#!/usr/bin/env bash
# Renders the Google Play screenshots (1080x1920) into store/screenshots/.
#   tools/make_store_screenshots.sh
# Your real save file is backed up first and put back afterwards.
set -euo pipefail
cd "$(dirname "$0")/.."

DEFAULT_GODOT="../Games Tools/Godot_v4.7.2-stable_linux.x86_64"
[ -x "$DEFAULT_GODOT" ] || DEFAULT_GODOT="godot"
GODOT="${GODOT:-$DEFAULT_GODOT}"
OUT="$PWD/store/screenshots"
SAVE="$HOME/.local/share/godot/app_userdata/Bloxo/save.json"
LANG_CODE="${1:-en}"

mkdir -p "$OUT"
BACKUP=""
if [ -f "$SAVE" ]; then
	BACKUP="$(mktemp)"
	cp -p "$SAVE" "$BACKUP"
fi
restore() { if [ -n "$BACKUP" ]; then cp -p "$BACKUP" "$SAVE"; rm -f "$BACKUP"; fi; }
trap restore EXIT

shot() { # name theme screen score best
	timeout 60 "$GODOT" --path . res://tools/store_shot.tscn -- --lang="$LANG_CODE" \
		--theme="$2" --screen="$3" --score="$4" --best="$5" --shot="$OUT/$1.png" 2>&1 | grep -E "saved|SCRIPT ERROR" || true
}

shot 01-neon-game     neon   game-demo     1260 2480
shot 02-menu          neon   menu          0    2480
shot 03-candy-game    candy  game-demo     845  2480
shot 04-gems-game     gems   game-demo     1730 2480
shot 05-nature-game   nature game-demo     2110 2480
shot 06-hint          candy  hint          530  2480
shot 07-settings      gems   settings      0    2480
shot 08-game-over     nature gameover      2715 2715
echo "== Screenshots in store/screenshots/"
