# Lone Traveler

Read docs/PLAN.md before any work. Build one milestone at a time.

## Rules
- Godot 4.6+ (currently 4.7.2), typed GDScript. No C# (breaks web export).
  Untyped declarations are errors (project setting), so type everything.
- 1 Godot unit = 1 km. World positions are 64-bit floats in sim/;
  scene nodes only get camera-relative positions via FloatingOrigin.gd.
  Node properties (Vector3, Camera3D.near, ...) are 32-bit: compare with
  assert_almost_eq in tests.
- One Camera3D can't exceed far/near ≈ 1e7 (light culler errors past that).
  Near camera is 1 m–10,000 km; distant bodies use a far-camera layer.
- Edit .tscn/.tres files carefully; prefer building nodes in scripts
  when a scene would be hard to edit as text.
- Never commit .godot/ or raw NASA downloads; textures go through
  tools/assets/build.py and Git LFS.
- Every new asset or model gets a CREDITS.md entry with source + license.
- Gameplay reads InputMap actions only, never raw devices. Actions are
  registered in code in input/Actions.gd (not in project.godot).
- Haptics/audio/HUD react to Events signals; they never read input.
- Before calling a task done: run the headless tests and the screenshot
  scene, then look at the screenshots.
- Tick off the task in docs/PLAN.md and commit with a clear message.
- Ask before adding an addon or GDExtension.

## Commands
- Tests (headless, GUT): `tools/test.sh` (one script: `tools/test.sh -gselect=test_units`)
- Screenshots (needs a window): `tools/screenshot.sh` → `tests/screenshot/out/*.png`
- Run the game: `godot --path .`   Open the editor: `godot --path . -e`
- Export locally: `godot --headless --path . --export-release "Linux" build/linux/LoneTraveler.x86_64`
  (presets: "Windows Desktop", "Linux", "Android", "Web")
- Override the binary with `GODOT=/path/to/godot tools/test.sh`.

## Layout notes
- Autoloads: Events (signal bus), Units (constants + formatting), SimClock
  (time warp; runs first each physics tick), Actions (InputMap registration).
- main.tscn runs with PROCESS_MODE_ALWAYS so Esc can unpause; sim nodes under
  it must set PROCESS_MODE_PAUSABLE.
- addons/gut is dev-only and excluded from exports, as are tests/, tools/, docs/.
