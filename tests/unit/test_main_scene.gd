extends GutTest
## Smoke test: the main scene loads headless and builds its nodes.

var _main: Node3D


func before_each() -> void:
	_main = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	add_child_autofree(_main)
	await wait_physics_frames(2)


func test_camera_uses_true_scale_planes() -> void:
	var cam: Camera3D = _main.get_node("Camera")
	assert_almost_eq(cam.near, Units.CAMERA_NEAR_KM, 1e-9)  # node props are 32-bit
	assert_almost_eq(cam.far, Units.CAMERA_FAR_KM, 1.0)
	assert_true(cam.current)


func test_debug_overlay_exists_and_toggles() -> void:
	var overlay: DebugOverlay = _main.get_node("DebugOverlay")
	assert_not_null(overlay)
	var before: bool = overlay.details_visible()
	overlay.toggle_details()
	assert_ne(overlay.details_visible(), before)


func test_overlay_reports_engine_and_renderer() -> void:
	var overlay: DebugOverlay = _main.get_node("DebugOverlay")
	var text: String = "\n".join(overlay.detail_lines())
	assert_string_contains(text, "Godot 4.")
	assert_string_contains(text, "Renderer:")
	assert_string_contains(text, "Draw calls:")
