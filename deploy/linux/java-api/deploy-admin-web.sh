#!/usr/bin/env bash
set -euo pipefail
umask 022

### ======== Site-specific variables (edit per project) ======== ###
APP_NAME="admin-web"
DEPLOY_ROOT="/opt/${APP_NAME}"
NGINX_RELOAD_CMD="nginx -s reload"       # or: systemctl reload nginx
TMP_DIST_DIR="${DEPLOY_ROOT}/tmp/dist"   # where you upload dist/
### ============================================================ ###

DATE="$(date +%Y%m%d%H%M%S)"
RELEASE_DIR="${DEPLOY_ROOT}/releases/${DATE}"
SOFTLINK="${DEPLOY_ROOT}/current"
LOG_FILE="${DEPLOY_ROOT}/deploy.log"
LOCK_FILE="${DEPLOY_ROOT}/.deploy.lock"

log() { echo "[$(date +'%F %T')] [deploy-web] $*" | tee -a "$LOG_FILE"; }
die() { echo "[$(date +'%F %T')] [deploy-web][error] $*" | tee -a "$LOG_FILE" >&2; exit 1; }

mkdir -p "$DEPLOY_ROOT"

for bin in flock readlink mv bash; do
  command -v "$bin" >/dev/null 2>&1 || die "missing required tool: $bin"
done

# lock
exec 9>"$LOCK_FILE"
flock -n 9 || die "another deploy is running"

# validate
[[ -d "$TMP_DIST_DIR" ]] || die "dist not found: $TMP_DIST_DIR (upload dist/ first)"

# record old link for rollback
OLD_LINK=""
if [[ -L "$SOFTLINK" ]]; then
  OLD_LINK="$(readlink -f "$SOFTLINK" || true)"
fi
rollback() {
  log "deploy failed, rollback..."
  if [[ -n "$OLD_LINK" ]]; then
    ln -sfn "$OLD_LINK" "$SOFTLINK"
    log "rolled back to: $OLD_LINK"
  fi
}
trap 'rollback' ERR

log "create release dir: $RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

log "move dist -> release"
mv "$TMP_DIST_DIR" "$RELEASE_DIR/dist"

log "switch symlink"
ln -sfn "$RELEASE_DIR/dist" "$SOFTLINK"
readlink -f "$SOFTLINK" | tee -a "$LOG_FILE"

log "reload nginx"
bash -lc "$NGINX_RELOAD_CMD"

log "deploy success: $DATE"