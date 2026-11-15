extends SceneTree
## Real game frames of Nina's lullaby, for the sprite viewer: plays the match (Nina sings next to
## Casper, who falls asleep) and saves a 144×96 game-px crop around them every 2 ticks. Needs a
## window (not --headless). Run from the repo root:
##   godot --path super-mms-bros --resolution 1920x1080 -s res://../tools/sprite_viewer/nina_song_capture.gd -- <out_dir>
## then strip them: python3 -I tools/sprite_viewer/nina_song_strip.py <out_dir> <previews_dir>
## Untyped on purpose: the game's classes need the Game autoload, which exists only at runtime.

const TICKS := 150
const EVERY := 2


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0].trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var game = root.get_node("Game")
	game.character_id = "slot_04"
	game.p2_character_id = "slot_08"
	var input_script = load("res://controllers/fighter_input.gd")
	var scripted = load("res://controllers/scripted_controller.gd")
	var m = load("res://match/match.tscn").instantiate()
	m.auto_step = false
	root.add_child(m)
	await physics_frame
	var nina = m.get_fighter(0)
	nina.spawn_at(Vector2(205, 192), 1)
	m.get_fighter(1).spawn_at(Vector2(245, 192), -1)
	var nina_controller = scripted.new()
	nina_controller._inputs.append(input_script.new())
	var special = input_script.new()
	special.special_pressed = true
	special.special_held = true
	special.down_held = true
	nina_controller._inputs.append(special)
	m.set_controller(0, nina_controller)
	m.set_controller(1, scripted.new())
	for t in TICKS:
		await physics_frame
		m.step()
		if t % EVERY == 0:
			await RenderingServer.frame_post_draw
			var img = root.get_texture().get_image()
			# Screen px per game px: the window's stretch times the camera's zoom.
			var px = float(img.get_width()) / 480.0
			var zoom = root.get_canvas_transform().get_scale().x
			var center = (nina.get_global_transform_with_canvas() * Vector2(20, -24)) * px
			var size = Vector2(144, 96) * px * zoom
			var crop = img.get_region(Rect2i(Vector2i(center - size / 2.0), Vector2i(size)))
			crop.resize(144, 96, Image.INTERPOLATE_NEAREST)
			crop.save_png(out + "f%03d.png" % t)
	quit()
