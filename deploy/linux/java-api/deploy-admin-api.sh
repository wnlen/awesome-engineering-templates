#!/bin/bash
# ydj-prod deploy script
# 流程：版本目录发布 -> 软链切换 -> 优雅停机 -> 端口等待 -> 启动重试 -> 健康探活 + YAML 体检
set -euo pipefail
umask 022

### ======== Site-specific variables (edit for each project) ======== ###
APP_NAME="my-app"                     # 应用名（用于 jar/service 命名）
PROFILE="prod"                        # Spring profile: dev/test/prod
DEPLOY_ROOT="/opt/${APP_NAME}"        # 部署根目录（建议与 APP_NAME 对齐）
PORT=8183                             # 应用端口（用于等待端口释放）
ASSETS_ROOT=""                 # optional: shared assets dir (img/certs/template)
REQUIRE_HEALTH_HTTP_200="1"    # 1=must 200, 0=skip health check (for non-http services)

# health check
HEALTH_HOST="127.0.0.1"
HEALTH_PATH="/actuator/health"        # 默认 Spring Boot actuator
HEALTH_URL="http://${HEALTH_HOST}:${PORT}${HEALTH_PATH}"

# systemd service (推荐：appname-profile.service)
SERVICE_NAME="${APP_NAME}-${PROFILE}.service"

# optional: java binary for self-check (留空则不自检)
JAVA_BIN=""                           # e.g. /usr/lib/jvm/java-21/bin/java
### =============================================================== ###

DATE="$(date +%Y%m%d%H%M%S)"                 # 14位时间戳
RELEASE_TS_REGEX='^[0-9]{12}([0-9]{2})?$'    # 版本目录匹配（给 rollback 用）
RELEASE_DIR="${DEPLOY_ROOT}/releases/${DATE}"

# jar naming (统一规则：APP_NAME-PROFILE.jar)
TMP_JAR="${DEPLOY_ROOT}/tmp/${APP_NAME}-${PROFILE}.jar"
FINAL_JAR="${RELEASE_DIR}/${APP_NAME}-${PROFILE}.jar"

SOFTLINK="${DEPLOY_ROOT}/current"
CFG_DIR="${RELEASE_DIR}/config"
SHARED_CFG_DIR="${DEPLOY_ROOT}/shared-config"

LOCK_FILE="${DEPLOY_ROOT}/.deploy.lock"
LOG_FILE="${DEPLOY_ROOT}/deploy.log"

# --- 并发互斥 ---
mkdir -p "${DEPLOY_ROOT}"
exec 9>"${LOCK_FILE}"
if ! flock -n 9; then
  echo "[error] another deploy is running" >&2
  exit 1
fi

# --- 依赖校验（缺哪个就直接退出） ---
for bin in curl unzip ss systemctl journalctl awk sed grep readlink flock; do
  command -v "$bin" >/dev/null || { echo "[error] missing required tool: $bin" >&2; exit 1; }
done
if [[ -n "${JAVA_BIN}" ]]; then
  [[ -x "${JAVA_BIN}" ]] || echo "[warn] JAVA_BIN not executable: ${JAVA_BIN} (ignored)."
fi
# --- 记录旧版本以便回滚 ---
OLD_LINK=""
if [ -L "${SOFTLINK}" ]; then
  OLD_LINK="$(readlink -f "${SOFTLINK}" || true)"
fi
rollback() {
  echo "[warn] deploy failed, rollback..." >&2
  if [ -n "${OLD_LINK}" ]; then
    ln -sfn "${OLD_LINK}" "${SOFTLINK}"
    echo "[warn] rolled back to: ${OLD_LINK}" >&2
  fi
}
trap 'rollback' ERR

# === 1) 创建新版本目录 ===
mkdir -p "${RELEASE_DIR}" "${CFG_DIR}"

# === 2) 移动并重命名 JAR 文件 ===
if [ ! -f "${TMP_JAR}" ]; then
  echo "[error] JAR not found: ${TMP_JAR}" >&2
  echo "Please upload JAR to ${TMP_JAR} before running." >&2
  exit 1
fi
mv "${TMP_JAR}" "${FINAL_JAR}"

# ✅ 2.5 写入版本信息
echo "Deployed version: ${DATE}" > "${RELEASE_DIR}/version.txt"

# === 3) 准备外部配置（优先级最高） ===
# 3.1 共享配置目录存在时，按需复制（目标已存在则不覆盖）
if [ -d "${SHARED_CFG_DIR}" ]; then
  for f in application-${PROFILE}.yml application.yml logback-spring.xml; do
    [ -f "${SHARED_CFG_DIR}/${f}" ] && cp -n "${SHARED_CFG_DIR}/${f}" "${CFG_DIR}/"
  done
fi

# 3.2 若无外置 application-${PROFILE}.yml，则从 JAR 兜底解压（⚠️ 注释插入到首行，避免尾部黏连）
if [ ! -f "${CFG_DIR}/application-${PROFILE}.yml" ]; then
  if unzip -Z1 "${FINAL_JAR}" | grep -q '^BOOT-INF/classes/application-'"${PROFILE}"'\.yml$'; then
    unzip -p "${FINAL_JAR}" "BOOT-INF/classes/application-${PROFILE}.yml" > "${CFG_DIR}/application-${PROFILE}.yml"
    # 在首行插入注释，保证不与最后一行拼接
    sed -i '1i # NOTE: extracted from JAR as fallback; edit '"${PROFILE}"' secrets here' "${CFG_DIR}/application-${PROFILE}.yml"
  fi
fi

# 3.25 兜底：把强制 classpath 导入改为可选，避免 JAR 内无 config 报错
for y in "${CFG_DIR}"/application*.yml; do
  [ -f "$y" ] || continue
  if grep -Eq '^\s*spring\.config\.import\s*:\s*classpath:/config/' "$y"; then
    sed -ri 's#(^\s*spring\.config\.import\s*:\s*)classpath:/config/#\1optional:classpath:/config/#' "$y"
    echo "[patch] $y -> spring.config.import 改为 optional:classpath:/config/"
  fi
done

# 3.3 YAML 体检（避免脏配置上线）
yaml_quick_check() {
  # 仅做快速启发式检查（不依赖 python/yq）
  local f="$1"
  # 检出类似 “http...# NOTE:” 这一类黏连
  if grep -Eq 'https?://[^ ]+# NOTE:' "$f"; then
    echo "[fix] $f: detected trailing '# NOTE:' glued to URL; splitting to new line."
    # 把 "# NOTE: ..." 以及之后的内容切到下一行
    sed -ri 's|(https?://[^ ]+)# NOTE:.*$|\1\n# NOTE: extracted from JAR as fallback|' "$f"
  fi
  # 报错行里常见的“url: http... NOTE:” 冒号冲突，统一把 URL 值加引号（只处理裸 URL 行）
  sed -ri 's|(^\s*[A-Za-z0-9_.-]+\s*:\s*)(https?://[^"'\'' ]+)\s*$|\1"\2"|' "$f"
}
for y in "${CFG_DIR}"/application*.yml; do
  [ -f "$y" ] && yaml_quick_check "$y"
done

# 3.4 权限（若以后改为业务用户运行，这里同步修改 chown）
chown -R root:root "${RELEASE_DIR}"
chmod -R u=rwX,go=rX "${RELEASE_DIR}"

# === 4) 记录旧版本路径（仅日志留痕） ===
if [ -n "${OLD_LINK}" ]; then
  echo "Backed up previous version: ${OLD_LINK}" >> "${LOG_FILE}"
fi

# === 5) 切换 current 软链到新版本 ===
ln -sfn "${RELEASE_DIR}" "${SOFTLINK}"

# === 6) Optional: mount shared assets (static files/certs/templates) ===
if [[ -n "${ASSETS_ROOT}" ]]; then
  [[ ! -e "${SOFTLINK}/img"   && -d "${ASSETS_ROOT}/img"   ]] && ln -s "${ASSETS_ROOT}/img"   "${SOFTLINK}/img"
  [[ ! -e "${SOFTLINK}/certs" && -d "${ASSETS_ROOT}/certs" ]] && ln -s "${ASSETS_ROOT}/certs" "${SOFTLINK}/certs"
  [[ ! -e "${SOFTLINK}/template" && -d "${ASSETS_ROOT}/template" ]] && ln -s "${ASSETS_ROOT}/template" "${SOFTLINK}/template"
fi

# === 7) 让 systemd 读取最新 unit（幂等） ===
systemctl daemon-reload

# === 8) 停旧实例（不因 stop 失败而中断脚本） ===
set +e
systemctl stop "${SERVICE_NAME}"
set -e

# === 9) 等端口释放（兼容 IPv4/IPv6） ===
for i in {1..30}; do
  if ss -ltn | awk '{print $4}' | grep -Eq "(:|\\])${PORT}$"; then
    sleep 1
  else
    break
  fi
done

# === 10) 启动并重试一次（防止偶发失败） ===
start_once() { systemctl start "${SERVICE_NAME}"; }

if ! start_once; then
  echo "[warn] first start failed, showing recent logs:" >&2
  journalctl -u "${SERVICE_NAME}" -n 120 --no-pager || true
  echo "[warn] retry in 3s..." >&2
  sleep 3
  start_once
fi

# === 11) 健康检查（200 视为成功） ===
if [[ "${REQUIRE_HEALTH_HTTP_200}" == "1" ]]; then
  ok=0
  for i in {1..60}; do
    code="$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "${HEALTH_URL}" || true)"
    if [ "${code}" = "200" ]; then
      ok=1
      break
    fi
    sleep 1
  done

  if [ "${ok}" -ne 1 ]; then
    echo "[error] service not healthy after start." >&2
    systemctl status "${SERVICE_NAME}" || true
    journalctl -u "${SERVICE_NAME}" -n 200 --no-pager || true
    exit 1
  fi
fi
echo "Production service deployed and started OK: ${DATE}" | tee -a "${LOG_FILE}"