extends GutTest
## Round receipt (docs/features/player/08-receipt/FEATURE.md).

const CART_SCENE := "res://systems/cart/cart.tscn"
const NAMES := ["RoundTitle", "ReceiptLines", "StampRow", "Standings"]


func _cart(id: int, profile_name: String) -> Cart:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	cart.cart_id = id
	cart.profile = load("res://systems/shared/profiles/%s.tres" % profile_name)
	cart.position = Vector3(id * 5.0, 0.0, 0.0)
	add_child_autofree(cart)
	RoundManager.register_cart(cart)
	return cart


func _setup() -> RoundReceipt:
	var player := _cart(0, "player")
	_cart(1, "carl")
	_cart(2, "bev")
	_cart(3, "rita")
	var receipt := RoundReceipt.new()
	receipt.cart = player
	add_child_autofree(receipt)
	return receipt


func _results(banked: Dictionary, winners: Array[int], stamps: Dictionary) -> RoundResults:
	var results := RoundResults.new()
	results.round_number = 1
	for id: int in banked:
		results.banked[id] = banked[id]
	results.winner_ids = winners
	for id: int in stamps:
		results.stamps[id] = stamps[id]
	return results


func _text(receipt: RoundReceipt, part: String) -> String:
	return (receipt.layout.get_node("%" + part) as Label).text


func test_uses_evans_layout_when_it_exists_else_the_placeholder() -> void:
	var expected: String = RoundReceipt.EVAN_LAYOUT if ResourceLoader.exists(RoundReceipt.EVAN_LAYOUT) else RoundReceipt.PLACEHOLDER_LAYOUT
	assert_eq(RoundReceipt.layout_path(), expected)
	var layout := (load(RoundReceipt.PLACEHOLDER_LAYOUT) as PackedScene).instantiate() as Control
	add_child_autofree(layout)
	for part: String in NAMES:
		assert_not_null(layout.get_node_or_null("%" + part), "placeholder has %" + part)


func test_hidden_until_the_round_ends_and_again_when_one_starts() -> void:
	var receipt := _setup()
	assert_false(receipt.is_showing(), "hidden during play")
	RoundManager.round_ended.emit(_results({0: 180, 1: 480, 2: 120, 3: 0}, [1] as Array[int], {1: 1}))
	assert_true(receipt.is_showing(), "shown at round end")
	RoundManager.round_started.emit(2)
	assert_false(receipt.is_showing(), "hidden when the next round starts")


func test_receipt_lists_everyone_most_banked_first() -> void:
	var receipt := _setup()
	RoundManager.round_ended.emit(_results({0: 180, 1: 480, 2: 120, 3: 0}, [1] as Array[int], {1: 1}))
	var title := _text(receipt, "RoundTitle")
	assert_string_contains(title, PlayerStrings.STORE_NAME.to_upper())
	assert_string_contains(title, "Round 1")
	var lines := _text(receipt, "ReceiptLines").split("\n")
	assert_eq(lines.size(), 4)
	assert_string_starts_with(lines[0], "Coupon Carl")
	assert_string_ends_with(lines[0], "$480")
	assert_string_starts_with(lines[1], "You")
	assert_string_ends_with(lines[3], "$0")


func test_stamp_row_for_a_winner_a_tie_and_nobody() -> void:
	var receipt := _setup()
	RoundManager.round_ended.emit(_results({0: 180, 1: 480}, [1] as Array[int], {1: 1}))
	assert_eq(_text(receipt, "StampRow"), "★ Stamp: Coupon Carl")
	RoundManager.round_ended.emit(_results({0: 200, 2: 200}, [0, 2] as Array[int], {0: 1, 2: 1}))
	assert_eq(_text(receipt, "StampRow"), "★ Stamps: You, Aunt Bev")
	RoundManager.round_ended.emit(_results({}, [] as Array[int], {}))
	assert_eq(_text(receipt, "StampRow"), "No stamp today")


func test_standings_show_stamps_so_far() -> void:
	var receipt := _setup()
	RoundManager.round_ended.emit(_results({0: 180, 1: 480}, [1] as Array[int], {1: 1}))
	var standings := _text(receipt, "Standings")
	assert_string_contains(standings, "Coupon Carl 1")
	assert_string_contains(standings, "You 0")


func test_demo_round_winner_rule() -> void:
	assert_eq(DemoRoundManager.round_winners({0: 180, 1: 480, 2: 120}), [1] as Array[int], "highest banked")
	assert_eq(DemoRoundManager.round_winners({0: 200, 1: 50, 2: 200}), [0, 2] as Array[int], "ties share the stamp")
	assert_eq(DemoRoundManager.round_winners({0: 0, 1: 0}), [] as Array[int], "nobody banked, no stamp")


func test_demo_shows_the_receipt_when_the_store_closes() -> void:
	var demo := (load("res://systems/player/demo/demo_round.tscn") as PackedScene).instantiate()
	add_child_autofree(demo)
	var receipts := demo.find_children("*", "CanvasLayer", true, false).filter(func(n: Node) -> bool: return n is RoundReceipt)
	assert_eq(receipts.size(), 1, "one RoundReceipt in the demo")
	if receipts.is_empty():
		return
	var receipt := receipts[0] as RoundReceipt
	demo._physics_process(DemoRoundClock.COUNTDOWN + 0.1)
	demo._physics_process(DemoRoundClock.ROUND + 1.0)
	assert_true(receipt.is_showing(), "the receipt shows at close")
	assert_eq(receipt.footer, "Press R to play again")
