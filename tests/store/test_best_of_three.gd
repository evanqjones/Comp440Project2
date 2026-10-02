extends GutTest
## Best of 3 (docs/features/store/05-best-of-three/FEATURE.md, GAME_SPEC.md §3.2): rounds 1 → 2 → 3,
## stamps, match totals, MATCH_OVER and SHOP AGAIN.

const STORE_SCENE := preload("res://systems/store/store.tscn")


## A cart stand-in that only counts resets (no driving, no tuning).
class ResetCart extends Cart:
	var reset_count: int = 0

	func _ready() -> void:
		pass

	func _physics_process(_delta: float) -> void:
		pass

	func reset_for_round(_spawn: Transform3D) -> void:
		reset_count += 1


var _saved_carts: Array[Cart]
var _saved_physics_processing: bool
var _carts: Array[ResetCart] = []


func before_each() -> void:
	_saved_carts = RoundManager._carts.duplicate()
	_saved_physics_processing = RoundManager.is_physics_processing()
	RoundManager.set_physics_process(false)
	RoundManager._carts.clear()
	RoundManager.phase = GameTypes.Phase.IDLE
	RoundManager.round_number = 0
	RoundManager._phase_time_left = 0.0
	RoundManager._close_pending = false
	RoundManager._match_running = false
	_carts.clear()
	for id: int in 3:
		var cart := ResetCart.new()
		cart.cart_id = id
		add_child_autofree(cart)
		RoundManager.register_cart(cart)
		_carts.append(cart)


func after_each() -> void:
	RoundManager._carts = _saved_carts
	RoundManager.phase = GameTypes.Phase.IDLE
	RoundManager.round_number = 0
	RoundManager._phase_time_left = 0.0
	RoundManager._close_pending = false
	RoundManager._match_running = false
	RoundManager._round_banked.clear()
	RoundManager._match_banked.clear()
	RoundManager._stamps.clear()
	RoundManager.set_physics_process(_saved_physics_processing)


## Count down into RUSH, set each cart's money for the round, run the clock out, and let the
## deferred results land. Returns the round's RoundResults.
func _play_round(banked: Dictionary) -> RoundResults:
	watch_signals(RoundManager)
	RoundManager._physics_process(RoundManager.COUNTDOWN_DURATION)
	assert_eq(RoundManager.phase, GameTypes.Phase.RUSH)
	for id: int in banked:
		RoundManager._round_banked[id] = banked[id]
	RoundManager._physics_process(RoundManager.ROUND_DURATION)
	await wait_process_frames(1)
	var parameters: Variant = get_signal_parameters(RoundManager, "round_ended")
	return (parameters as Array)[0] as RoundResults if parameters != null else null


func test_results_lead_into_round_two_with_totals_kept() -> void:
	add_child_autofree(STORE_SCENE.instantiate()) # carts reset at the store's starts
	RoundManager.start_match()
	await _play_round({0: 50, 1: 120})
	assert_eq(RoundManager.phase, GameTypes.Phase.RESULTS)
	RoundManager._physics_process(RoundManager.RESULTS_DURATION)
	assert_eq(RoundManager.phase, GameTypes.Phase.COUNTDOWN, "round 2's countdown")
	assert_eq(RoundManager.round_number, 2)
	assert_eq(RoundManager.time_left, RoundManager.ROUND_DURATION, "2:00 again")
	assert_eq(RoundManager.get_round_banked(1), 0, "a new round starts at $0")
	assert_eq(RoundManager.get_match_banked(1), 120, "match totals kept")
	assert_eq(RoundManager.get_stamps(1), 1)
	assert_eq(_carts[1].reset_count, 2, "carts reset empty at the start of each round")
	RoundManager._physics_process(RoundManager.COUNTDOWN_DURATION)
	assert_eq(RoundManager.phase, GameTypes.Phase.RUSH)


func test_round_winner_gets_a_stamp_ties_share_and_no_money_no_stamp() -> void:
	RoundManager.start_match()
	var first := await _play_round({0: 50, 1: 120})
	assert_eq(first.winner_ids, [1] as Array[int])
	assert_eq(first.stamps.get(1, 0), 1)
	RoundManager._physics_process(RoundManager.RESULTS_DURATION)
	var second := await _play_round({0: 80, 2: 80})
	assert_eq(second.winner_ids, [0, 2] as Array[int], "a tie for the top: both get a stamp")
	assert_eq(second.stamps.get(0, 0), 1)
	assert_eq(second.stamps.get(1, 0), 1)
	assert_eq(second.stamps.get(2, 0), 1)
	assert_eq(second.match_banked.get(0, 0), 130)
	RoundManager._physics_process(RoundManager.RESULTS_DURATION)
	var third := await _play_round({})
	assert_true(third.winner_ids.is_empty(), "nobody banked: no stamp")
	assert_eq(third.stamps.get(1, 0), 1, "stamps unchanged")


func test_round_three_ends_the_match_with_the_winner() -> void:
	RoundManager.start_match()
	await _play_round({0: 100})
	RoundManager._physics_process(RoundManager.RESULTS_DURATION)
	await _play_round({1: 100})
	RoundManager._physics_process(RoundManager.RESULTS_DURATION)
	var last := await _play_round({0: 10, 1: 5})
	assert_eq(RoundManager.phase, GameTypes.Phase.MATCH_OVER, "no 10 s wait after round 3")
	assert_true(last.is_match_over)
	assert_eq(last.round_number, 3)
	assert_eq(last.match_winner_ids, [0] as Array[int], "2 stamps beat 1")
	RoundManager._physics_process(60.0)
	assert_eq(RoundManager.phase, GameTypes.Phase.MATCH_OVER, "the clock stops")


func test_stamp_tie_goes_to_total_banked_then_shares() -> void:
	RoundManager.start_match()
	await _play_round({0: 100})
	RoundManager._physics_process(RoundManager.RESULTS_DURATION)
	await _play_round({1: 90})
	RoundManager._physics_process(RoundManager.RESULTS_DURATION)
	var last := await _play_round({0: 10, 1: 10})
	assert_eq(last.stamps.get(0, 0), 2)
	assert_eq(last.stamps.get(1, 0), 2)
	assert_eq(last.match_winner_ids, [0] as Array[int], "stamps tied: $110 beats $100")

	RoundManager.start_match()
	await _play_round({0: 100})
	RoundManager._physics_process(RoundManager.RESULTS_DURATION)
	await _play_round({1: 100})
	RoundManager._physics_process(RoundManager.RESULTS_DURATION)
	last = await _play_round({0: 10, 1: 10})
	assert_eq(last.match_winner_ids, [0, 1] as Array[int], "exact tie: shared")


func test_shop_again_from_match_over_starts_fresh() -> void:
	RoundManager.start_match()
	for round_index: int in 3:
		await _play_round({0: 40})
		if round_index < 2:
			RoundManager._physics_process(RoundManager.RESULTS_DURATION)
	assert_eq(RoundManager.phase, GameTypes.Phase.MATCH_OVER)
	RoundManager.start_match()
	assert_eq(RoundManager.phase, GameTypes.Phase.COUNTDOWN)
	assert_eq(RoundManager.round_number, 1)
	assert_eq(RoundManager.get_stamps(0), 0, "stamps cleared")
	assert_eq(RoundManager.get_match_banked(0), 0, "match totals cleared")


func test_match_banked_includes_the_live_round_once() -> void:
	RoundManager.start_match()
	await _play_round({2: 70})
	assert_eq(RoundManager.get_match_banked(2), 70, "during RESULTS: counted once")
	RoundManager._physics_process(RoundManager.RESULTS_DURATION)
	RoundManager._physics_process(RoundManager.COUNTDOWN_DURATION)
	RoundManager._round_banked[2] = 30
	assert_eq(RoundManager.get_match_banked(2), 100, "earlier rounds + this round so far")
