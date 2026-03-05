#!/bin/bash
set -e

DEPLOY_ROOT="/opt/ydj-admin-web"
DATE=$(date +%Y%m%d%H%M)

RELEASE_DIR="$DEPLOY_ROOT/releases/$DATE"
SOFTLINK="$DEPLOY_ROOT/current"
TMP_DIST="$DEPLOY_ROOT/tmp/dist"

echo "create release dir"
mkdir -p "$RELEASE_DIR"

echo "move dist"
mv "$TMP_DIST" "$RELEASE_DIR/dist"

echo "switch symlink"
ln -sfn "$RELEASE_DIR/dist" "$SOFTLINK"

echo "reload nginx"
nginx -s reload

echo "deploy admin-web success: $DATE"