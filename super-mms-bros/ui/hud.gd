class_name Hud
extends CanvasLayer
## The on-screen display (docs/specs/match-and-stage.md#hud). A CanvasLayer draws in screen
## pixels, so the camera's zoom doesn't move or scale it. Only reads the match; never changes it.

const CARD_SCENE := preload("res://ui/player_card.tscn")
const PLAYER_COLORS: Array[Color] = [Color("#b13e53"), Color("#3b5dc9")]
const SCREEN := Vector2(480, 270)
const CARD_SIZE := Vector2(96, 30)
const CARD_GAP := 16.0
const BOTTOM_MARGIN := 6.0

## One card per fighter, in player order.
var cards: Array[PlayerCard] = []


## Makes a card for each fighter and listens for hits. Called by the Match once its fighters exist.
func setup(match_node: Match, fighters: Array[Fighter]) -> void:
	for card in cards:
		card.queue_free()
	cards.clear()
	var y := SCREEN.y - BOTTOM_MARGIN - CARD_SIZE.y
	for fighter in fighters:
		var card := CARD_SCENE.instantiate() as PlayerCard
		add_child(card)
		var i := fighter.player_index
		var left := SCREEN.x / 2.0 - CARD_GAP / 2.0 - CARD_SIZE.x if i == 0 else SCREEN.x / 2.0 + CARD_GAP / 2.0
		card.position = Vector2(left, y)
		card.setup(fighter, "P%d" % (i + 1), PLAYER_COLORS[mini(i, PLAYER_COLORS.size() - 1)])
		cards.append(card)
	if not match_node.fighter_hit.is_connected(_on_fighter_hit):
		match_node.fighter_hit.connect(_on_fighter_hit)


func _on_fighter_hit(player_index: int) -> void:
	cards[player_index].bump()
