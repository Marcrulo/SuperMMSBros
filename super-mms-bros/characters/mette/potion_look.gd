class_name PotionLook
extends RefCounted
## How Mette's potions look (docs/specs/characters/mette.md#look): the flask, the puddles and the
## reactions, drawn by the game in the pixel style (outlined, three tones). Only draws.

const OUTLINE := Color("#1a1c2c")
const GLASS := Color(0.86, 0.93, 1.0, 0.85)
const CORK := Color("#a0703c")
## Per potion (PotionAbility.Potion order): [dark, main, light].
const COLORS := [
	[Color8(150, 30, 36), Color8(220, 52, 52), Color8(255, 130, 110)],
	[Color8(34, 80, 160), Color8(60, 130, 230), Color8(150, 200, 255)],
	[Color8(50, 120, 40), Color8(90, 190, 70), Color8(170, 235, 130)],
]
const STEAM := Color(0.93, 0.95, 0.97)
const STEAM_SHADE := Color(0.7, 0.74, 0.8)
const FIRE := [Color8(200, 60, 30), Color8(250, 150, 40), Color8(255, 236, 140)]
const FOAM := Color(0.95, 1.0, 0.97)
const FOAM_SHADE := Color(0.72, 0.9, 0.86)


static func color(potion: int, tone: int = 1) -> Color:
	return COLORS[potion][tone]


## A round-bottomed flask, centered on (0, 0): a 7 px bulb with the potion in it, a neck with a
## cork. About 9 × 12.
static func draw_flask(canvas: CanvasItem, potion: int) -> void:
	# Outline: bulb, neck, cork.
	canvas.draw_circle(Vector2(0, 2), 4.5, OUTLINE)
	canvas.draw_rect(Rect2(-2, -5, 4, 5), OUTLINE)
	canvas.draw_rect(Rect2(-2.5, -6.5, 5, 2.5), OUTLINE)
	# Glass, then the potion filling the bulb.
	canvas.draw_circle(Vector2(0, 2), 3.5, GLASS)
	canvas.draw_rect(Rect2(-1, -4, 2, 4), GLASS)
	canvas.draw_circle(Vector2(0, 2.5), 3.0, color(potion, 1))
	canvas.draw_rect(Rect2(-3, 0, 6, 1), color(potion, 1))
	canvas.draw_rect(Rect2(-2, 4, 4, 1), color(potion, 0))
	canvas.draw_rect(Rect2(-2, 0, 2, 1), color(potion, 2))
	# A glint on the glass, and the cork.
	canvas.draw_rect(Rect2(1, 0, 1, 1), Color.WHITE)
	canvas.draw_rect(Rect2(-1.5, -6, 3, 1.5), CORK)


## A puddle `width` wide, its bottom on y 0: a flat blob with a light rim; acid bubbles, ice has a
## glint, glue drips at its edges. `left` (1…0) fades it out at the very end.
static func draw_puddle(canvas: CanvasItem, potion: int, width: float, ticks: int,
		left: float) -> void:
	var fade := clampf(left * 8.0, 0.0, 1.0)
	var half := width / 2.0
	var dark: Color = color(potion, 0)
	var main: Color = color(potion, 1)
	var light: Color = color(potion, 2)
	dark.a = fade
	main.a = fade
	light.a = fade
	# Rounded ends: three rows getting narrower toward the top.
	canvas.draw_rect(Rect2(-half, -2, width, 2), dark)
	canvas.draw_rect(Rect2(-half + 2, -3, width - 4, 1), main)
	canvas.draw_rect(Rect2(-half + 1, -2, width - 2, 1), main)
	canvas.draw_rect(Rect2(-half + 5, -3, width - 12, 1), light)
	match potion:
		PotionAbility.Potion.RED:
			# Bubbles rise from a few spots, each on its own cycle.
			for i in 3:
				var cycle := (ticks + i * 13) % 36
				if cycle < 12:
					var x := -half + 8 + i * (width - 16) / 2.0
					canvas.draw_rect(Rect2(x, -4 - cycle / 4, 2, 2), light)
		PotionAbility.Potion.BLUE:
			var glint := Color(1, 1, 1, fade)
			var x := -half + 6 + float((ticks / 2) % 60) / 60.0 * (width - 12)
			canvas.draw_rect(Rect2(x, -3, 3, 1), glint)
		PotionAbility.Potion.GREEN:
			for side in [-1, 1]:
				var drip := 1 + (ticks / 20 + (1 if side > 0 else 0)) % 2
				canvas.draw_rect(Rect2(side * (half - 3) - 1, -1, 2, drip + 1), main)


## Steam: grey-white puffs rising up a column `size` (bottom center at 0, 0), fading out.
static func draw_steam(canvas: CanvasItem, size: Vector2, age: int, frames: int) -> void:
	var fade := 1.0 - float(age) / frames
	for i in 12:
		var rise := fposmod(float(age) * 3.0 + i * size.y / 12.0, size.y)
		var x := sin(i * 2.1 + age * 0.15) * size.x * 0.3
		var r := 4.0 + rise / size.y * 5.0
		var puff := STEAM
		puff.a = minf(fade * 1.6, 1.0) * (1.0 - rise / size.y * 0.5)
		var shade := STEAM_SHADE
		shade.a = puff.a
		canvas.draw_circle(Vector2(x, -rise + 1), r, shade)
		canvas.draw_circle(Vector2(x, -rise), r - 1.0, puff)


## An explosion: an orange-yellow ball that grows to fill `size` (bottom center at 0, 0) and fades.
static func draw_explosion(canvas: CanvasItem, size: Vector2, age: int, frames: int) -> void:
	var t := clampf(float(age + 1) / frames, 0.0, 1.0)
	var center := Vector2(0, -size.y / 2.0)
	var r := size.y / 2.0 * (0.5 + 0.6 * t)
	for i in 3:
		var c: Color = FIRE[i]
		c.a = 1.0 - t * 0.6
		canvas.draw_circle(center, r * (1.0 - i * 0.3), c)


## The foam pillar: `width` wide, `height` tall from y 0 up, white with a pale blue-green tint and
## bubbly edges.
static func draw_foam(canvas: CanvasItem, width: float, height: float, age: int) -> void:
	if height <= 0.0:
		return
	var half := width / 2.0
	canvas.draw_rect(Rect2(-half - 1, -height - 1, width + 2, height + 1), OUTLINE)
	canvas.draw_rect(Rect2(-half, -height, width, height), FOAM_SHADE)
	canvas.draw_rect(Rect2(-half + 3, -height, width - 6, height), FOAM)
	# Bubbles along the sides and a bumpy top.
	var bumps := int(width / 6.0)
	for i in bumps:
		var x := -half + 3 + i * (width - 6) / maxf(bumps - 1, 1)
		var wobble := 1.0 if (i + age / 8) % 2 == 0 else 0.0
		canvas.draw_circle(Vector2(x, -height + wobble), 3.0, FOAM)
	for i in int(height / 8.0):
		var y := -4.0 - i * 8.0
		canvas.draw_circle(Vector2(-half + 1, y - (i % 2) * 3), 2.0, FOAM_SHADE)
		canvas.draw_circle(Vector2(half - 1, y - ((i + 1) % 2) * 3), 2.0, FOAM_SHADE)


## The smash: a splash of the potion with glass shards and droplets flying out from (0, 0), mostly
## forward (+x), `age` 1…`ticks`.
static func draw_burst(canvas: CanvasItem, potion: int, age: int, ticks: int) -> void:
	var t := float(age) / ticks
	var spread := 5.0 + 18.0 * t
	var fade := 1.0 - t * 0.6
	# The splash: a blob of the potion that grows and thins out, a white flash at first.
	var blob: Color = color(potion, 1)
	blob.a = 0.85 * (1.0 - t)
	canvas.draw_circle(Vector2(2, 0), 4.0 + 7.0 * t, blob)
	if age <= 2:
		canvas.draw_circle(Vector2.ZERO, 6.0, Color(1, 1, 1, 0.9))
	for i in 10:
		var a := -1.4 + i * 0.31
		var d := Vector2(cos(a), sin(a)) * spread * (0.75 + (i % 3) * 0.15)
		d.y += 12.0 * t * t  # Droplets fall.
		var drop: Color = color(potion, 1 if i % 2 == 0 else 2)
		drop.a = fade
		var edge := OUTLINE
		edge.a = fade
		canvas.draw_rect(Rect2(d - Vector2(2, 2), Vector2(4, 4)), edge)
		canvas.draw_rect(Rect2(d - Vector2(1, 1), Vector2(3, 3)), drop)
	for i in 5:
		var a := -1.0 + i * 0.5
		var d := Vector2(cos(a), sin(a)) * spread * 0.9
		canvas.draw_rect(Rect2(d, Vector2(2, 1)), Color(0.9, 0.97, 1.0, fade))
