#!/usr/bin/env bash
# financas-2026 · login / manual launcher
# Runs via a macOS Login Item; assumes the repo lives under $HOME/Documents/GitHub/.

BASE="$HOME/Documents/GitHub/financas-2026"
if [ -x "$BASE/.venv/bin/python3" ]; then
  PYTHON="$BASE/.venv/bin/python3"
else
  PYTHON="${PYTHON:-$(command -v python3)}"
fi
if [ -z "$PYTHON" ] || [ ! -x "$PYTHON" ]; then
  echo "❌ python3 not found on PATH. Install Python 3.10+ or set PYTHON=/path/to/python3" >&2
  exit 1
fi
LOG="$BASE/logs/login-launch.log"
mkdir -p "$BASE/logs"
exec >> "$LOG" 2>&1

echo ""
echo "=== $(date '+%Y-%m-%d %H:%M:%S') LAUNCH ==="

# 1. Wait for desktop
sleep 6

# 2. Start Hammerspoon (init.lua already has allowAppleScript + ipc)
echo "Starting Hammerspoon..."
open -a Hammerspoon
sleep 4

# 3. Sync
echo "Syncing..."
cd "$BASE" && "$PYTHON" sync.py
echo "Sync done."

# 4. Open Excel
open "$BASE/data/financas2026-DataEntry.xlsx"
sleep 1

# 5. Open dashboards in separate Atlas windows
open -a "/Applications/ChatGPT Atlas.app" "file://$BASE/src/html/financas2026-Dashboard.html"
sleep 1.5
open -a "/Applications/ChatGPT Atlas.app" "file://$BASE/src/nfce/nfce-dashboard.html"
sleep 1.5
open -a "/Applications/ChatGPT Atlas.app" "file://$BASE/src/nfce/inflation-tracker.html"

# 6. Apply 49" layout via Hammerspoon AppleScript
echo "Applying layout..."
sleep 6
osascript << 'AS'
tell application "Hammerspoon"
  execute lua code "
    local best,bestW=hs.screen.primaryScreen(),0
    for _,s in ipairs(hs.screen.allScreens()) do
      if s:frame().w>bestW then bestW=s:frame().w; best=s end
    end
    local f=best:frame(); local x,y,W,H=f.x,f.y,f.w,f.h
    local e1=math.floor(W*.20); local e2=math.floor(W*.27)
    local e3=math.floor(W*.27); local e4=W-e1-e2-e3
    local z={
      excel={x=x,       y=y,w=e1,h=H},
      dash ={x=x+e1,    y=y,w=e2,h=H},
      nfce ={x=x+e1+e2, y=y,w=e3,h=H},
      ipca ={x=x+e1+e2+e3,y=y,w=e4,h=H}
    }
    local xl=hs.application.get('Microsoft Excel') or hs.application.get('Numbers')
    if xl then
      local w=xl:mainWindow()
      if w then w:moveToScreen(best,false,true,0); w:setFrame(z.excel,0) end
    end
    local atlas=hs.application.get('ChatGPT Atlas')
    if atlas then
      local map={['financas-2026']='dash',['NFC-e']='nfce',['Infla']='ipca'}
      for _,win in ipairs(atlas:allWindows()) do
        local t=win:title() or ''
        for kw,zone in pairs(map) do
          if t:find(kw,1,true) then
            win:moveToScreen(best,false,true,0)
            win:setFrame(z[zone],0)
            break
          end
        end
      end
    end
    hs.notify.new({title='financas-2026',informativeText='Workspace pronto ✓'}):send()
  "
end tell
AS

echo "Done. $(date '+%H:%M:%S')"
