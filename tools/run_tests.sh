#!/usr/bin/env bash
# MEVZİ sahne testleri — Linux/macOS/CI çalıştırıcısı (Windows: tools/run_tests.ps1)
# Kullanım: GODOT=/yol/godot tools/run_tests.sh [--headless] [--timeout 600] [sahne1 sahne2 ...]
# Her sahne ayrı süreçte, süre sınırlı çalışır. Çıkış kodu: tüm sahneler "RESULT fails=0" ise 0.
# --headless: çizimsiz (ekran görüntüleri atlanır, yalnız mantık denetlenir; GPU gerekmez)
set -u
GODOT="${GODOT:-godot}"
TIMEOUT=600
HEADLESS=""
SCENES=()
while [ $# -gt 0 ]; do
	case "$1" in
		--headless) HEADLESS="--headless" ;;
		--timeout) shift; TIMEOUT="$1" ;;
		*) SCENES+=("$1") ;;
	esac
	shift
done
[ ${#SCENES[@]} -eq 0 ] && SCENES=(treetest dronetest woundtest ropetest crewtest paratest para2test fowtest tactest evadetest vfxtest rocktest largetest ammotest)
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOGS="$ROOT/shots/logs"
mkdir -p "$LOGS" && touch "$ROOT/shots/.gdignore"
"$GODOT" --headless --path "$ROOT" --import > "$LOGS/_import.log" 2>&1
if grep -qE "SCRIPT ERROR|Parse Error|Compile Error" "$LOGS/_import.log"; then
	grep -E "SCRIPT ERROR|Parse Error|Compile Error" "$LOGS/_import.log"; echo "Betik hataları var, testler durduruldu."; exit 1
fi
bad=0
for s in "${SCENES[@]}"; do
	mkdir -p "$ROOT/shots/$s"
	t0=$(date +%s)
	timeout "$TIMEOUT" "$GODOT" $HEADLESS --path "$ROOT" -- --shot="$ROOT/shots/$s" --scene="$s" > "$LOGS/$s.log" 2>&1
	rc=$?
	res=$(tr -d '\0' < "$LOGS/$s.log" | grep -oE "[A-Z0-9]+ RESULT fails=[0-9]+" | head -1)
	if [ $rc -eq 124 ]; then out="TIMEOUT"
	elif grep -q "SCRIPT ERROR" "$LOGS/$s.log"; then out="SCRIPT ERROR"
	elif [ -z "$res" ]; then out="CRASH/NO RESULT"
	elif [ "${res##*=}" = "0" ]; then out="OK"
	else out="FAIL"; fi
	[ "$out" != "OK" ] && bad=$((bad + 1))
	printf "%-14s %-16s %4ss  %s\n" "$s" "$out" "$(( $(date +%s) - t0 ))" "$res"
done
[ $bad -gt 0 ] && { echo "$bad sahne başarısız/takıldı"; exit 1; }
echo "Tüm sahneler geçti"
