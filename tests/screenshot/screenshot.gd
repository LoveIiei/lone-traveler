extends Node
## Screenshot runner. Loads main.tscn, applies each shot's setup, waits for
## the frame to settle, and saves a PNG to tests/screenshot/out/<name>.png.
## Needs a real window (not --headless). Run: tools/screenshot.sh
## M1 adds camera spots (Earth orbit, halfway, Moon close-up) to SHOTS.

const OUT_DIR: String = "res://tests/screenshot/out"
const SETTLE_FRAMES: int = 90  # > 1 s, so the FPS monitor has a full sample

## name -> setup method on this script, called with the main scene.
const SHOTS: Dictionary[String, String] = {
	"m0_empty_space_debug": "_setup_debug_on",
}


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("screenshot: needs a window; run without --headless")
		get_tree().quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var failures: int = 0
	for shot: String in SHOTS:
		var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
		add_child(main)
		call(SHOTS[shot], main)
		for i: int in SETTLE_FRAMES:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img: Image = get_viewport().get_texture().get_image()
		var path: String = ProjectSettings.globalize_path("%s/%s.png" % [OUT_DIR, shot])
		var err: Error = img.save_png(path)
		if err == OK:
			print("screenshot: saved %s (%dx%d)" % [path, img.get_width(), img.get_height()])
		else:
			push_error("screenshot: failed to save %s (%s)" % [path, error_string(err)])
			failures += 1
		main.queue_free()
		await get_tree().process_frame
	get_tree().quit(1 if failures > 0 else 0)


func _setup_debug_on(main: Node) -> void:
	(main.get_node("DebugOverlay") as DebugOverlay).set_details_visible(true)
