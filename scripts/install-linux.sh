#!/usr/bin/env bash
# install-linux.sh
# Configures Claude Desktop with in-app AWS SSO. Run as root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/../config" && pwd)"
TPL="$CONFIG_DIR/claude-desktop-config.json"

SSO_START_URL="${SSO_START_URL:-https://d-1234567890.awsapps.com/start}"
SSO_REGION="${SSO_REGION:-us-east-1}"
ACCOUNT_ID="${ACCOUNT_ID:-123456789012}"
ROLE_NAME="${ROLE_NAME:-BedrockInference}"
# Auto-generate one UUID per install run; override by exporting DEPLOYMENT_UUID.
DEPLOYMENT_UUID="${DEPLOYMENT_UUID:-$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)}"
DEPLOYMENT_UUID="$(echo "$DEPLOYMENT_UUID" | tr '[:lower:]' '[:upper:]')"

echo "[claude-desktop-deploy] Linux install — in-app SSO mode"

for USER_HOME in /home/* /root; do
  [ -d "$USER_HOME" ] || continue
  USERNAME="$(basename "$USER_HOME")"
  [ "$USERNAME" = "lost+found" ] && continue

  echo "  -> user: $USERNAME"

  DESKTOP_DIR="$USER_HOME/.config/Claude"
  DESKTOP_FILE="$DESKTOP_DIR/inference-config.json"
  mkdir -p "$DESKTOP_DIR"

  sed \
    -e "s|{{SSO_START_URL}}|$SSO_START_URL|g" \
    -e "s|{{SSO_REGION}}|$SSO_REGION|g" \
    -e "s|{{ACCOUNT_ID}}|$ACCOUNT_ID|g" \
    -e "s|{{ROLE_NAME}}|$ROLE_NAME|g" \
    -e "s|{{DEPLOYMENT_UUID}}|$DEPLOYMENT_UUID|g" \
    "$TPL" > "$DESKTOP_FILE"

  chown -R "$USERNAME":"$USERNAME" "$DESKTOP_DIR" 2>/dev/null || true
  echo "     wrote $DESKTOP_FILE"
done

echo "[claude-desktop-deploy] Done."
echo "Users: open Claude → Settings → Connection → click 'Sign in with AWS SSO'."
