#!/bin/bash
# Godot içe aktarma + betik hatalarını dosya:satır olarak listele
G="/c/Users/Ömer/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
cd "$(dirname "$0")"
timeout 240 "$G" --headless --path . --import 2>&1 | grep -B0 -A2 "SCRIPT ERROR\|^ERROR" | grep -v "^--$" | head -${1:-60}
