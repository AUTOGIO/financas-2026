#!/bin/bash
# ============================================================
#  configure_lmstudio.sh
#  Applies optimal LM Studio settings for FinanceVision:
#    • Context length  : 2048 (was 8192 → causes OOM on chunk 2)
#    • Speculative dec : disabled (Qwen draft model adds RAM pressure)
#    • Loads Gemma 4 E4B with those params via lms CLI
#
#  Run ONCE after installing LM Studio or after a factory reset.
#  Safe to re-run — idempotent.
# ============================================================

set -euo pipefail

LMS="$HOME/.lmstudio/bin/lms"
SETTINGS="$HOME/.lmstudio/settings.json"
GEMMA_KEY="google/gemma-4-e4b"
CTX=2048
TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── helpers ──────────────────────────────────────────────────
green()  { echo -e "\033[32m✓\033[0m $*"; }
yellow() { echo -e "\033[33m⚠\033[0m $*"; }
red()    { echo -e "\033[31m✗\033[0m $*"; }
step()   { echo -e "\n\033[36m▶ $*\033[0m"; }

# ── 1. Verify lms CLI available ───────────────────────────────
step "Checking lms CLI"
if [ ! -x "$LMS" ]; then
  red "lms not found at $LMS"
  echo "  Install it in LM Studio → Developer → Install CLI tool"
  exit 1
fi
green "lms CLI found: $($LMS --version 2>/dev/null | head -1)"

# ── 2. Patch defaultContextLength in settings.json ───────────
step "Patching ~/.lmstudio/settings.json"
if [ ! -f "$SETTINGS" ]; then
  red "settings.json not found — open LM Studio once first"
  exit 1
fi

python3 - << PYEOF
import json, shutil, sys
from pathlib import Path

path = Path("$SETTINGS")
backup = path.with_suffix(".json.bak")

with open(path) as f:
    d = json.load(f)

changed = []

# defaultContextLength → 2048
old_ctx = d.get("defaultContextLength", {})
if old_ctx != {"type": "custom", "value": $CTX}:
    d["defaultContextLength"] = {"type": "custom", "value": $CTX}
    changed.append(f"defaultContextLength: {old_ctx} → {{'type':'custom','value':$CTX}}")

# Persist speculative decoding OFF in configPresetInclusiveness
if not d.get("configPresetInclusiveness", {}).get("speculativeDecoding") == False:
    d.setdefault("configPresetInclusiveness", {})["speculativeDecoding"] = False
    changed.append("configPresetInclusiveness.speculativeDecoding → false")

if changed:
    shutil.copy(path, backup)
    with open(path, "w") as f:
        json.dump(d, f, indent=4)
    for c in changed:
        print(f"  patched: {c}")
    print(f"  backup: {backup}")
else:
    print("  already optimal — no changes needed")
PYEOF
green "settings.json OK"

# ── 3. Quit LM Studio (so it picks up new settings on relaunch) ──
step "Restarting LM Studio"
if pgrep -x "LM Studio" > /dev/null 2>&1; then
  yellow "LM Studio is running — quitting it (settings apply on next launch)"
  osascript -e 'tell application "LM Studio" to quit' 2>/dev/null || \
    pkill -x "LM Studio" 2>/dev/null || true
  sleep 2
  green "LM Studio quit"
else
  green "LM Studio not running"
fi

# Relaunch LM Studio so server comes up
echo "  Launching LM Studio..."
open -a "LM Studio"
echo -n "  Waiting for server on :1234"
for i in $(seq 1 30); do
  if curl -s --connect-timeout 1 http://localhost:1234/v1/models > /dev/null 2>&1; then
    echo ""
    green "Server up on :1234"
    break
  fi
  echo -n "."
  sleep 2
done
if ! curl -s --connect-timeout 1 http://localhost:1234/v1/models > /dev/null 2>&1; then
  echo ""
  yellow "Server not responding yet — you may need to start it manually in LM Studio → Developer → Server"
fi

# ── 4. Load Gemma 4 E4B with optimised settings ───────────────
step "Loading Gemma 4 E4B (context=$CTX, no speculative decoding)"
if "$LMS" model list 2>/dev/null | grep -q "google/gemma-4-e4b"; then
  # Already loaded — unload first so new params take effect
  yellow "Gemma already loaded — reloading with new params"
  "$LMS" unload "$GEMMA_KEY" 2>/dev/null || true
  sleep 1
fi

"$LMS" load "$GEMMA_KEY" \
  --context-length $CTX \
  --no-speculative-draft-mtp \
  -y && green "Gemma 4 E4B loaded (ctx=$CTX, no speculative)" \
  || yellow "Load failed — do it manually in LM Studio UI with context=$CTX"

# ── 5. Note about fv.sh (formerly auto-edited here) ───────────
# The previous version of this script rewrote scripts/fv.sh at runtime to
# insert an `lms load` block. That was surprising behaviour (AUDIT-005) and
# fv.sh itself has since been archived because the FinanceVision Swift
# project is not in this repo. If you restore FinanceVision, add the
# `lms load` invocation directly into the new fv.sh instead of self-editing.
step "Skipping fv.sh self-edit (script archived — see AUDIT-005)"
green "no-op — fv.sh moved to archive/scripts/fv.sh"

# ── 6. Summary ────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════"
green "Configuration complete!"
echo ""
echo "  Context length : $CTX tokens (was 8192)"
echo "  Spec. decoding : disabled"
echo "  Gemma 4 E4B    : loaded via lms"
echo ""
echo "  ⚠  One manual step:"
echo "     LM Studio → Developer → Server Settings"
echo "     → Require Authentication → OFF"
echo ""
echo "  Run: fv  (picks up all changes automatically)"
echo "════════════════════════════════════════════════"
