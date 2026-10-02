extends GutTest
## Receipt for best of 3 (docs/features/store/05-best-of-three/FEATURE.md): a countdown to the next
## round, the MATCH OVER receipt with SHOP AGAIN, and Grandma's card reissued when you win.

const CART_SCENE := "res://systems/cart/cart.tscn"

var _saved_phase: GameTypes.Phase


func before_each() -> void:
	_saved_phase = RoundManager.phase
	RoundManager.phase = GameTypes.Phase.RESULTS
	RoundManager._match_running = false


func after_each() -> void:
	RoundManager.phase = GameTypes.Phase.IDLE
	RoundManager.round_number = 0
	RoundManager._match_running = false
	RoundManager._phase_time_left = 0.0
	RoundManager.phase = _saved_phase


func _receipt() -> RoundReceipt:
	var player := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	player.cart_id = 0
	player.profile = load("res://systems/shared/profiles/player.tres")
	add_child_autofree(player)
	var receipt := RoundReceipt.new()
	receipt.cart = player
	add_child_autofree(receipt)
	return receipt


func _results(round_number: int, over: bool, match_winners: Array[int]) -> RoundResults:
	var results := RoundResults.new()
	results.round_number = round_number
	results.banked = {0: 60, 1: 120}
	results.winner_ids = [1] as Array[int]
	results.stamps = {0: 1, 1: 2}
	results.match_banked = {0: 300, 1: 410}
	results.is_match_over = over
	results.match_winner_ids = match_winners
	return results


func test_between_rounds_counts_down_and_hides_when_the_next_round_counts_down() -> void:
	var receipt := _receipt()
	RoundManager.round_ended.emit(_results(1, false, []))
	assert_true(receipt.is_showing())
	assert_eq(receipt.footer_text(), "Round 2 starts in 10")
	simulate(receipt, 1, 3.0)
	assert_eq(receipt.footer_text(), "Round 2 starts in 7")
	assert_false(receipt.shop_again_visible(), "no SHOP AGAIN between rounds")
	RoundManager.phase_changed.emit(GameTypes.Phase.COUNTDOWN)
	assert_false(receipt.is_showing(), "hidden so the 3-2-1 shows")
	assert_eq(receipt.footer_text(), "")


func test_match_over_receipt_with_shop_again() -> void:
	var receipt := _receipt()
	RoundManager.round_ended.emit(_results(3, true, [1] as Array[int]))
	var title := (receipt.layout.get_node("%RoundTitle") as Label).text
	assert_string_contains(title, "Match over")
	assert_string_contains((receipt.layout.get_node("%StampRow") as Label).text, "Winner: Shopper 1")
	assert_string_contains((receipt.layout.get_node("%ReceiptLines") as Label).text, "$410", "match totals")
	assert_true(receipt.shop_again_visible())
	assert_false(receipt.reissued_card_visible(), "Carl won, not you")
	RoundManager.phase = GameTypes.Phase.MATCH_OVER
	receipt.shop_again_button().pressed.emit()
	assert_eq(RoundManager.phase, GameTypes.Phase.COUNTDOWN, "SHOP AGAIN starts a new match")
	assert_eq(RoundManager.round_number, 1)
	assert_false(receipt.is_showing())
	assert_false(receipt.shop_again_visible())


func test_grandmas_card_is_reissued_when_you_win() -> void:
	var receipt := _receipt()
	RoundManager.round_ended.emit(_results(3, true, [0] as Array[int]))
	assert_true(receipt.reissued_card_visible())
	assert_string_contains((receipt.layout.get_node("%StampRow") as Label).text, "Winner: You")
