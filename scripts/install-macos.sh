#!/usr/bin/env bash
# install-macos.sh
# Configures Claude Desktop with in-app AWS SSO so users sign in via the GUI.
# Run as root (or via MDM in root context).
#
# IT must set the four SSO_* variables below (or pass them as env vars) BEFORE
# distribution. They are baked into each user's inference-config.json.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/../config" && pwd)"
TPL="$CONFIG_DIR/claude-desktop-config.json"

# ----- Required values from IAM Identity Center -----
SSO_START_URL="${SSO_START_URL:-https://d-1234567890.awsapps.com/start}"
SSO_REGION="${SSO_REGION:-us-east-1}"
ACCOUNT_ID="${ACCOUNT_ID:-123456789012}"
ROLE_NAME="${ROLE_NAME:-BedrockInference}"
# Generate one UUID per install run so all users on this machine share it.
# Override by exporting DEPLOYMENT_UUID before invoking the script.
DEPLOYMENT_UUID="${DEPLOYMENT_UUID:-$(uuidgen | tr '[:lower:]' '[:upper:]')}"
# ----------------------------------------------------

echo "[claude-desktop-deploy] macOS install — in-app SSO mode"

for USER_HOME in /Users/*; do
  USERNAME="$(basename "$USER_HOME")"
  case "$USERNAME" in Shared|Guest|.*) continue ;; esac
  [ -d "$USER_HOME" ] || continue

  echo "  -> user: $USERNAME"

  DESKTOP_DIR="$USER_HOME/Library/Application Support/Claude"
  DESKTOP_FILE="$DESKTOP_DIR/inference-config.json"
  mkdir -p "$DESKTOP_DIR"

  sed \
    -e "s|{{SSO_START_URL}}|$SSO_START_URL|g" \
    -e "s|{{SSO_REGION}}|$SSO_REGION|g" \
    -e "s|{{ACCOUNT_ID}}|$ACCOUNT_ID|g" \
    -e "s|{{ROLE_NAME}}|$ROLE_NAME|g" \
    -e "s|{{DEPLOYMENT_UUID}}|$DEPLOYMENT_UUID|g" \
    "$TPL" > "$DESKTOP_FILE"

  chown -R "$USERNAME":staff "$DESKTOP_DIR" 2>/dev/null || true
  echo "     wrote $DESKTOP_FILE"
done

echo "[claude-desktop-deploy] Done."
echo "Users: open Claude → Settings → Connection → click 'Sign in with AWS SSO'."
