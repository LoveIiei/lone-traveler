#!/usr/bin/env bash
# Render the screenshot scene in a real window and save PNGs to
# tests/screenshot/out/. Usage: tools/screenshot.sh
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
"$GODOT" --path . --resolution 1920x1080 res://tests/screenshot/screenshot.tscn
ls -1 tests/screenshot/out/*.png
