#!/usr/bin/env bash
# uninstall.sh — removes the Claude Desktop inference config from each user.
# Run as root on macOS or Linux.
set -u
case "$(uname -s)" in
  Darwin) REL="Library/Application Support/Claude/inference-config.json" ;;
  Linux)  REL=".config/Claude/inference-config.json" ;;
  *) echo "Unsupported OS"; exit 1 ;;
esac

if [ "$(uname -s)" = "Darwin" ]; then
  HOMES=$(ls -d /Users/*/ 2>/dev/null | grep -vE '/(Shared|Guest)/$')
else
  HOMES=$(ls -d /home/*/ /root/ 2>/dev/null)
fi

for h in $HOMES; do
  rm -f "${h}${REL}" 2>/dev/null && echo "  removed ${h}${REL}"
done
echo "[claude-desktop-deploy] Uninstall complete."
echo "Note: SSO token caches under ~/.aws/sso/cache/ (if any) are left untouched."
