class_name InkFont
## The game's text font, Ink Yugo (docs/specs/controls-and-display.md#text). It isn't in git
## (personal-use license), so when the file is missing all text keeps the pixel font.
## The Game autoload calls `apply_to()` on every Label as it enters the scene tree.

const PATH := "res://assets/fonts/ink_yugo.otf"
## The select screens' titles.
const TITLE_SIZE := 24
## The brush letters are smaller than the pixel font's at the same size.
const SCALE := 1.25

static var _font: Font = null


## True when the font file is on this machine.
static func present() -> bool:
	return ResourceLoader.exists(PATH)


## True when every character of `text` is one the demo font really draws: letters, spaces, commas
## and full stops. Its digits and other signs are all a "personal use only" stamp.
static func can_draw(text: String) -> bool:
	for c in text:
		if not (c == " " or c == "," or c == "." or (c >= "A" and c <= "Z") or (c >= "a" and c <= "z")):
			return false
	return true


## Puts `label` (if `can_draw` its text) in the ink font, in capitals, its size × SCALE. A top-aligned label moves up by half the extra
## height, so it stays centred on the line it had in the pixel font.
static func apply_to(label: Label) -> void:
	if not present() or not can_draw(label.text):
		return
	var old_size := label.get_theme_font_size("font_size")
	var new_size := roundi(old_size * SCALE)
	label.add_theme_font_override("font", _ink())
	label.add_theme_font_size_override("font_size", new_size)
	# The brush font looks best in capitals.
	label.uppercase = true
	if label.vertical_alignment == VERTICAL_ALIGNMENT_TOP:
		label.position.y -= floorf((new_size - old_size) / 2.0)


## Sets a select screen's `title` in the ink font at TITLE_SIZE with its top at `top`.
static func apply_title(title: Label, top: float) -> void:
	if not present():
		return
	title.add_theme_font_override("font", _ink())
	title.add_theme_font_size_override("font_size", TITLE_SIZE)
	title.position.y = top


static func _ink() -> Font:
	if _font == null:
		_font = load(PATH) as Font
	return _font
