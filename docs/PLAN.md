# Lone Traveler: Build Plan

Nov 24, 2026 · Owen

## Vision & scope

Lone Traveler is a free, open-source Godot game where you ride a spacecraft from Earth's surface to the Moon, at true scale, using real NASA imagery and elevation data. It ships first as a desktop app played with a gamepad, then in VR: headsets through OpenXR and a phone in a cardboard viewer.

### Goals

- **Real data:** textures and terrain come from NASA missions (LRO for the Moon, Blue Marble for Earth), with credits shown in the game.
- **True scale:** real radii and the real ~384,400 km Earth–Moon distance.
- **Feel:** rumble on the controller during launch, staging and burns. A vibrating chair can plug into the same haptics layer later.
- **Room to grow:** new bodies, ships and creatures (aliens included) are new Godot scenes, not rewrites.
- **Reach:** free downloads for Windows, Linux and Android on GitHub Releases, plus a lighter web demo.

### Non-goals for v1

- Accurate orbital physics. The launch is a scripted ride; free-flight is arcade-style.
- Other planets until the Moon is excellent.
- Multiplayer.

**Decisions:** code under Apache-2.0; the spacecraft is a free, openly licensed 3D model (not custom-built); every asset is listed in CREDITS.md with its source and terms. Non-commercial, no NASA logo, no implied NASA endorsement.

## Tech stack

Godot 4 (latest stable, 4.6 or newer) with GDScript, built as a native desktop app first. Godot gives you an editor, scenes, physics, animation and navigation, so a growing universe (and aliens) means adding content, not engine code.

### Why Godot over Three.js, and what it costs

| | Godot | Three.js (previous plan) |
|---|---|---|
| Growing content (ships, creatures, AI, physics, animation) | Built-in editor and systems | Everything hand-written |
| Desktop rendering | Vulkan Forward+ renderer | WebGL2 in a browser |
| Headset VR | OpenXR built in (Quest, SteamVR, Android XR) | WebXR only |
| Web build | Possible, but Compatibility renderer (WebGL2) only and a larger download | Native to the web |
| Phone Cardboard | No maintained plugin found; we build a stereo mode ourselves (M3) | Chrome WebXR supports it |
| True-scale precision | Single precision + floating origin; double precision needs a custom engine build | Floating origin |

### Stack

| Layer | Choice | Notes |
|---|---|---|
| Engine | Godot 4.6+ standard build (not .NET) | C# projects can't export to the web, so the core stays in GDScript |
| Language | GDScript with static typing; C++ GDExtension only for proven hot spots | You already know C++ |
| Renderer | Forward+ on desktop, Mobile on Android, Compatibility for web | Pick per export preset |
| VR | Godot OpenXR + OpenXR Vendors plugin; custom Cardboard stereo mode | See M3 |
| Input / haptics | Godot InputMap actions; `Input.start_joy_vibration()` | Standard Xbox/PlayStation pads |
| Audio | Godot AudioStreamPlayer + buses | Engine sound tracks thrust |
| Asset pipeline | Python 3 (Pillow, NumPy) scripts → PNG/EXR → Godot import with VRAM compression | Godot compresses per platform on import |
| Tests | GUT or gdUnit4, run headless | Claude Code can run them from the terminal (chosen: **GUT 9.7**) |
| Version control | Git + Git LFS for textures over ~10 MB | `.godot/` cache stays out of git |
| Release | GitHub Actions exports Windows, Linux, Android and Web | Web demo on GitHub Pages or itch.io |

**Units everywhere:** 1 Godot unit = 1 km, time in seconds. World positions live in 64-bit floats (GDScript `float` is 64-bit), and only camera-relative positions reach the scene tree.

## Architecture

The simulation keeps world positions in 64-bit floats in plain GDScript objects; each frame, scene nodes are placed relative to the camera. That split keeps true scale stable without a custom double-precision engine build.

Input becomes actions, actions drive the simulation, and the renderer and the listeners (haptics, chair, audio, HUD) only react to it.

### Project layout

```
lone-traveler/
  project.godot
  CLAUDE.md               # rules for Claude Code (see last section)
  CREDITS.md              # every asset, its source and terms
  LICENSE                 # Apache-2.0
  docs/PLAN.md            # this plan
  tools/assets/           # Python: download + convert NASA data (not exported)
  assets/                 # generated textures (Git LFS), ship model, audio
  autoload/               # Units.gd, SimClock.gd (time warp), Events.gd (signal bus)
  sim/                    # Body.gd, Ship.gd, Gravity.gd, Mission.gd (scripted ride)
  world/                  # FloatingOrigin.gd, Planet.tscn, Earth.tscn, Moon.tscn, Stars.tscn
  shaders/                # earth.gdshader, atmosphere.gdshader, moon.gdshader
  ship/                   # Ship.tscn, Cockpit.tscn, Hud.tscn
  input/                  # Actions.gd (wraps InputMap), Haptics.gd, haptic_patterns.gd
  xr/                     # XRSetup.gd (OpenXR), CardboardRig.tscn, Comfort.gd
  audio/                  # Engine.gd, buses
  ui/                     # Menu.tscn, Credits.tscn, Settings.tscn
  tests/                  # GUT or gdUnit4 tests, screenshot scene
  main.tscn
```

### Scale and precision rules

- Real sizes: Earth radius 6,371 km, Moon radius 1,737.4 km, mean distance 384,400 km.
- Floating origin: `FloatingOrigin.gd` keeps the camera at (0, 0, 0). Every frame it sets each body node's position to its 64-bit world position minus the camera's, so `Vector3` (32-bit) only ever holds small numbers near the player.
- Camera near plane 0.001 km (1 m), far plane 2,000,000 km. If z-fighting appears, render distant bodies in a separate far-camera layer.
  - **Measured in M0 (Godot 4.7.2):** a single camera with far/near ≥ ~1e8 makes the light culler fail every frame (`create_frustum_points` errors); 1e7 is clean. So the near camera is 1 m–10,000 km, and M1 needs the far-camera layer from day one (e.g. 1 km–2,000,000 km) for Earth and Moon at distance. `Units.MAX_CAMERA_DEPTH_RATIO` and a unit test guard this.
- Physics for the ship stays near the origin; bodies far away are not physics objects.
- Double-precision builds stay an option for later; the design doesn't depend on them.

**Frame loop:** read input → actions → step sim in `_physics_process` (60 Hz, scaled by time warp) → rebase floating origin → update LOD and shaders → render (window or XR) → haptics, audio and HUD react to Events signals.

Haptics, audio and HUD only listen to Events signals (`ignition`, `staging`, `burn_started`, `burn_ended`, `touchdown`). A vibrating chair later becomes one more listener.

## Data & assets

You may refer to these assets if needed: `~/Documents/GameAssets/`

Everything comes from public data; a Python script downloads and converts it, and Godot compresses the results for each platform when it imports them.

| Asset | Source | Used for | Generated files |
|---|---|---|---|
| Moon color | NASA SVS CGI Moon Kit (LROC color map) | Moon albedo | PNG 2K / 4K / 8K |
| Moon elevation | NASA SVS CGI Moon Kit (LOLA displacement, 4/16/64 px per degree) | Terrain height + normal map | 16-bit PNG or EXR height, PNG normal map |
| Earth day | NASA Blue Marble Next Generation (Visible Earth) | Earth surface | PNG 2K / 4K / 8K |
| Earth night | NASA Black Marble (city lights) | Night side | PNG 2K / 4K |
| Earth clouds | NASA Visible Earth cloud layer | Cloud shell | PNG 2K / 4K |
| Stars | NASA SVS Deep Star Maps | Sky background (panorama sky) | EXR or PNG 4K / 8K |
| Spacecraft | A free, openly licensed model (check NASA's 3D resources first, then CC0/CC-BY sites) | Ship exterior + cockpit view | glTF (.glb) |
| Positions | JPL Horizons (Moon and Sun vectors) | Real positions for a chosen date (M4) | Small JSON table |

URLs other than the Moon Kit must be checked by Claude Code before writing the download script; record each exact page and license in CREDITS.md.

### Pipeline (`python tools/assets/build.py`)

1. Download originals into `tools/assets/.cache/` (git-ignored); verify size and checksum.
2. Resize each map to its tiers with Pillow; keep heights 16-bit.
3. Derive the Moon normal map from the elevation map with NumPy (scaled by real km).
4. Write results to `assets/textures/`, tracked by Git LFS, plus `assets/manifest.json` (file, tier, source URL, credit line).
5. Godot imports them with VRAM compression (desktop and mobile formats chosen per export preset).

**Loading:** desktop loads 4K by default and 8K for whichever body is close; Android and the web demo use 2K.

**Rules:** only NASA or clearly licensed data and models; no NASA insignia or logos; the in-game Credits screen is built from the manifest.

## Milestones

Six milestones, each ending in something playable. Claude Code builds one at a time and doesn't start the next until the current gate passes.

### M0: Scaffold

- [x] Godot 4.6+ project (lone-traveler), Forward+ renderer, typed GDScript, folder layout above
- [x] CLAUDE.md, CREDITS.md, Apache-2.0 LICENSE, docs/PLAN.md, .gitignore (.godot/), Git LFS for assets/textures/
- [x] Test framework (GUT or gdUnit4) running headless; a screenshot scene that saves a PNG
- [x] Export presets: Windows, Linux, Android, Web (single-threaded)
- [x] GitHub Actions: run tests and export builds on every push
- [x] Empty space scene with an FPS counter and a debug overlay

**Gate:** tests pass headless; CI produces a Windows build that opens.

### M1: Earth and Moon at true scale

- [ ] Asset pipeline for Earth day/night/clouds, Moon color and elevation, stars
- [ ] FloatingOrigin.gd; Earth and Moon at real size and distance
- [ ] Earth shader: day/night blend at the terminator, city lights, cloud shell, atmosphere rim
- [ ] Moon: high-subdivision sphere with height displacement + normal map, lit by the Sun
- [ ] Free-fly camera: keyboard/mouse and gamepad, speed scales with altitude
- [ ] Rumble on boost and on a close surface pass
- [ ] Tests for floating-origin math and unit conversions

**Gate:** fly from low Earth orbit to 5 km above the Moon with no jitter or z-fighting, at 60 fps on your laptop.

### M2: The launch ride

- [ ] Free spacecraft model imported; cockpit view with a window and HUD (altitude, speed, distance to Moon, mission time)
- [ ] Launch pad on a simple ground patch; countdown, ignition, liftoff
- [ ] Scripted mission (AnimationPlayer or Mission.gd timeline): ascent → staging → orbit → trans-lunar burn → coast → lunar orbit
- [ ] Time warp (1× to 10,000×) during the coast, dropping to 1× before events
- [ ] Haptic and audio patterns tied to Events signals
- [ ] After lunar orbit, hand control to the player (free-flight)

**Gate:** the full ride from countdown to lunar orbit plays end to end in about 10 minutes with time warp.

### M3: VR

- [ ] OpenXR for headsets (PC VR through SteamVR, Quest and Android XR as Android exports with the OpenXR Vendors plugin)
- [ ] Cardboard mode on Android: CardboardRig.tscn with two cameras side by side (64 mm apart), head rotation from the phone's gyroscope and gravity sensors, optional lens-distortion shader
- [ ] Web demo: try Godot's WebXR interface on Android Chrome as a bonus, not a requirement
- [ ] Comfort: vignette during acceleration, no forced horizon roll, snap turning
- [ ] Mobile renderer, 2K textures and resolution scaling on phones

**Gate:** the ride runs at a steady 60 fps in Cardboard mode on a mid-range Android phone, and on one OpenXR headset if you can borrow one.

### M4: Detail and accuracy

- [ ] Moon terrain as a quadtree cube-sphere with LOD chunks (move to C++ GDExtension if GDScript is too slow)
- [ ] Apollo landing sites as markers with short info cards
- [ ] Real Moon and Sun positions for a chosen date (JPL Horizons data)
- [ ] Better Earth atmosphere scattering

**Gate:** fly at 1 km altitude over a crater with visible detail and no popping.

### M5: Beyond the Moon

- [ ] Mars and the Sun, then more of the solar system
- [ ] Creatures and encounters (aliens): characters, animation, simple AI with Godot navigation
- [ ] A contributor guide for adding a body or creature (scene + data, no engine changes)

## Input, haptics and VR

All devices map to the same Godot InputMap actions, so gameplay code never checks which device is in use.

### Action map

| Action | Gamepad (standard mapping) | Keyboard / mouse | Cardboard |
|---|---|---|---|
| Pitch / yaw | Left stick | Mouse drag or W/S/A/D | Head movement |
| Roll | Bumpers (LB/RB) | Q / E | None |
| Thrust forward / back | Right trigger / left trigger | Shift / Ctrl | Hold the button |
| Time warp up / down | D-pad up / down | . / , | Menu |
| Look around cockpit | Right stick | Right-mouse drag | Head movement |
| Pause / menu | Start | Esc | Gaze at menu + tap |

### Haptic patterns (`input/haptic_patterns.gd`; values are starting points to tune)

| Event | Strong motor | Weak motor | Duration |
|---|---|---|---|
| Ignition build-up | 0 → 0.8 ramp | 0.3 | 3 s |
| Ascent (continuous) | Tracks thrust × 0.7 | Random flicker 0.2–0.4 | While engines burn |
| Stage separation | 1.0 | 1.0 | 150 ms, then 0 for 300 ms |
| Engine burn | Thrust × 0.4 | 0.2 | Burn length |
| Touchdown or bump | 0.9 | 0.5 | 200 ms |

`Haptics.gd` plays these with `Input.start_joy_vibration(device, weak, strong, duration)`, re-issued every ~100 ms for continuous rumble and stopped with `Input.stop_joy_vibration()`. Settings get a haptic-strength slider and an off switch. A later "chair" adapter receives the same pattern stream, for example through a small GDExtension that writes to a serial port on an Arduino driving motors. Check rumble on Windows and Linux separately, since gamepad driver support differs.

### VR comfort rules

- The player's head is never moved by the camera rig except through the ship; the cockpit is a stable frame.
- No forced roll of the horizon; strong accelerations add a vignette.
- Time warp fades to black for 0.3 s when it changes.
- Text in VR sits at least 1.5 m away and is large enough to read on a phone.

## Testing, performance and releases

Every milestone ships with headless tests and stays inside the budgets below; CI blocks a merge that breaks either.

### Performance budgets

| Target | Frame rate | Draw calls | Texture memory | Download size |
|---|---|---|---|---|
| Laptop (your Legion), Forward+ | 60 fps at 1440p | < 1,500 | < 2 GB | < 1 GB |
| PC VR / Quest, OpenXR | 72–90 fps (headset refresh) | < 500 | < 1 GB | < 1 GB |
| Mid-range Android, Cardboard | 60 fps | < 200 | < 400 MB | < 300 MB APK |
| Web demo, Compatibility | 30–60 fps | < 200 | < 300 MB | < 60 MB |

### Tests

- **Unit tests** (GUT, run with `godot --headless`): floating-origin rebasing, unit conversions, time warp, mission timeline (events fire in order and on time), haptic pattern output.
- **Screenshot test:** a scene places the camera at fixed spots (Earth orbit, halfway, Moon close-up), saves PNGs, and compares them with baselines. Claude Code can open these PNGs to check its own visual work.
- **Smoke test:** the ride reaches lunar orbit at maximum time warp with no errors in the log.
- **Manual checklist per milestone:** real gamepad rumble, Android Cardboard mode, a headset if available.

**Phone testing:** use Godot's one-click deploy to an Android phone over USB (adb), and read logs with `adb logcat`.

**Releases:** GitHub Actions exports on every tag: Windows and Linux zips plus an Android APK on GitHub Releases, and the single-threaded web demo on GitHub Pages or itch.io.

## Handing this to Claude Code

Local tools to install first: Godot 4.6+ (standard build, not .NET) with its export templates, Git + Git LFS, GitHub CLI (`gh`), Python 3 with Pillow and NumPy, Android Studio's SDK + JDK 17 for Android exports, and adb for phone testing. Add the Godot binary to your PATH so Claude Code can run `godot --headless`.

### Working tips

- One milestone per session keeps context focused; start a new session for the next one and point it at docs/PLAN.md.
- Keep the Godot editor open while Claude Code works; it reloads changed scripts and scenes. Reopen a scene if Claude Code edited it while it was open.
- When something looks wrong, give Claude Code a screenshot; visual bugs are faster to fix from a picture.
- Test rumble, Cardboard mode and headsets yourself on real hardware.

## Risks and open questions

| Risk | Impact | Fallback |
|---|---|---|
| Precision jitter at true scale | Shaking camera, flickering surfaces | Floating origin from M1 day one; far-camera layer for distant bodies (required: see the M0 measurement under Scale and precision rules); double-precision build as a last resort |
| No maintained Cardboard plugin for Godot | Phone VR takes custom work | Our own two-camera stereo rig with gyroscope head tracking (M3) |
| Phones overheat or drop frames in VR | Motion sickness, bad first impression | Mobile renderer, 2K textures, resolution scaling, fewer shader effects |
| Web demo is heavy and limited to WebGL2 | Slow first load; fewer effects | Treat web as a demo: smaller textures, Compatibility renderer, link to full downloads |
| GDScript too slow for terrain LOD | Stutter when flying low | Move the quadtree to a C++ GDExtension |
| Claude Code mis-edits .tscn scene files | Broken scenes | Build complex node trees in scripts; review scene diffs; commit often |
| Asset licensing mistakes | Takedown or attribution issues | Only NASA or clearly licensed data and models; manifest-driven credits |
| Scope creep (Mars, aliens, n-body physics) | Never ships | Hold to milestone gates; M5 only after M3 is public |

**Decided:** name Lone Traveler · Apache-2.0 · a free spacecraft model · Godot engine · GUT for tests.

### Open questions

- Which free spacecraft model, and under which license (CC0 or CC-BY are easiest)?
- ~~GUT or gdUnit4 for tests?~~ GUT (decided in M0).
- OpenSpace is worth reading for ideas on data and rendering, though it is a large C++ app and not a base for this project.

## Sources

- NASA SVS: CGI Moon Kit — https://svs.gsfc.nasa.gov/4720
- Godot docs: Large world coordinates — https://docs.godotengine.org/en/stable/tutorials/physics/large_world_coordinates.html
- Godot docs: Exporting for the Web — https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- Godot: OpenXR Vendors plugin — https://github.com/GodotVR/godot_openxr_vendors
- OpenSpace on GitHub — https://github.com/OpenSpace/OpenSpace
