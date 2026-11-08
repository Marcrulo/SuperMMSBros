class_name TitleFont
## The select screens' title font, Ink Yugo (docs/specs/controls-and-display.md#text). It isn't in
## git (personal-use license), so a screen keeps its pixel-font title when the file is missing.

const PATH := "res://assets/fonts/ink_yugo.otf"
const SIZE := 24


## Sets `title` in the brush font with its top at `top`, if the font is on this machine.
static func apply(title: Label, top: float) -> void:
	if not ResourceLoader.exists(PATH):
		return
	title.add_theme_font_override("font", load(PATH) as Font)
	title.add_theme_font_size_override("font_size", SIZE)
	title.position.y = top
