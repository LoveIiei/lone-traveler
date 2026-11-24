@warning_ignore_start("unused_signal")
extends Node
## Global signal bus. The sim emits; haptics, audio, HUD (and later a chair)
## listen. Listeners never read input directly.

## Engines light. Haptics ramp up, audio starts the roar.
signal ignition
## A stage separates. `stage` is the index of the stage that was dropped.
signal staging(stage: int)
## A named burn starts or ends (e.g. "ascent", "tli", "loi"). `thrust` is 0..1.
signal burn_started(burn_name: String, thrust: float)
signal burn_ended(burn_name: String)
## The ship touches or bumps a surface. `body_name` is the body hit.
signal touchdown(body_name: String)
## Time warp factor changed (1 = real time).
signal time_warp_changed(warp: float)
