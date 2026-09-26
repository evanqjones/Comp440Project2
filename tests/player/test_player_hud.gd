extends GutTest
## In-round HUD (docs/features/player/06-hud/FEATURE.md).

const CART_SCENE := "res://systems/cart/cart.tscn"
const NAMES := ["TimerLabel", "RoundLabel", "ScoreList", "CartCountLabel", "CartValueLabel", "BoostBar", "FeedList", "Minimap"]

var _saved_phase: GameTypes.Phase
var _saved_time: float


func before_each() -> void:
	_saved_phase = RoundManager.phase
	_saved_time = RoundManager.time_left


func after_each() -> void:
	RoundManager.phase = _saved_phase
	RoundManager.time_left = _saved_time


func _cart(id: int, profile_name: String) -> Cart:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	cart.cart_id = id
	cart.profile = load("res://systems/shared/profiles/%s.tres" % profile_name)
	cart.position = Vector3(id * 5.0, 0.0, 0.0)
	add_child_autofree(cart)
	return cart


func _hud(player: Cart) -> PlayerHud:
	var hud := PlayerHud.new()
	hud.cart = player
	add_child_autofree(hud)
	return hud


func _rob(winner: Cart, loser: Cart, moved: int) -> void:
	var items: Array[ItemData] = []
	for n: int in moved:
		items.append(ItemData.new())
	var spilled: Array[ItemData] = []
	loser.cart_robbed.emit(winner, loser, items, spilled)


func test_uses_evans_layout_when_it_exists_else_the_placeholder() -> void:
	var expected := PlayerHud.EVAN_LAYOUT if ResourceLoader.exists(PlayerHud.EVAN_LAYOUT) else PlayerHud.PLACEHOLDER_LAYOUT
	assert_eq(PlayerHud.layout_path(), expected)


func test_placeholder_layout_has_every_contract_name() -> void:
	var layout := (load(PlayerHud.PLACEHOLDER_LAYOUT) as PackedScene).instantiate() as Control
	add_child_autofree(layout)
	for part: String in NAMES:
		assert_not_null(layout.get_node_or_null("%" + part), "placeholder has %" + part)
	assert_true(layout.get_node("%BoostBar") is Range, "%BoostBar is a Range")


func test_timer_counts_down_and_turns_red_at_final_call() -> void:
	var hud := _hud(_cart(0, "player"))
	RoundManager.phase = GameTypes.Phase.RUSH
	RoundManager.time_left = 64.2
	await wait_process_frames(1)
	var timer := hud.layout.get_node("%TimerLabel") as Label
	assert_eq(timer.text, "1:05")
	var normal := timer.get_theme_color("font_color")
	RoundManager.phase = GameTypes.Phase.FINAL_CALL
	RoundManager.time_left = 12.0
	await wait_process_frames(1)
	assert_eq(timer.text, "0:12")
	assert_eq(timer.get_theme_color("font_color"), PlayerHud.FINAL_CALL_COLOR, "red during final call")
	assert_ne(normal, PlayerHud.FINAL_CALL_COLOR)


func test_cart_panel_shows_count_value_and_boost() -> void:
	var player := _cart(0, "player")
	var hud := _hud(player)
	RoundManager.phase = GameTypes.Phase.RUSH
	for n: int in 3:
		var item := ItemData.new()
		item.item_id = 7000 + n
		item.value = 10
		player.try_add_item(item)
	await wait_process_frames(1)
	assert_eq((hud.layout.get_node("%CartCountLabel") as Label).text, "3/24")
	assert_eq((hud.layout.get_node("%CartValueLabel") as Label).text, "$30")
	var bar := hud.layout.get_node("%BoostBar") as Range
	assert_almost_eq(bar.value, bar.max_value, 0.01, "full meter = full bar")


func test_getting_robbed_feed_and_popup() -> void:
	var player := _cart(0, "player")
	var carl := _cart(1, "carl")
	var hud := _hud(player)
	hud.watch(carl)
	_rob(carl, player, 4)
	assert_has(hud.feed_lines(), "Coupon Carl inherited your cart")
	assert_has(hud.popup_texts(), "Knocked out of the sale!")


func test_inheriting_feed_and_popup() -> void:
	var player := _cart(0, "player")
	var bev := _cart(2, "bev")
	var hud := _hud(player)
	hud.watch(bev)
	_rob(player, bev, 7)
	assert_has(hud.feed_lines(), "You inherited Aunt Bev's cart")
	assert_has(hud.popup_texts(), "Inherited! +7 items")


func test_bot_on_bot_goes_to_the_feed_without_a_popup() -> void:
	var player := _cart(0, "player")
	var carl := _cart(1, "carl")
	var rita := _cart(3, "rita")
	var hud := _hud(player)
	hud.watch(carl)
	hud.watch(rita)
	_rob(rita, carl, 5)
	assert_has(hud.feed_lines(), "Rolling Rita inherited Coupon Carl's cart")
	assert_eq(hud.popup_texts().size(), 0, "popups are only about you")


func test_checkout_feed_and_popup() -> void:
	var player := _cart(0, "player")
	var bev := _cart(2, "bev")
	var hud := _hud(player)
	RoundManager.checked_out.emit(bev, 120)
	RoundManager.checked_out.emit(player, 180)
	assert_has(hud.feed_lines(), "Aunt Bev checked out $120")
	assert_has(hud.feed_lines(), "You checked out $180")
	assert_eq(hud.popup_texts(), PackedStringArray(["Checked out $180"]))


func test_feed_keeps_the_newest_five() -> void:
	var player := _cart(0, "player")
	var hud := _hud(player)
	for n: int in 7:
		RoundManager.checked_out.emit(player, 10 + n)
	var lines := hud.feed_lines()
	assert_eq(lines.size(), PlayerHud.FEED_SIZE)
	assert_eq(lines[lines.size() - 1], "You checked out $16", "newest at the bottom")


func test_demo_shows_the_hud_for_the_player() -> void:
	var demo := (load("res://systems/player/demo/demo_round.tscn") as PackedScene).instantiate()
	add_child_autofree(demo)
	var huds := demo.find_children("*", "CanvasLayer", true, false).filter(func(n: Node) -> bool: return n is PlayerHud)
	assert_eq(huds.size(), 1, "one PlayerHud in the demo")
	if huds.size() == 1:
		assert_eq((huds[0] as PlayerHud).cart.cart_id, 0, "following the player's cart")
