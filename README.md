# Lone Traveler

A free, open-source Godot game: ride a spacecraft from Earth's surface to the
Moon at true scale, using real NASA imagery and elevation data. Desktop with a
gamepad first, then VR (OpenXR headsets and phone Cardboard).

**Status:** M0 scaffold. See [docs/PLAN.md](docs/PLAN.md) for the plan and milestones.

## Run it

1. Install [Godot 4.7+](https://godotengine.org/download) (standard build, not .NET).
2. `godot --path . -e` to open the editor, then press F5, or `godot --path .` to play.

Controls (M0): `F3` debug overlay · `Esc` pause · `,` / `.` time warp.

## Develop

- `tools/test.sh`: unit tests, headless (GUT)
- `tools/screenshot.sh`: render test screenshots to `tests/screenshot/out/`

## License

Code: Apache-2.0. Assets and data: see [CREDITS.md](CREDITS.md).
Not affiliated with or endorsed by NASA.
