#!/usr/bin/env bash
# financas-2026 · safe close
# Saves Excel, closes all Atlas windows for this project, sends notification

BASE="$HOME/Documents/financas-2026"
PYTHON="/opt/homebrew/bin/python3"

echo "📥 Final sync before close..."
cd "$BASE" && "$PYTHON" sync.py --quiet 2>/dev/null || "$PYTHON" sync.py

echo "💾 Saving Excel..."
osascript << 'AS'
try
  tell application "Microsoft Excel"
    if (count of workbooks) > 0 then
      save workbook (active workbook)
    end if
  end tell
end try
AS

echo "🔒 Closing Atlas financas windows..."
osascript << 'AS'
try
  tell application "ChatGPT Atlas"
    set kwds to {"financas-2026", "NFC-e", "Infla", "IPCA"}
    repeat with w in (every window)
      try
        set t to title of w
        repeat with kw in kwds
          if t contains kw then close w
        end repeat
      end try
    end repeat
  end tell
end try
AS

osascript -e 'display notification "Workspace fechado e salvo ✓" with title "financas-2026"'
echo "✅ Done."
