extends Node3D
## Root scene. M0: an empty space scene with a camera, a sun light and the
## debug overlay. Nodes are built in code so the .tscn stays trivial.
## Main runs with PROCESS_MODE_ALWAYS (set in main.tscn) so it can unpause;
## sim nodes added under it must set PROCESS_MODE_PAUSABLE themselves.

var camera: Camera3D
var sun: DirectionalLight3D
var overlay: DebugOverlay


func _ready() -> void:
	_build_environment()

	camera = Camera3D.new()
	camera.name = "Camera"
	camera.near = Units.CAMERA_NEAR_KM
	camera.far = Units.CAMERA_FAR_KM
	camera.fov = 70.0
	add_child(camera)
	camera.make_current()

	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-30.0, 40.0, 0.0)
	add_child(sun)

	overlay = DebugOverlay.new()
	overlay.camera = camera
	add_child(overlay)
	overlay.set_details_visible(OS.is_debug_build())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(Actions.TOGGLE_DEBUG):
		overlay.toggle_details()
	elif event.is_action_pressed(Actions.PAUSE):
		get_tree().paused = not get_tree().paused
	elif event.is_action_pressed(Actions.WARP_UP):
		SimClock.warp_up()
	elif event.is_action_pressed(Actions.WARP_DOWN):
		SimClock.warp_down()
	else:
		return
	get_viewport().set_input_as_handled()


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	add_child(world_env)
