#!/usr/bin/env bash
# Run the GUT unit tests headless. Exit code is non-zero on failure.
# Usage: tools/test.sh [extra GUT args, e.g. -gselect=test_units]
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
# Import first so class_name and resource caches exist on a fresh checkout.
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json "$@"
