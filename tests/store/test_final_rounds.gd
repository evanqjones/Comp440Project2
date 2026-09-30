extends GutTest
## Final Store match accounting (docs/features/store/04-final-rounds/01-spec.md §3).

class AccountingCart extends Cart:
	func _ready() -> void:
		pass


var _saved_phase: GameTypes.Phase
var _saved_round_number: int
var _saved_match_running: bool
var _saved_physics_processing: bool


func before_each() -> void:
	_saved_phase = RoundManager.phase
	_saved_round_number = RoundManager.round_number
	_saved_match_running = RoundManager._match_running
	_saved_physics_processing = RoundManager.is_physics_processing()
	RoundManager.set_physics_process(false)
	RoundManager.phase = GameTypes.Phase.IDLE
	RoundManager.round_number = 0
	RoundManager._match_running = false
	RoundManager.start_match()


func after_each() -> void:
	RoundManager._match_running = false
	RoundManager.phase = _saved_phase
	RoundManager.round_number = _saved_round_number
	RoundManager._match_running = _saved_match_running
	RoundManager.set_physics_process(_saved_physics_processing)


func test_positive_round_winner_updates_stamps_match_bank_and_getters() -> void:
	var player := _add_cart(0)
	var carl := _add_cart(1)
	RoundManager._round_banked = {player.cart_id: 45, carl.cart_id: 30}

	var results := RoundManager._build_round_results()

	assert_eq(results.banked, {0: 45, 1: 30})
	assert_eq(results.winner_ids, [0])
	assert_eq(results.stamps, {0: 1, 1: 0})
	assert_eq(results.match_banked, {0: 45, 1: 30})
	assert_eq(RoundManager.get_stamps(0), 1)
	assert_eq(RoundManager.get_stamps(1), 0)
	assert_eq(RoundManager.get_match_banked(0), 45)
	assert_eq(RoundManager.get_match_banked(1), 30)
	results.stamps[0] = 99
	results.match_banked[0] = 999
	assert_eq(RoundManager.get_stamps(0), 1, "results must be a snapshot")
	assert_eq(RoundManager.get_match_banked(0), 45, "results must be a snapshot")


func test_tied_positive_round_awards_every_winner_and_zero_round_awards_none() -> void:
	var bev := _add_cart(2)
	var rita := _add_cart(3)
	RoundManager._round_banked = {bev.cart_id: 20, rita.cart_id: 20}

	var tied_results := RoundManager._build_round_results()

	assert_eq(tied_results.winner_ids, [2, 3])
	assert_eq(tied_results.stamps, {2: 1, 3: 1})
	assert_eq(tied_results.match_banked, {2: 20, 3: 20})
	RoundManager.round_number = 2
	RoundManager._round_banked = {bev.cart_id: 0, rita.cart_id: 0}

	var empty_results := RoundManager._build_round_results()

	assert_eq(empty_results.winner_ids, [])
	assert_eq(empty_results.stamps, {2: 1, 3: 1})
	assert_eq(empty_results.match_banked, {2: 20, 3: 20})


func _add_cart(cart_id: int) -> AccountingCart:
	var cart := AccountingCart.new()
	cart.cart_id = cart_id
	add_child_autofree(cart)
	RoundManager.register_cart(cart)
	return cart
