extends GutTest
## HUD polish (docs/features/player/10-hud-polish/FEATURE.md): countdown, hints, checkout arrow,
## pickup pops, checkout confetti and feed pills.

const CART_SCENE := "res://systems/cart/cart.tscn"

var _saved_phase: GameTypes.Phase
var _saved_time: float


func before_each() -> void:
	_saved_phase = RoundManager.phase
	_saved_time = RoundManager.time_left
	RoundManager.phase = GameTypes.Phase.IDLE


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
	simulate(hud, 1, 0.0) # sees IDLE first, so the next phase counts as a change
	return hud


func _item(id: int, value: int, category: GameTypes.Category = GameTypes.Category.PRODUCE) -> ItemData:
	var item := ItemData.new()
	item.item_id = id
	item.value = value
	item.category = category
	return item


func _fill(cart: Cart, count: int) -> void:
	for n: int in count:
		cart.try_add_item(_item(9000 + cart.cart_id * 100 + n, 5))


func test_countdown_counts_three_two_one_then_go_then_hides() -> void:
	var hud := _hud(_cart(0, "player"))
	RoundManager.phase = GameTypes.Phase.COUNTDOWN
	simulate(hud, 1, 0.1)
	assert_eq(hud.countdown_text(), "3")
	simulate(hud, 1, 1.0)
	assert_eq(hud.countdown_text(), "2")
	simulate(hud, 1, 1.0)
	assert_eq(hud.countdown_text(), "1")
	RoundManager.phase = GameTypes.Phase.RUSH
	simulate(hud, 1, 0.1)
	assert_eq(hud.countdown_text(), "GO!")
	simulate(hud, 1, 1.0)
	assert_eq(hud.countdown_text(), "", "GO! clears after a moment")


func test_hints_for_doors_final_call_and_a_full_cart() -> void:
	var player := _cart(0, "player")
	var hud := _hud(player)
	RoundManager.phase = GameTypes.Phase.RUSH
	simulate(hud, 1, 0.1)
	assert_eq(hud.hint_text(), PlayerHud.HINT_DOORS)
	simulate(hud, 1, 3.0)
	assert_eq(hud.hint_text(), "", "the doors hint times out")
	_fill(player, player.tuning.item_cap)
	simulate(hud, 1, 0.1)
	assert_eq(hud.hint_text(), PlayerHud.HINT_FULL)
	RoundManager.phase = GameTypes.Phase.FINAL_CALL
	simulate(hud, 1, 0.1)
	assert_eq(hud.hint_text(), PlayerHud.HINT_FINAL_CALL, "phase hints win for a moment")
	simulate(hud, 1, 3.0)
	assert_eq(hud.hint_text(), PlayerHud.HINT_FULL, "then the full-cart hint comes back")
	player.take_all_items()
	simulate(hud, 1, 0.1)
	assert_eq(hud.hint_text(), "", "cleared once the cart isn't full")


func test_arrow_shows_when_full_or_at_final_call_with_items() -> void:
	var player := _cart(0, "player")
	var hud := _hud(player)
	RoundManager.phase = GameTypes.Phase.RUSH
	simulate(hud, 1, 0.1)
	assert_false(hud.arrow_visible(), "empty cart: no arrow")
	_fill(player, 1)
	simulate(hud, 1, 0.1)
	assert_false(hud.arrow_visible(), "one item during RUSH: no arrow")
	_fill(player, player.tuning.item_cap)
	simulate(hud, 1, 0.1)
	assert_true(hud.arrow_visible(), "full cart: arrow")
	player.take_all_items()
	RoundManager.phase = GameTypes.Phase.FINAL_CALL
	simulate(hud, 1, 0.1)
	assert_false(hud.arrow_visible(), "final call, empty cart: no arrow")
	_fill(player, 1)
	simulate(hud, 1, 0.1)
	assert_true(hud.arrow_visible(), "final call with an item: arrow")


func test_heading_angle_is_zero_ahead_and_positive_to_the_right() -> void:
	var looking_north := Basis() # forward = −Z, right = +X
	assert_almost_eq(PlayerHud.heading_angle(looking_north, Vector3.ZERO, Vector3(0, 0, -5)), 0.0, 0.001)
	assert_almost_eq(PlayerHud.heading_angle(looking_north, Vector3.ZERO, Vector3(5, 3, 0)), PI / 2.0, 0.001, "height is ignored")
	assert_almost_eq(PlayerHud.heading_angle(looking_north, Vector3.ZERO, Vector3(-5, 0, 0)), -PI / 2.0, 0.001)
	var looking_west := Basis(Vector3.UP, PI / 2.0) # forward = −X, right = −Z
	assert_almost_eq(PlayerHud.heading_angle(looking_west, Vector3.ZERO, Vector3(0, 0, -5)), PI / 2.0, 0.001)
	var tilted := Basis(Vector3.RIGHT, -0.4) # a chase camera looks down a little
	assert_almost_eq(PlayerHud.heading_angle(tilted, Vector3(0, 0, 10), Vector3(0, 0, 0)), 0.0, 0.001)


func test_pickup_pop_only_for_the_players_own_pickups() -> void:
	var player := _cart(0, "player")
	var carl := _cart(1, "carl")
	var hud := _hud(player)
	RoundManager.phase = GameTypes.Phase.RUSH
	var snack := _item(9500, 15, GameTypes.Category.SNACKS)
	player.try_add_item(snack)
	carl.try_add_item(_item(9501, 40, GameTypes.Category.ELECTRONICS))
	assert_eq(hud.pop_texts(), PackedStringArray(["+$15"]))
	var pop: Label3D = hud.pop_nodes()[0]
	assert_eq(pop.modulate, CartItemStack.color_for(snack), "in the aisle color")


func test_confetti_only_on_the_players_checkout() -> void:
	var player := _cart(0, "player")
	var bev := _cart(2, "bev")
	var hud := _hud(player)
	RoundManager.checked_out.emit(bev, 100)
	assert_eq(hud.confetti_count(), 0, "not for a bot's checkout")
	RoundManager.checked_out.emit(player, 50)
	assert_eq(hud.confetti_count(), 1)
	assert_has(hud.popup_texts(), "Checked out $50", "the popup stays")


func test_feed_lines_are_pills_that_fit_left_of_the_cart_panel() -> void:
	var player := _cart(0, "player")
	var carl := _cart(1, "carl")
	var rita := _cart(3, "rita")
	var hud := _hud(player)
	hud.watch(carl)
	var items: Array[ItemData] = [_item(9600, 5)]
	var spilled: Array[ItemData] = []
	carl.cart_robbed.emit(rita, carl, items, spilled)
	assert_has(hud.feed_lines(), "Rolling Rita inherited Coupon Carl's cart", "feed_lines() still reads the text")
	var feed := hud.layout.get_node("%FeedList") as Container
	assert_gt(feed.get_child_count(), 0)
	for line: Node in feed.get_children():
		assert_true(line is PanelContainer, "each line is a pill")
		assert_lte((line as Control).get_combined_minimum_size().x, PlayerHud.FEED_MAX_WIDTH, "fits left of the cart panel")
