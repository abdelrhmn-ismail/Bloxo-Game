#!/usr/bin/env bash
# Builds the signed release files:
#   build/bloxo-release.aab  -> upload to Google Play
#   build/bloxo-release.apk  -> install on your own phone
#
#   GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64 tools/export_release.sh
#
# The first run creates the release keystore (outside the project).
# The password is read from <keystore>.pass if present, else typed here.
#
# !!! BACK UP the keystore file AND its password in 3 places.
# !!! Losing either means the game can never be updated on Google Play.
set -euo pipefail

cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
KEYTOOL="${KEYTOOL:-$HOME/tools/jdk17/bin/keytool}"
KEYSTORE="${BLOXO_KEYSTORE:-$HOME/keystores/bloxo-release.keystore}"
ALIAS="bloxo"

command -v "$GODOT" >/dev/null 2>&1 || [ -x "$GODOT" ] || { echo "Godot not found: set GODOT=/path/to/godot"; exit 1; }

if [ ! -f "$KEYSTORE" ]; then
	echo "== No release keystore yet: creating $KEYSTORE"
	echo "   Choose a strong password and WRITE IT DOWN before continuing."
	mkdir -p "$(dirname "$KEYSTORE")"
	"$KEYTOOL" -genkeypair -v -keystore "$KEYSTORE" -alias "$ALIAS" \
		-keyalg RSA -keysize 2048 -validity 10000
	chmod 600 "$KEYSTORE"
	echo "== Keystore created. Back it up NOW (USB stick, cloud drive, email)."
fi

# Password: from "<keystore>.pass" next to the keystore if it exists
# (outside the project, owner-only), otherwise typed at the prompt.
PASS_FILE="${KEYSTORE%.keystore}.pass"
if [ -f "$PASS_FILE" ]; then
	PASS="$(cat "$PASS_FILE")"
else
	read -r -s -p "Keystore password: " PASS
	echo
fi

mkdir -p build
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KEYSTORE"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$ALIAS"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$PASS"

# 1) AAB for Google Play
"$GODOT" --headless --path . --install-android-build-template \
	--export-release "Android Release" build/bloxo-release.aab
# 2) Release APK (same key) to install on your own phone
"$GODOT" --headless --path . --export-release "Android" build/bloxo-release.apk

ls -la build/bloxo-release.aab build/bloxo-release.apk
echo "== Done: build/bloxo-release.aab (Google Play) + build/bloxo-release.apk (phone)"
