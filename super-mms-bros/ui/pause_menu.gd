class_name PauseMenu
extends CanvasLayer
## The pause menu (docs/specs/match-and-stage.md#pause): `pause` (Esc) stops the scene tree and
## shows CONTINUE / QUIT over the dimmed game, with small music / sound effects mute icon buttons
## for the mouse. It runs with PROCESS_MODE_ALWAYS (set
## in the scene), so it hears keys while everything else is paused. It changes no gameplay state.

enum Choice { CONTINUE, QUIT }

const HIGHLIGHT := Color("#b13e53")
const TEXT := Color("#f4f4f4")
const DIM_TEXT := Color("#94b0c2")
## The mute buttons: on, under the mouse, held down, and switched off.
const BUTTON_ON := Color("#333c57")
const BUTTON_HOVER := Color("#44506e")
const BUTTON_DOWN := Color("#1a1c2c")
const BUTTON_OFF := Color("#1a1c2c")
## The mute buttons' icons (made by tools/gen_ui_icons.py).
const MUSIC_ICON := preload("res://assets/ui/icon_music.png")
const MUSIC_OFF_ICON := preload("res://assets/ui/icon_music_off.png")
const SFX_ICON := preload("res://assets/ui/icon_sfx.png")
const SFX_OFF_ICON := preload("res://assets/ui/icon_sfx_off.png")

## The highlighted choice (a Choice).
var selected: int = Choice.CONTINUE

@onready var _labels: Array[Label] = [$Continue as Label, $Quit as Label]
@onready var _bar := $Bar as ColorRect
@onready var _music := $MusicButton as Button
@onready var _sfx := $SfxButton as Button


func _ready() -> void:
	hide()
	for button in [_music, _sfx]:
		_style(button)
	_music.pressed.connect(_toggle_music)
	_sfx.pressed.connect(_toggle_sfx)
	_show_mute_buttons()


func music_button() -> Button:
	return _music


func sfx_button() -> Button:
	return _sfx


func is_open() -> bool:
	return visible


func get_choice_labels() -> Array[Label]:
	return _labels


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		if event.is_action_pressed("pause"):
			get_viewport().set_input_as_handled()
			open()
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		resume()
	elif event.is_action_pressed("ui_up"):
		_select(selected - 1)
	elif event.is_action_pressed("ui_down"):
		_select(selected + 1)
	elif event.is_action_pressed("ui_accept"):
		_choose()
	else:
		return
	get_viewport().set_input_as_handled()


## Pauses the game and shows the menu, CONTINUE highlighted.
func open() -> void:
	get_tree().paused = true
	selected = Choice.CONTINUE
	_show_mute_buttons()
	_show_selection()
	show()


## Hides the menu and lets the game run again.
func resume() -> void:
	hide()
	get_tree().paused = false


## Ends the match: back to the character select (unpaused, so that screen runs).
func quit() -> void:
	resume()
	Game.go_to(Game.CHARACTER_SELECT_PATH)


func _choose() -> void:
	Game.play_sfx("menu_confirm")
	if selected == Choice.CONTINUE:
		resume()
	else:
		quit()


func _toggle_music() -> void:
	Game.music_muted = not Game.music_muted
	Game.save_settings()
	Game.play_sfx("menu_confirm")
	_show_mute_buttons()


func _toggle_sfx() -> void:
	Game.sfx_muted = not Game.sfx_muted
	Game.save_settings()
	Game.play_sfx("menu_confirm")  # After unmuting, so turning sound on is heard.
	_show_mute_buttons()


## Each button's icon and look from the current mute state.
func _show_mute_buttons() -> void:
	_show_mute(_music, MUSIC_OFF_ICON if Game.music_muted else MUSIC_ICON, Game.music_muted)
	_show_mute(_sfx, SFX_OFF_ICON if Game.sfx_muted else SFX_ICON, Game.sfx_muted)


func _show_mute(button: Button, icon: Texture2D, muted: bool) -> void:
	button.icon = icon
	button.add_theme_stylebox_override("normal", _box(BUTTON_OFF if muted else BUTTON_ON))


## Flat boxes for each state of a small button (no focus box: it never takes focus).
func _style(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("hover", _box(BUTTON_HOVER))
	button.add_theme_stylebox_override("pressed", _box(BUTTON_DOWN))
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = BUTTON_HOVER
	box.set_border_width_all(1)
	return box


func _select(index: int) -> void:
	var clamped := clampi(index, 0, _labels.size() - 1)
	if clamped == selected:
		return
	selected = clamped
	Game.play_sfx("menu_move")
	_show_selection()


## The highlighted choice in white on the red bar, the other in grey.
func _show_selection() -> void:
	for i in _labels.size():
		_labels[i].add_theme_color_override("font_color", TEXT if i == selected else DIM_TEXT)
	var label := _labels[selected]
	_bar.position = Vector2(_bar.position.x, label.position.y)
	_bar.size = Vector2(_bar.size.x, label.size.y)
