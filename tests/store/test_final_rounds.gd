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


func test_results_advance_to_the_next_round_with_empty_round_state() -> void:
	var cart := _add_cart(4)
	RoundManager._round_banked = {cart.cart_id: 55}
	RoundManager._banked_items[cart.cart_id] = [] as Array[ItemData]
	RoundManager.round_number = 1
	RoundManager._phase_time_left = RoundManager.RESULTS_DURATION
	RoundManager.phase = GameTypes.Phase.RESULTS

	RoundManager._physics_process(RoundManager.RESULTS_DURATION)

	assert_eq(RoundManager.phase, GameTypes.Phase.COUNTDOWN)
	assert_eq(RoundManager.round_number, 2)
	assert_eq(RoundManager.time_left, RoundManager.ROUND_DURATION)
	assert_eq(RoundManager.get_round_banked(cart.cart_id), 0)
	assert_eq(RoundManager.get_banked_items(cart.cart_id), [])


func test_third_round_results_name_match_winners_then_enter_match_over() -> void:
	var player := _add_cart(5)
	var carl := _add_cart(6)
	RoundManager.round_number = 3
	RoundManager._round_banked = {player.cart_id: 40, carl.cart_id: 10}

	var results := RoundManager._build_round_results()

	assert_true(results.is_match_over)
	assert_eq(results.match_winner_ids, [5])
	RoundManager._phase_time_left = RoundManager.RESULTS_DURATION
	RoundManager.phase = GameTypes.Phase.RESULTS
	RoundManager._physics_process(RoundManager.RESULTS_DURATION)
	assert_eq(RoundManager.phase, GameTypes.Phase.MATCH_OVER)
	assert_false(RoundManager._match_running)


func _add_cart(cart_id: int) -> AccountingCart:
	var cart := AccountingCart.new()
	cart.cart_id = cart_id
	add_child_autofree(cart)
	RoundManager.register_cart(cart)
	return cart
