#!/usr/bin/env bash
# Linux / GitHub Actions entry point. Godot stages the playable assets before Gradle runs.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
GODOT_BIN="${GODOT_BIN:-godot}"
if [[ "$("$GODOT_BIN" --version)" != 4.6.3.stable.* ]]; then
  echo 'This project requires Godot 4.6.3 Standard.' >&2
  exit 1
fi
python3 tools/prepare_android.py
mkdir -p builds
XDG_CONFIG_HOME="$PWD/.godot/android-config" "$GODOT_BIN" --headless --editor --import --quit
"$GODOT_BIN" --headless --script res://tests/run.gd
XDG_CONFIG_HOME="$PWD/.godot/android-config" "$GODOT_BIN" --headless --export-debug Android builds/sky-bounce.apk
# Never advertise a missing, unsigned, empty, or game-content-free artifact.
python3 tools/verify_apk.py builds/sky-bounce.apk
"${ANDROID_HOME:-${ANDROID_SDK_ROOT:?}}/build-tools/36.1.0/apksigner" verify --verbose builds/sky-bounce.apk
sha256sum builds/sky-bounce.apk > builds/sky-bounce.apk.sha256
