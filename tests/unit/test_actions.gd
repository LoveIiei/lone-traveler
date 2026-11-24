extends GutTest


func test_every_action_is_registered() -> void:
	for action: StringName in Actions.bindings():
		assert_true(InputMap.has_action(action), "missing action %s" % action)


func test_each_action_has_its_events() -> void:
	var map: Dictionary[StringName, Array] = Actions.bindings()
	for action: StringName in map:
		assert_eq(InputMap.action_get_events(action).size(), map[action].size(), str(action))


func test_register_all_is_idempotent() -> void:
	Actions.register_all()
	assert_eq(InputMap.action_get_events(Actions.PAUSE).size(), 2)


func test_keyboard_and_gamepad_trigger_same_action() -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_ESCAPE
	key.pressed = true
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_START
	pad.pressed = true
	assert_true(key.is_action_pressed(Actions.PAUSE))
	assert_true(pad.is_action_pressed(Actions.PAUSE))


func test_right_trigger_is_thrust_forward() -> void:
	var rt := InputEventJoypadMotion.new()
	rt.axis = JOY_AXIS_TRIGGER_RIGHT
	rt.axis_value = 1.0
	assert_true(rt.is_action(Actions.THRUST_FORWARD))
	assert_almost_eq(rt.get_action_strength(Actions.THRUST_FORWARD), 1.0, 0.001)
