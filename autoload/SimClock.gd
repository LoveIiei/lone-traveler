extends Node
## Simulation clock with time warp. Autoloaded as `SimClock`.
## It runs first each physics tick (process_priority -100), so sim code can
## read `delta` (scaled seconds this tick) and `time` (sim seconds elapsed).
## Pausing the SceneTree pauses the clock.

const WARP_LEVELS: Array[float] = [1.0, 10.0, 100.0, 1000.0, 10000.0]

var time: float = 0.0
var delta: float = 0.0
var warp_index: int = 0


func _ready() -> void:
	process_priority = -100
	process_physics_priority = -100


func _physics_process(real_delta: float) -> void:
	step(real_delta)


func warp() -> float:
	return WARP_LEVELS[warp_index]


## Advance the clock by `real_delta` real seconds; returns the scaled delta.
func step(real_delta: float) -> float:
	delta = real_delta * warp()
	time += delta
	return delta


func set_warp_index(index: int) -> void:
	var clamped: int = clampi(index, 0, WARP_LEVELS.size() - 1)
	if clamped == warp_index:
		return
	warp_index = clamped
	Events.time_warp_changed.emit(warp())


func warp_up() -> void:
	set_warp_index(warp_index + 1)


func warp_down() -> void:
	set_warp_index(warp_index - 1)


func reset() -> void:
	time = 0.0
	delta = 0.0
	warp_index = 0
