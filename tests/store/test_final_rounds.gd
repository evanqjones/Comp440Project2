extends GutTest
## Final Store match accounting (docs/features/store/04-final-rounds/01-spec.md §3).

const CART_SCENE: PackedScene = preload("res://systems/cart/cart.tscn")
const STORE_SCENE: PackedScene = preload("res://systems/store/store.tscn")

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


func test_deal_spawns_once_outside_regular_cap_and_restarts_after_collection() -> void:
	var store := STORE_SCENE.instantiate() as Store
	add_child_autofree(store)
	await wait_process_frames(1)
	RoundManager.phase = GameTypes.Phase.RUSH
	RoundManager._deal_spawn_time_left = 0.0
	watch_signals(RoundManager)

	RoundManager._advance_deal_spawns(0.01)

	var deal: Pickup = RoundManager._deal_pickup
	assert_not_null(deal)
	assert_eq(deal.item.category, GameTypes.Category.DEAL)
	assert_eq(deal.item.value, 100)
	assert_signal_emit_count(RoundManager, "deal_spawned", 1)
	RoundManager._advance_deal_spawns(30.0)
	assert_same(RoundManager._deal_pickup, deal, "only one Deal can be live")
	var collector := CART_SCENE.instantiate() as Cart
	add_child_autofree(collector)
	deal._on_body_entered(collector)
	RoundManager._advance_deal_spawns(0.0)
	assert_null(RoundManager._deal_pickup)
	assert_true(
		RoundManager._deal_spawn_time_left >= RoundManager.DEAL_MIN_INTERVAL
		and RoundManager._deal_spawn_time_left <= RoundManager.DEAL_MAX_INTERVAL
	)


func test_deal_does_not_consume_a_regular_pickup_cap_slot() -> void:
	var store := STORE_SCENE.instantiate() as Store
	add_child_autofree(store)
	await wait_process_frames(1)
	for _index: int in RoundManager.REGULAR_PICKUP_CAP:
		assert_not_null(RoundManager._spawn_regular_pickup())
	RoundManager._deal_spawn_time_left = 0.0
	RoundManager._advance_deal_spawns(0.01)

	assert_eq(RoundManager._regular_pickup_count(), RoundManager.REGULAR_PICKUP_CAP)
	assert_eq(RoundManager.get_pickups().size(), RoundManager.REGULAR_PICKUP_CAP + 1)


func test_real_cart_spill_preserves_the_deal_identity_value_and_single_live_guard() -> void:
	var store := STORE_SCENE.instantiate() as Store
	add_child_autofree(store)
	await wait_process_frames(1)
	RoundManager.phase = GameTypes.Phase.RUSH
	var winner := CART_SCENE.instantiate() as Cart
	winner.cart_id = 7
	winner.position = Vector3.ZERO
	add_child_autofree(winner)
	var loser := CART_SCENE.instantiate() as Cart
	loser.cart_id = 8
	loser.position = Vector3(0.0, 0.0, -1.5)
	add_child_autofree(loser)
	RoundManager.register_cart(winner)
	RoundManager.register_cart(loser)
	for item_id: int in 20:
		assert_true(winner.try_add_item(_item(item_id, 5)))
	var spilled_deal: ItemData
	for item_id: int in 8:
		var item := _item(100 + item_id, 10)
		if item_id == 7:
			item.category = GameTypes.Category.DEAL
			item.value = 100
			spilled_deal = item
		assert_true(loser.try_add_item(item))
	winner._speed_before_move = 14.0
	loser._speed_before_move = 0.0
	winner._resolve_contact(loser)

	assert_eq(winner.get_state().items.size(), 24)
	assert_eq(loser.get_state().items.size(), 0)
	assert_eq(RoundManager.get_pickups().size(), 4)
	var deal_pickup: Pickup
	for pickup: Pickup in RoundManager.get_pickups():
		if pickup.item == spilled_deal:
			deal_pickup = pickup
	assert_not_null(deal_pickup)
	assert_same(deal_pickup.item, spilled_deal)
	assert_eq(deal_pickup.item.item_id, 107)
	assert_eq(deal_pickup.item.category, GameTypes.Category.DEAL)
	assert_eq(deal_pickup.item.value, 100)
	assert_same(RoundManager._deal_pickup, deal_pickup)
	var conserved_value := winner.get_state().value
	for pickup: Pickup in RoundManager.get_pickups():
		conserved_value += pickup.item.value
	assert_eq(conserved_value, 270)


func _add_cart(cart_id: int) -> AccountingCart:
	var cart := AccountingCart.new()
	cart.cart_id = cart_id
	add_child_autofree(cart)
	RoundManager.register_cart(cart)
	return cart


func _item(item_id: int, value: int) -> ItemData:
	var item := ItemData.new()
	item.item_id = item_id
	item.category = GameTypes.Category.PRODUCE
	item.value = value
	return item
