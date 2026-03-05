#!/usr/bin/env bash
set -euo pipefail
umask 022

DEPLOY_ROOT="/opt/ydj-api"
RELEASES_DIR="${DEPLOY_ROOT}/releases"
SOFTLINK="${DEPLOY_ROOT}/current"
SERVICE_NAME="ydj-prod.service"
HEALTH_URL="http://127.0.0.1:8183/edo/actuator/health"
LOG_FILE="${DEPLOY_ROOT}/deploy.log"
LOCK_FILE="${DEPLOY_ROOT}/.deploy.lock"

# ===== 工具函数 =====
log()   { echo "[$(date +'%F %T')] [rollback] $*" | tee -a "$LOG_FILE" ; }
die()   { echo "[$(date +'%F %T')] [rollback][error] $*" | tee -a "$LOG_FILE" >&2; exit 1; }
exists() { [[ -e "$1" ]]; }

# 并发互斥
mkdir -p "$DEPLOY_ROOT"
exec 9>"$LOCK_FILE"
flock -n 9 || die "another deploy/rollback is running"

# 解析参数：可传“步数N”（默认1）或“时间戳目录名”
TARGET="${1:-1}"

# 当前目标
[[ -L "$SOFTLINK" ]] || die "current is not a symlink: $SOFTLINK"
CURRENT_PATH="$(readlink -f "$SOFTLINK")"
[[ -d "$CURRENT_PATH" ]] || die "current target not a dir: $CURRENT_PATH"

# 列出有效版本（只要是目录且包含 ydj-prod.jar），按时间戳排序
mapfile -t VERSIONS < <(find "$RELEASES_DIR" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" \
  | grep -E '^[0-9]{12}$' | sort)

[[ ${#VERSIONS[@]} -gt 0 ]] || die "no releases found under $RELEASES_DIR"

# 当前索引
CUR_IDX=-1
for i in "${!VERSIONS[@]}"; do
  [[ "$RELEASES_DIR/${VERSIONS[$i]}" == "$CURRENT_PATH" ]] && CUR_IDX=$i && break
done
[[ $CUR_IDX -ge 0 ]] || die "current version not recognized in releases list: $CURRENT_PATH"

# 计算回滚目标目录
if [[ "$TARGET" =~ ^[0-9]{12}$ ]]; then
  # 指定时间戳
  PREV_VER="$TARGET"
  PREV_PATH="$RELEASES_DIR/$PREV_VER"
else
  # 指定步数
  STEP=$TARGET
  [[ "$STEP" =~ ^[0-9]+$ ]] || die "invalid argument: $TARGET (use N steps or release ts)"
  [[ $CUR_IDX -ge $STEP ]] || die "cannot rollback $STEP step(s): already at earliest"
  PREV_VER="${VERSIONS[$((CUR_IDX-STEP))]}"
  PREV_PATH="$RELEASES_DIR/$PREV_VER"
fi

[[ -d "$PREV_PATH" ]] || die "target release not found: $PREV_PATH"
[[ -f "$PREV_PATH/ydj-prod.jar" ]] || die "target release missing jar: $PREV_PATH/ydj-prod.jar"

log "current: $CURRENT_PATH"
log "target : $PREV_PATH"

# 停实例，清失败状态
systemctl stop "$SERVICE_NAME" || true
systemctl reset-failed "$SERVICE_NAME" || true

# 切软链
ln -sfn "$PREV_PATH" "$SOFTLINK"
readlink -f "$SOFTLINK" | tee -a "$LOG_FILE"

# 让 systemd 识别最新单元/环境
systemctl daemon-reload

# 启动
systemctl start "$SERVICE_NAME"

# 健康检查（最多 60 秒）
ok=0
for i in {1..60}; do
  code="$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "$HEALTH_URL" || true)"
  if [[ "$code" == "200" ]]; then ok=1; break; fi
  sleep 1
done

if [[ $ok -ne 1 ]]; then
  log "health check failed, rolling back to original: $CURRENT_PATH"
  # 回退软链回原来版本
  ln -sfn "$CURRENT_PATH" "$SOFTLINK"
  systemctl daemon-reload
  systemctl start "$SERVICE_NAME" || true
  die "rollback to $PREV_VER failed (health not OK). restored to original."
fi

log "rolled back successfully to $PREV_VER"
exit 0