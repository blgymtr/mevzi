#!/bin/bash
# ./shot.sh desert|winter  -> ekran görüntüleri scratchpad/shots
G="/c/Users/Ömer/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
cd "$(dirname "$0")"
S="${SHOTS:-/c/Users/MER~1/AppData/Local/Temp/claude/C--Users--mer-Desktop-main/153949e2-d142-44a3-94dd-616a6ed8f216/scratchpad/shots}"
mkdir -p "$S"
timeout 300 "$G" --path . -- --shot="$S" --scene=${1:-desert} 2>&1 | grep -iE "error|DONE|at: " | grep -v "^$" | head -40
