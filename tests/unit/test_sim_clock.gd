extends GutTest


func before_each() -> void:
	SimClock.reset()


func after_each() -> void:
	SimClock.reset()


func test_starts_at_real_time() -> void:
	assert_eq(SimClock.warp(), 1.0)
	assert_eq(SimClock.time, 0.0)


func test_step_scales_by_warp() -> void:
	SimClock.set_warp_index(2)
	var d: float = SimClock.step(0.5)
	assert_eq(d, 50.0)
	assert_eq(SimClock.time, 50.0)


func test_warp_is_clamped_from_1x_to_10000x() -> void:
	for i: int in 10:
		SimClock.warp_up()
	assert_eq(SimClock.warp(), 10000.0)
	for i: int in 10:
		SimClock.warp_down()
	assert_eq(SimClock.warp(), 1.0)


func test_warp_change_emits_event_once_per_change() -> void:
	watch_signals(Events)
	SimClock.warp_up()
	SimClock.warp_down()
	SimClock.warp_down()  # already at 1x: no signal
	assert_signal_emit_count(Events, "time_warp_changed", 2)
	assert_signal_emitted_with_parameters(Events, "time_warp_changed", [1.0])
