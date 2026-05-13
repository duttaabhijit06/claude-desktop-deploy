#!/usr/bin/env bash
# verify.sh — run as the end user to confirm the patch landed.
set -u
case "$(uname -s)" in
  Darwin) DESKTOP="$HOME/Library/Application Support/Claude/inference-config.json" ;;
  Linux)  DESKTOP="$HOME/.config/Claude/inference-config.json" ;;
  *) echo "Unsupported OS"; exit 1 ;;
esac

echo "Claude Desktop config: $DESKTOP"
if [ -f "$DESKTOP" ]; then
  echo "  EXISTS"
  python3 -m json.tool < "$DESKTOP" >/dev/null && echo "  JSON: valid" || echo "  JSON: INVALID"
  python3 - <<PY
import json
d = json.load(open("$DESKTOP"))
print("  provider:    ", d.get("inferenceProvider"))
print("  region:      ", d.get("inferenceBedrockRegion"))
print("  SSO start:   ", d.get("inferenceBedrockSsoStartUrl"))
print("  SSO region:  ", d.get("inferenceBedrockSsoRegion"))
print("  SSO account: ", d.get("inferenceBedrockSsoAccountId"))
print("  SSO role:    ", d.get("inferenceBedrockSsoRoleName"))
print("  deployment:  ", d.get("deploymentOrganizationUuid"))
missing = [k for k in ("inferenceBedrockSsoStartUrl","inferenceBedrockSsoRegion","inferenceBedrockSsoAccountId","inferenceBedrockSsoRoleName","deploymentOrganizationUuid") if not d.get(k) or "{{" in str(d.get(k))]
if missing:
    print("  WARNING: unfilled placeholders:", missing)
PY
else
  echo "  MISSING"
fi

echo
echo "Open Claude Desktop and click 'Sign in with AWS SSO' to complete authentication."
