extends Node
## Registers every InputMap action in code, so the action map in
## docs/PLAN.md lives in one reviewable place. Autoloaded as `Actions`.
## Gameplay reads these actions only, never raw devices.

const PITCH_UP := &"pitch_up"
const PITCH_DOWN := &"pitch_down"
const YAW_LEFT := &"yaw_left"
const YAW_RIGHT := &"yaw_right"
const ROLL_LEFT := &"roll_left"
const ROLL_RIGHT := &"roll_right"
const THRUST_FORWARD := &"thrust_forward"
const THRUST_BACK := &"thrust_back"
const WARP_UP := &"warp_up"
const WARP_DOWN := &"warp_down"
const LOOK_UP := &"look_up"
const LOOK_DOWN := &"look_down"
const LOOK_LEFT := &"look_left"
const LOOK_RIGHT := &"look_right"
const PAUSE := &"pause"
const TOGGLE_DEBUG := &"toggle_debug"

const STICK_DEADZONE: float = 0.2
const TRIGGER_DEADZONE: float = 0.1


## action -> list of event specs. Spec kinds:
##   ["key", Key]                 physical key (layout-independent)
##   ["axis", JoyAxis, -1.0|1.0]  joypad axis direction
##   ["button", JoyButton]        joypad button
static func bindings() -> Dictionary[StringName, Array]:
	return {
		# Left stick up / W = nose up. An invert option comes with Settings.
		PITCH_UP: [["key", KEY_W], ["axis", JOY_AXIS_LEFT_Y, -1.0]],
		PITCH_DOWN: [["key", KEY_S], ["axis", JOY_AXIS_LEFT_Y, 1.0]],
		YAW_LEFT: [["key", KEY_A], ["axis", JOY_AXIS_LEFT_X, -1.0]],
		YAW_RIGHT: [["key", KEY_D], ["axis", JOY_AXIS_LEFT_X, 1.0]],
		ROLL_LEFT: [["key", KEY_Q], ["button", JOY_BUTTON_LEFT_SHOULDER]],
		ROLL_RIGHT: [["key", KEY_E], ["button", JOY_BUTTON_RIGHT_SHOULDER]],
		THRUST_FORWARD: [["key", KEY_SHIFT], ["axis", JOY_AXIS_TRIGGER_RIGHT, 1.0]],
		THRUST_BACK: [["key", KEY_CTRL], ["axis", JOY_AXIS_TRIGGER_LEFT, 1.0]],
		WARP_UP: [["key", KEY_PERIOD], ["button", JOY_BUTTON_DPAD_UP]],
		WARP_DOWN: [["key", KEY_COMMA], ["button", JOY_BUTTON_DPAD_DOWN]],
		LOOK_UP: [["axis", JOY_AXIS_RIGHT_Y, -1.0]],
		LOOK_DOWN: [["axis", JOY_AXIS_RIGHT_Y, 1.0]],
		LOOK_LEFT: [["axis", JOY_AXIS_RIGHT_X, -1.0]],
		LOOK_RIGHT: [["axis", JOY_AXIS_RIGHT_X, 1.0]],
		PAUSE: [["key", KEY_ESCAPE], ["button", JOY_BUTTON_START]],
		TOGGLE_DEBUG: [["key", KEY_F3], ["button", JOY_BUTTON_BACK]],
	}


func _enter_tree() -> void:
	register_all()


## Adds every action to the InputMap. Safe to call more than once: an action
## that already exists (e.g. defined in Project Settings) keeps its events.
static func register_all() -> void:
	var map: Dictionary[StringName, Array] = bindings()
	for action: StringName in map:
		if InputMap.has_action(action):
			continue
		var is_axis_action: bool = map[action].any(func(s: Array) -> bool: return s[0] == "axis")
		var deadzone: float = STICK_DEADZONE if is_axis_action else 0.5
		if action == THRUST_FORWARD or action == THRUST_BACK:
			deadzone = TRIGGER_DEADZONE
		InputMap.add_action(action, deadzone)
		for spec: Array in map[action]:
			InputMap.action_add_event(action, make_event(spec))


static func make_event(spec: Array) -> InputEvent:
	match spec[0]:
		"key":
			var k := InputEventKey.new()
			k.physical_keycode = spec[1]
			k.device = -1
			return k
		"axis":
			var a := InputEventJoypadMotion.new()
			a.axis = spec[1]
			a.axis_value = spec[2]
			a.device = -1
			return a
		"button":
			var b := InputEventJoypadButton.new()
			b.button_index = spec[1]
			b.device = -1
			return b
	push_error("Actions: unknown event spec %s" % [spec])
	return null
