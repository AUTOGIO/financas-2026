#!/bin/bash
# ─────────────────────────────────────────────
#  fv — FinanceVision launcher  [ARCHIVED 2026-07-29]
#
#  The FinanceVision/ Swift project is not present in this repository
#  (see AUDIT-005 in REPOSITORY_AUDIT.md). This script points at a
#  binary that has never been built here, so it is kept only for
#  historical reference. Restore FinanceVision/ before moving this
#  file back to scripts/.
#
#  Primary: Claude Haiku API (fast, ~3s, ~$0.0006/run)
#  Fallback: LM Studio → Ollama → Foundation Models
#  Usage: fv [path/to/file.pdf]
# ─────────────────────────────────────────────

echo "❌ scripts/fv.sh has been archived — see archive/scripts/fv.sh header." >&2
echo "   The FinanceVision Swift project is not part of this repo." >&2
exit 1

FV_BIN="$HOME/Documents/GitHub/financas-2026/FinanceVision/.build/release/FinanceVision"
STATUS_FILE="$HOME/.financas-system-status.json"

# ── 1. Ensure binary exists ──────────────────
if [ ! -f "$FV_BIN" ]; then
  echo "❌ FinanceVision not built. Run:"
  echo "   cd ~/Documents/GitHub/financas-2026/FinanceVision && swift build -c release"
  exit 1
fi

# ── 2. File selection ─────────────────────────
if [ -n "$1" ]; then
  PDF_PATH="$1"
else
  PDF_PATH=$(osascript 2>/dev/null <<'AS'
    tell application "Finder"
      set f to choose file with prompt "Selecione o extrato bancário (PDF ou imagem)" ¬
        of type {"PDF", "png", "jpg", "jpeg", "heic"}
      return POSIX path of f
    end tell
AS
  )
  [ -z "$PDF_PATH" ] && echo "Cancelado." && exit 0
fi

# ── 3. Run FinanceVision ──────────────────────
"$FV_BIN" "$PDF_PATH"
STATUS=$?

# ── 4. Update system status timestamp ────────
if [ -f "$STATUS_FILE" ]; then
  python3 -c "
import json, datetime
with open(\'$STATUS_FILE\') as f: d=json.load(f)
d[\'last_fv_run\'] = datetime.datetime.now().isoformat()
with open(\'$STATUS_FILE\',\'w\') as f: json.dump(d,f)
" 2>/dev/null
fi

# ── 5. Reveal JSON output in Finder ──────────
if [ $STATUS -eq 0 ]; then
  PARSED=$(find ~/Documents/GitHub/financas-2026 -name "*-parsed.json" -newer "$FV_BIN" 2>/dev/null | head -1)
  [ -n "$PARSED" ] && open -R "$PARSED"
fi
