class_name DebugOverlay
extends CanvasLayer
## FPS counter (always on) plus a details panel toggled with the
## `toggle_debug` action (F3 / gamepad Back). Built in code, no .tscn.

const REFRESH_SECONDS: float = 0.25

var camera: Camera3D
var paused_label: Label

var _fps_label: Label
var _details_panel: PanelContainer
var _details_label: Label
var _accum: float = 0.0


func _init() -> void:
	name = "DebugOverlay"
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "top", "right", "bottom"]:
		root.add_theme_constant_override("margin_" + side, 12)
	add_child(root)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_child(column)

	_fps_label = _make_label(20)
	_fps_label.name = "Fps"
	column.add_child(_fps_label)

	_details_panel = PanelContainer.new()
	_details_panel.name = "Details"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.03, 0.06, 0.72)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	_details_panel.add_theme_stylebox_override("panel", style)
	_details_label = _make_label(15)
	_details_panel.add_child(_details_label)
	column.add_child(_details_panel)

	paused_label = _make_label(40)
	paused_label.text = "PAUSED"
	paused_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	paused_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	paused_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	paused_label.visible = false
	add_child(paused_label)

	_refresh()


func _process(delta: float) -> void:
	paused_label.visible = get_tree().paused
	_accum += delta
	if _accum >= REFRESH_SECONDS:
		_accum = 0.0
		_refresh()


func details_visible() -> bool:
	return _details_panel.visible


func set_details_visible(on: bool) -> void:
	_details_panel.visible = on


func toggle_details() -> void:
	set_details_visible(not details_visible())


func _refresh() -> void:
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	_fps_label.text = "%d FPS" % roundi(fps)
	if _details_panel.visible:
		_details_label.text = "\n".join(detail_lines())


## The details panel text, one entry per line (public so tests can check it).
func detail_lines() -> PackedStringArray:
	var mb: float = 1024.0 * 1024.0
	var info: Dictionary = Engine.get_version_info()
	var size: Vector2i = get_viewport().get_visible_rect().size
	var lines := PackedStringArray([
		"Lone Traveler %s  ·  Godot %s" % [
			ProjectSettings.get_setting("application/config/version", "?"), info.get("string", "?")],
		"Renderer: %s (%s)" % [
			RenderingServer.get_current_rendering_method(),
			RenderingServer.get_current_rendering_driver_name()],
		"Frame: %.1f ms   Scripts: %.2f ms   Physics: %d Hz" % [
			1000.0 / maxf(Performance.get_monitor(Performance.TIME_FPS), 1.0),
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Engine.physics_ticks_per_second],
		"Draw calls: %d   Objects: %d   Primitives: %d" % [
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)],
		"Video mem: %.0f MB   Textures: %.0f MB   Static: %.0f MB" % [
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / mb,
			Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / mb,
			Performance.get_monitor(Performance.MEMORY_STATIC) / mb],
		"Sim: %s   Warp: %d×" % [
			Units.format_mission_time(SimClock.time), roundi(SimClock.warp())],
		"Viewport: %d × %d" % [size.x, size.y],
	])
	if camera:
		var p: Vector3 = camera.global_position
		lines.append("Camera: (%.3f, %.3f, %.3f) km" % [p.x, p.y, p.z])
	lines.append("F3 debug · Esc pause · , / . time warp")
	return lines


func _make_label(font_size: int) -> Label:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	return l
