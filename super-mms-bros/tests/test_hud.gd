extends GutTest
## The HUD's player cards (docs/specs/match-and-stage.md#hud).

const MATCH_SCENE := preload("res://match/match.tscn")

var _match: Match
var _hud: Hud


func before_each() -> void:
	_match = MATCH_SCENE.instantiate()
	_match.auto_step = false
	add_child_autofree(_match)
	_hud = _match.get_node("HUD") as Hud


func test_percent_text_is_a_whole_number() -> void:
	assert_eq(PlayerCard.percent_text(0.0), "0%")
	assert_eq(PlayerCard.percent_text(42.7), "42%")
	assert_eq(PlayerCard.percent_text(999.0), "999%")


func test_percent_color_goes_from_white_to_red() -> void:
	assert_eq(PlayerCard.percent_color(0.0), PlayerCard.PERCENT_LOW)
	assert_true(PlayerCard.percent_color(150.0).is_equal_approx(PlayerCard.PERCENT_HIGH), "red at 150")
	assert_true(PlayerCard.percent_color(400.0).is_equal_approx(PlayerCard.PERCENT_HIGH), "stays red")
	assert_eq(PlayerCard.percent_color(75.0), PlayerCard.PERCENT_LOW.lerp(PlayerCard.PERCENT_HIGH, 0.5))
	assert_eq(PlayerCard.PERCENT_LOW, Color("#f4f4f4"))
	assert_eq(PlayerCard.PERCENT_HIGH, Color("#f0524f"))


func test_hud_is_a_canvas_layer_with_a_card_per_fighter() -> void:
	assert_true(_hud is CanvasLayer, "camera zoom doesn't affect it")
	assert_eq(_hud.cards.size(), 2)
	assert_eq(_hud.cards[0].get_name_text(), "P1")
	assert_eq(_hud.cards[1].get_name_text(), "P2")
	assert_eq(_hud.cards[0].player_color, Color("#b13e53"))
	assert_eq(_hud.cards[1].player_color, Color("#3b5dc9"))


func test_cards_sit_at_the_bottom_p1_left_of_center() -> void:
	var p1 := _hud.cards[0].get_rect()
	var p2 := _hud.cards[1].get_rect()
	assert_eq(p1.size, Vector2(96, 30))
	assert_eq(p1.end.y, 264.0, "6 px from the bottom")
	assert_eq(p2.end.y, 264.0)
	assert_eq(p1.end.x, 232.0, "left of center, 16 px gap")
	assert_eq(p2.position.x, 248.0)


func test_card_shows_the_fighters_percent() -> void:
	_match.get_fighter(1).percent = 37.4
	_hud.cards[1].refresh()
	assert_eq(_hud.cards[1].get_percent_text(), "37%")
	assert_eq(_hud.cards[0].get_percent_text(), "0%")


func test_portrait_is_the_head_in_the_player_colors() -> void:
	var portrait := _hud.cards[1].get_portrait()
	assert_eq(portrait.region, Rect2(14, 16, 20, 20))
	assert_eq(portrait.atlas, FighterVisuals.textures_for(1)["idle"], "P2's recolored strip")


func test_card_shows_a_stock_icon_per_stock() -> void:
	var card: PlayerCard = _hud.cards[0]
	assert_eq(card.get_stock_count(), 3)
	_match.get_fighter(0).stocks = 1
	card.refresh()
	assert_eq(card.get_stock_count(), 1)
	assert_eq(card.get_stock_icon(), FighterVisuals.textures_for(0)["stock_icon"])


func test_a_hit_bumps_the_percent() -> void:
	var card: PlayerCard = _hud.cards[1]
	assert_eq(card.bump_offset(), 0.0)
	card.bump()
	assert_eq(card.bump_offset(), -2.0)
	for i in PlayerCard.BUMP_FRAMES:
		card.advance_bump()
	assert_eq(card.bump_offset(), 0.0)


func test_match_signals_a_landed_hit() -> void:
	watch_signals(_match)
	var p1 := _match.get_fighter(0)
	var p2 := _match.get_fighter(1)
	p1.spawn_at(Vector2(230, 192), 1)
	p2.spawn_at(Vector2(250, 192), -1)
	var attack := FighterInput.new()
	attack.attack_pressed = true
	_match.set_controller(0, ScriptedController.new([FighterInput.new(), attack]))
	_match.set_controller(1, ScriptedController.new([]))
	await wait_physics_frames(1)
	for i in 6:
		_match.step()
	assert_signal_emitted_with_parameters(_match, "fighter_hit", [1])
