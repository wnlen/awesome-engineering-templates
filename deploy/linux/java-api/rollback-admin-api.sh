#!/usr/bin/env bash
set -euo pipefail
umask 022

### ======== Site-specific variables (edit per project) ======== ###
APP_NAME="my-app"                   # app name used for jar/service naming
PROFILE="prod"                      # spring profile: dev/test/prod
DEPLOY_ROOT="/opt/${APP_NAME}"      # deploy root
PORT=8183                           # used by health check URL

# Health check
HEALTH_HOST="127.0.0.1"
HEALTH_PATH="/actuator/health"      # change if you use a prefix (e.g. /edo/actuator/health)
HEALTH_URL="http://${HEALTH_HOST}:${PORT}${HEALTH_PATH}"

# systemd
SERVICE_NAME="${APP_NAME}-${PROFILE}.service"

# jar name inside release dir (recommended: APP_NAME-PROFILE.jar)
JAR_NAME="${APP_NAME}-${PROFILE}.jar"

# release dir timestamp pattern: 12 (YYYYMMDDHHMM) or 14 (YYYYMMDDHHMMSS)
RELEASE_TS_REGEX='^[0-9]{12}([0-9]{2})?$'

# log/lock
LOG_FILE="${DEPLOY_ROOT}/deploy.log"
LOCK_FILE="${DEPLOY_ROOT}/.deploy.lock"
### =========================================================== ###

RELEASES_DIR="${DEPLOY_ROOT}/releases"
SOFTLINK="${DEPLOY_ROOT}/current"

# ===== helpers =====
log()    { echo "[$(date +'%F %T')] [rollback] $*" | tee -a "$LOG_FILE" ; }
die()    { echo "[$(date +'%F %T')] [rollback][error] $*" | tee -a "$LOG_FILE" >&2; exit 1; }

# ===== lock =====
mkdir -p "$DEPLOY_ROOT"
exec 9>"$LOCK_FILE"
flock -n 9 || die "another deploy/rollback is running"

TARGET="${1:-1}"  # N steps (default 1) or release timestamp dir name

# ===== validate current =====
[[ -L "$SOFTLINK" ]] || die "current is not a symlink: $SOFTLINK"
CURRENT_PATH="$(readlink -f "$SOFTLINK")"
[[ -d "$CURRENT_PATH" ]] || die "current target not a dir: $CURRENT_PATH"

# ===== list versions =====
[[ -d "$RELEASES_DIR" ]] || die "releases dir not found: $RELEASES_DIR"

mapfile -t VERSIONS < <(
  find "$RELEASES_DIR" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" \
    | grep -E "$RELEASE_TS_REGEX" \
    | sort
)

[[ ${#VERSIONS[@]} -gt 0 ]] || die "no releases found under $RELEASES_DIR"

# current index
CUR_IDX=-1
for i in "${!VERSIONS[@]}"; do
  [[ "$RELEASES_DIR/${VERSIONS[$i]}" == "$CURRENT_PATH" ]] && CUR_IDX=$i && break
done
[[ $CUR_IDX -ge 0 ]] || die "current version not recognized in releases list: $CURRENT_PATH"

# ===== choose target =====
if [[ "$TARGET" =~ $RELEASE_TS_REGEX ]]; then
  PREV_VER="$TARGET"
  PREV_PATH="$RELEASES_DIR/$PREV_VER"
else
  STEP="$TARGET"
  [[ "$STEP" =~ ^[0-9]+$ ]] || die "invalid argument: $TARGET (use N steps or release ts)"
  [[ $CUR_IDX -ge $STEP ]] || die "cannot rollback $STEP step(s): already at earliest"
  PREV_VER="${VERSIONS[$((CUR_IDX-STEP))]}"
  PREV_PATH="$RELEASES_DIR/$PREV_VER"
fi

[[ -d "$PREV_PATH" ]] || die "target release not found: $PREV_PATH"
[[ -f "$PREV_PATH/$JAR_NAME" ]] || die "target release missing jar: $PREV_PATH/$JAR_NAME"

log "current: $CURRENT_PATH"
log "target : $PREV_PATH"
log "service: $SERVICE_NAME"
log "health : $HEALTH_URL"

# ===== stop + switch =====
systemctl stop "$SERVICE_NAME" || true
systemctl reset-failed "$SERVICE_NAME" || true

ln -sfn "$PREV_PATH" "$SOFTLINK"
readlink -f "$SOFTLINK" | tee -a "$LOG_FILE"

systemctl daemon-reload
systemctl start "$SERVICE_NAME"

# ===== health check (60s) =====
ok=0
for i in {1..60}; do
  code="$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "$HEALTH_URL" || true)"
  if [[ "$code" == "200" ]]; then ok=1; break; fi
  sleep 1
done

if [[ $ok -ne 1 ]]; then
  log "health check failed, restoring original: $CURRENT_PATH"
  ln -sfn "$CURRENT_PATH" "$SOFTLINK"
  systemctl daemon-reload
  systemctl start "$SERVICE_NAME" || true
  die "rollback to $PREV_VER failed (health not OK). restored to original."
fi

log "rolled back successfully to $PREV_VER"
exit 0