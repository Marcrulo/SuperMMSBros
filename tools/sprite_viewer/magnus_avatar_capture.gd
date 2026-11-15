extends SceneTree
## Real game frames of Magnus's Avatar State, for the sprite viewer: lights his four elements,
## then saves a 112×80 game-px crop around him every tick of the rise and the first second of the
## flight (he hovers in place). Needs a window (not --headless). Run from the repo root:
##   godot --path super-mms-bros --resolution 1920x1080 -s res://../tools/sprite_viewer/magnus_avatar_capture.gd -- <out_dir>
## then: python3 -I tools/sprite_viewer/magnus_previews.py super-mms-bros <previews_dir> <out_dir>
## Untyped on purpose: the game's classes need the Game autoload, which exists only at runtime.

const TICKS := 120


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0].trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var game = root.get_node("Game")
	game.character_id = "slot_14"
	game.p2_character_id = "slot_01"
	var scripted = load("res://controllers/scripted_controller.gd")
	var m = load("res://match/match.tscn").instantiate()
	m.auto_step = false
	root.add_child(m)
	await physics_frame
	var magnus = m.get_fighter(0)
	magnus.spawn_at(Vector2(240, 150), 1)
	m.get_fighter(1).spawn_at(Vector2(400, 192), -1)
	m.set_controller(0, scripted.new())
	m.set_controller(1, scripted.new())
	var avatar = magnus.abilities[0]
	for ability in magnus.abilities:
		if ability.has_method("in_avatar_state"):
			avatar = ability
	for element in 4:
		avatar.light(element)
	for t in TICKS + 1:
		await physics_frame
		m.step()
		if t == 0:
			continue
		await RenderingServer.frame_post_draw
		var img = root.get_texture().get_image()
		# Screen px per game px: the window's stretch times the camera's zoom.
		var px = float(img.get_width()) / 480.0
		var zoom = root.get_canvas_transform().get_scale().x
		var center = (magnus.get_global_transform_with_canvas() * Vector2(0, -18)) * px
		var size = Vector2(112, 80) * px * zoom
		var crop = img.get_region(Rect2i(Vector2i(center - size / 2.0), Vector2i(size)))
		crop.resize(112, 80, Image.INTERPOLATE_NEAREST)
		crop.save_png(out + "f%03d.png" % t)
	quit()
