#!/usr/bin/env bash
# financas-2026 · Open workspace (ChatGPT Atlas edition)
# Runs sync → opens Excel + 3 dashboards in Atlas → triggers Hammerspoon layout
# Usage: bash ~/Documents/financas-2026/scripts/financas-open.sh

BASE="$HOME/Documents/financas-2026"
PYTHON="/opt/homebrew/bin/python3"
ATLAS="ChatGPT Atlas"

echo "🔄 Syncing data..."
cd "$BASE" && "$PYTHON" sync.py

echo "📂 Opening workspace..."
open "$BASE/data/financas2026-DataEntry.xlsx"

# Open each HTML in a separate Atlas window using Chromium --new-window flag
sleep 0.5
open -na "$ATLAS" --args --new-window "file://$BASE/src/html/financas2026-Dashboard.html"
sleep 1.0
open -na "$ATLAS" --args --new-window "file://$BASE/src/nfce/nfce-dashboard.html"
sleep 1.0
open -na "$ATLAS" --args --new-window "file://$BASE/src/nfce/inflation-tracker.html"

sleep 4

echo "🖥  Applying layout on 49\"..."
osascript << 'EOF'
tell application "Hammerspoon"
  execute lua code "
    local s = (function()
      local best, bestW = hs.screen.primaryScreen(), 0
      for _, sc in ipairs(hs.screen.allScreens()) do
        if sc:frame().w > bestW then bestW = sc:frame().w; best = sc end
      end
      return best
    end)()
    local f = s:frame()
    local x, y, W, H = f.x, f.y, f.w, f.h
    local e1=math.floor(W*0.20); local e2=math.floor(W*0.27); local e3=math.floor(W*0.27); local e4=W-e1-e2-e3
    local function mvApp(name, hint, frame)
      local a = hs.application.get(name)
      if not a then return end
      local win = a:mainWindow()
      if hint then
        for _, w in ipairs(a:allWindows()) do
          if w:title():find(hint,1,true) then win=w; break end
        end
      end
      if win then win:moveToScreen(s,false,true,0); win:setFrame(frame,0) end
    end
    local function mvAtlas(hint, frame)
      local a = hs.application.get('ChatGPT Atlas')
      if not a then return end
      for _, w in ipairs(a:allWindows()) do
        if (w:title() or ''):find(hint,1,true) then
          w:moveToScreen(s,false,true,0); w:setFrame(frame,0); return
        end
      end
    end
    hs.timer.doAfter(0.3, function()
      mvApp('Microsoft Excel', 'financas2026', {x=x,          y=y,w=e1,h=H})
      mvApp('Numbers',         'financas2026', {x=x,          y=y,w=e1,h=H})
      mvAtlas('financas-2026',               {x=x+e1,       y=y,w=e2,h=H})
      mvAtlas('NFC-e',                       {x=x+e1+e2,    y=y,w=e3,h=H})
      mvAtlas('Infla',                       {x=x+e1+e2+e3, y=y,w=e4,h=H})
    end)
  "
end tell
EOF

echo "✅ financas-2026 workspace ready  (ChatGPT Atlas · 49\")"
