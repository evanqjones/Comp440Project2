extends GutTest
## Pickup collection and live floor registry (store/03-spawns-checkout Step 1.1).

const CART_DOUBLE_SCRIPT = preload("res://tests/store/support/cart_double.gd")
const STORE_SCENE: PackedScene = preload("res://systems/store/store.tscn")
const REGULAR_SPAWN_INTERVAL: float = 0.5
const REGULAR_PICKUP_CAP: int = 46

var _saved_phase: GameTypes.Phase
var _saved_match_running: bool
var _saved_time_left: float


func before_each() -> void:
	_saved_phase = RoundManager.phase
	_saved_match_running = RoundManager._match_running
	_saved_time_left = RoundManager.time_left
	RoundManager.phase = GameTypes.Phase.RUSH


func after_each() -> void:
	RoundManager.phase = _saved_phase
	RoundManager._match_running = _saved_match_running
	RoundManager.time_left = _saved_time_left


func _make_item() -> ItemData:
	var item := ItemData.new()
	item.item_id = 7001
	item.category = GameTypes.Category.BAKERY
	item.value = 10
	return item


func _valued_item(item_id: int, value: int) -> ItemData:
	var item := ItemData.new()
	item.item_id = item_id
	item.value = value
	return item


func _make_cart(accept: bool = true) -> Cart:
	var cart := CART_DOUBLE_SCRIPT.new() as Cart
	cart.set("accept_items", accept)
	add_child_autofree(cart)
	return cart


func _make_pickup(item: ItemData) -> Pickup:
	var pickup := Pickup.new()
	pickup.item = item
	add_child_autofree(pickup)
	return pickup


func test_active_cart_collects_item_and_pickup_leaves_live_registry_immediately() -> void:
	var cart := _make_cart()
	var item := _make_item()
	var pickup := _make_pickup(item)
	assert_has(RoundManager.get_pickups(), pickup, "a live pickup registers with RoundManager")

	pickup.call("_on_body_entered", cart)
	var collected: Array = cart.get("collected")
	assert_eq(collected.size(), 1)
	assert_same(collected[0], item, "pickup passes the same ItemData instance")
	assert_true(pickup.is_taken())
	assert_does_not_have(RoundManager.get_pickups(), pickup, "taken pickup is removed before deferred deletion")
	pickup._on_body_entered(_make_cart())
	assert_eq((cart.get("collected") as Array).size(), 1, "a taken pickup cannot be collected again")


func test_rejected_full_cart_leaves_pickup_available_for_another_cart() -> void:
	var full_cart := _make_cart(false)
	var next_cart := _make_cart()
	var pickup := _make_pickup(_make_item())

	pickup.call("_on_body_entered", full_cart)
	assert_false(pickup.is_taken())
	assert_has(RoundManager.get_pickups(), pickup)
	assert_eq((full_cart.get("collected") as Array).size(), 0)

	pickup.call("_on_body_entered", next_cart)
	assert_true(pickup.is_taken())
	assert_eq((next_cart.get("collected") as Array).size(), 1)
	assert_does_not_have(RoundManager.get_pickups(), pickup)


func test_two_carts_contending_for_pickup_have_only_one_winner() -> void:
	var first_cart := _make_cart()
	var second_cart := _make_cart()
	var pickup := _make_pickup(_make_item())

	pickup.call("_on_body_entered", first_cart)
	pickup.call("_on_body_entered", second_cart)

	assert_eq((first_cart.get("collected") as Array).size() + (second_cart.get("collected") as Array).size(), 1)
	assert_true(pickup.is_taken())
	assert_does_not_have(RoundManager.get_pickups(), pickup)


func test_inactive_phase_rejects_collection_without_taking_pickup() -> void:
	var cart := _make_cart()
	var pickup := _make_pickup(_make_item())
	RoundManager.phase = GameTypes.Phase.COUNTDOWN

	pickup.call("_on_body_entered", cart)
	assert_false(pickup.is_taken())
	assert_eq((cart.get("collected") as Array).size(), 0)
	assert_has(RoundManager.get_pickups(), pickup)


func test_category_roll_uses_specified_weight_boundaries() -> void:
	assert_eq(RoundManager._category_for_roll(0.0), GameTypes.Category.PRODUCE)
	assert_eq(RoundManager._category_for_roll(29.999), GameTypes.Category.PRODUCE)
	assert_eq(RoundManager._category_for_roll(30.0), GameTypes.Category.BAKERY)
	assert_eq(RoundManager._category_for_roll(54.999), GameTypes.Category.BAKERY)
	assert_eq(RoundManager._category_for_roll(55.0), GameTypes.Category.DAIRY)
	assert_eq(RoundManager._category_for_roll(80.0), GameTypes.Category.SNACKS)
	assert_eq(RoundManager._category_for_roll(92.0), GameTypes.Category.FROZEN)
	assert_eq(RoundManager._category_for_roll(98.0), GameTypes.Category.ELECTRONICS)
	assert_eq(RoundManager._item_value_for_category(GameTypes.Category.PRODUCE), 5)
	assert_eq(RoundManager._item_value_for_category(GameTypes.Category.BAKERY), 10)
	assert_eq(RoundManager._item_value_for_category(GameTypes.Category.DAIRY), 10)
	assert_eq(RoundManager._item_value_for_category(GameTypes.Category.SNACKS), 15)
	assert_eq(RoundManager._item_value_for_category(GameTypes.Category.FROZEN), 20)
	assert_eq(RoundManager._item_value_for_category(GameTypes.Category.ELECTRONICS), 40)


func test_regular_spawns_are_delayed_weighted_unique_and_use_category_visuals() -> void:
	var store := _make_store()
	_begin_active_round()
	RoundManager._rng.seed = 440

	assert_true(RoundManager._spawn_regular_pickup() is Pickup)
	assert_eq(RoundManager.get_pickups().size(), 1)
	var first := RoundManager.get_pickups()[0]
	assert_eq(first.item.item_id, 0)
	assert_eq(first.item.value, RoundManager._item_value_for_category(first.item.category))
	assert_eq(first.get_parent().name, _category_node_name(first.item.category))
	assert_true(first.position.x >= -1.6 and first.position.x <= 1.6, "pickup lands in the open center of its aisle")
	assert_true(first.position.z >= -11.0 and first.position.z <= 1.0, "pickup remains inside its aisle spawn interval")
	assert_not_null(first.get_node_or_null("Visual/%sVisual" % _category_node_name(first.item.category)))

	assert_true(RoundManager._spawn_regular_pickup() is Pickup)
	var second := RoundManager.get_pickups()[1]
	assert_eq(second.item.item_id, 1)
	assert_ne(first.item.get_instance_id(), second.item.get_instance_id(), "each spawn receives independent ItemData")


func test_regular_spawns_wait_half_a_second_and_only_count_active_time() -> void:
	_make_store()
	RoundManager.phase = GameTypes.Phase.IDLE
	RoundManager._match_running = false
	RoundManager.start_match()
	RoundManager._physics_process(2.99)
	assert_eq(RoundManager.get_pickups().size(), 0)
	RoundManager._physics_process(0.01)
	assert_eq(RoundManager.phase, GameTypes.Phase.RUSH)
	assert_eq(RoundManager.get_pickups().size(), 0, "countdown time does not advance the spawn timer")

	RoundManager._physics_process(0.49)
	assert_eq(RoundManager.get_pickups().size(), 0)
	RoundManager._physics_process(0.01)
	assert_eq(RoundManager.get_pickups().size(), 1)


func test_regular_spawn_cap_includes_existing_floor_pickups_and_has_no_backlog() -> void:
	var store := _make_store()
	_begin_active_round()
	for index: int in REGULAR_PICKUP_CAP:
		assert_true(RoundManager._spawn_regular_pickup() is Pickup)
	assert_eq(RoundManager.get_pickups().size(), REGULAR_PICKUP_CAP)

	RoundManager._physics_process(5.0)
	assert_eq(RoundManager.get_pickups().size(), REGULAR_PICKUP_CAP, "regular spawns stop at the shared floor cap")
	RoundManager.get_pickups()[0].free()
	RoundManager._physics_process(0.49)
	assert_eq(RoundManager.get_pickups().size(), REGULAR_PICKUP_CAP - 1, "waiting at cap does not build a spawn backlog")
	RoundManager._physics_process(0.02)
	assert_eq(RoundManager.get_pickups().size(), REGULAR_PICKUP_CAP)


func test_start_match_clears_floor_and_resets_spawn_state() -> void:
	_make_store()
	_begin_active_round()
	RoundManager._spawn_regular_pickup()
	assert_eq(RoundManager.get_pickups().size(), 1)
	RoundManager.phase = GameTypes.Phase.IDLE
	RoundManager._match_running = false

	RoundManager.start_match()
	assert_eq(RoundManager.get_pickups().size(), 0, "a new match starts with a clear floor")
	RoundManager._set_phase(GameTypes.Phase.RUSH)
	RoundManager.time_left = 120.0
	RoundManager._physics_process(REGULAR_SPAWN_INTERVAL)
	assert_eq(RoundManager.get_pickups().size(), 1)
	assert_eq(RoundManager.get_pickups()[0].item.item_id, 0, "item IDs restart with a new match")


func test_checkout_banks_once_after_deferred_request_and_ignores_duplicate_and_empty() -> void:
	var store := _make_store()
	var checkout := store.get_node("CheckoutZone") as Area3D
	var cart := _make_cart()
	cart.cart_id = 11
	RoundManager.register_cart(cart)
	var item := _valued_item(11, 10)
	(cart as StoreCartDouble).checkout_items.append(item)
	watch_signals(RoundManager)

	assert_true(checkout.body_entered.is_connected(Callable(checkout, "_on_body_entered")))
	checkout.call("_on_body_entered", cart)
	checkout.call("_on_body_entered", cart)
	assert_eq(RoundManager.get_round_banked(11), 0, "checkout waits for the physics frame to resolve")
	await get_tree().process_frame
	assert_eq(RoundManager.get_round_banked(11), 10)
	assert_eq(RoundManager.get_banked_items(11).size(), 1)
	assert_same(RoundManager.get_banked_items(11)[0], item)
	assert_signal_emitted_with_parameters(RoundManager, "checked_out", [cart, 10])
	assert_eq((cart as StoreCartDouble).checkout_items.size(), 0)

	RoundManager.call("_request_checkout", cart)
	await get_tree().process_frame
	assert_eq(RoundManager.get_round_banked(11), 10, "an empty trip does not add value")
	assert_signal_emit_count(RoundManager, "checked_out", 1)


func test_checkout_repeats_each_trip_and_banked_getter_returns_snapshot() -> void:
	var cart := _make_cart()
	cart.cart_id = 12
	RoundManager.register_cart(cart)
	var double := cart as StoreCartDouble
	double.checkout_items.append(_valued_item(101, 5))
	RoundManager.call("_request_checkout", cart)
	await get_tree().process_frame
	double.checkout_items.append(_valued_item(102, 20))
	RoundManager.call("_request_checkout", cart)
	await get_tree().process_frame
	assert_eq(RoundManager.get_round_banked(12), 25)
	var banked := RoundManager.get_banked_items(12)
	assert_eq(banked.size(), 2)
	assert_eq(banked[0].item_id, 101)
	assert_eq(banked[1].item_id, 102)
	banked.clear()
	assert_eq(RoundManager.get_banked_items(12).size(), 2)


func test_same_frame_inheritance_finishes_before_deferred_checkout() -> void:
	var cart := _make_cart()
	cart.cart_id = 13
	RoundManager.register_cart(cart)
	var double := cart as StoreCartDouble
	double.checkout_items.append(_valued_item(201, 10))
	RoundManager.call("_request_checkout", cart)
	# Simulate Cart finishing same-frame inheritance before deferred checkout drains.
	var inherited := _valued_item(202, 40)
	double.checkout_items.append(inherited)
	await get_tree().process_frame
	assert_eq(RoundManager.get_round_banked(13), 50)
	assert_same(RoundManager.get_banked_items(13)[1], inherited)


func test_accepted_checkout_is_banked_before_closed_round_results() -> void:
	_make_store()
	var cart := _make_cart()
	cart.cart_id = 14
	RoundManager.register_cart(cart)
	(cart as StoreCartDouble).checkout_items.append(_valued_item(301, 15))
	watch_signals(RoundManager)
	RoundManager.call("_request_checkout", cart)
	RoundManager._enter_closed()
	await get_tree().process_frame
	assert_eq(RoundManager.phase, GameTypes.Phase.RESULTS)
	var results := get_signal_parameters(RoundManager, "round_ended")[0] as RoundResults
	assert_eq(results.banked[14], 15)
	assert_eq(RoundManager.get_banked_items(14).size(), 1)
	assert_signal_emitted(RoundManager, "round_ended")


func test_closed_phase_rejects_new_checkout_request() -> void:
	var cart := _make_cart()
	cart.cart_id = 15
	RoundManager.register_cart(cart)
	(cart as StoreCartDouble).checkout_items.append(_valued_item(401, 30))
	RoundManager.phase = GameTypes.Phase.CLOSED
	RoundManager.call("_request_checkout", cart)
	await get_tree().process_frame
	assert_eq(RoundManager.get_round_banked(15), 0)
	assert_eq((cart as StoreCartDouble).checkout_items.size(), 1)


func test_robbed_signal_spawns_only_spills_once_preserving_identity_and_value() -> void:
	_make_store()
	var winner := _make_cart()
	var loser := _make_cart()
	winner.cart_id = 21
	loser.cart_id = 22
	loser.position = Vector3(4.0, 0.0, -3.0)
	RoundManager.register_cart(winner)
	RoundManager.register_cart(loser)
	RoundManager.register_cart(loser)
	var winner_double := winner as StoreCartDouble
	var loser_double := loser as StoreCartDouble
	var transferred: Array[ItemData] = []
	var spilled: Array[ItemData] = []
	var original_value := 0
	for item_id: int in 28:
		var item := _valued_item(500 + item_id, 5 + item_id)
		if item_id == 27:
			item.category = GameTypes.Category.DEAL
			item.value = 100
			item.is_deal = true
		original_value += item.value
		if item_id < 8:
			winner_double.checkout_items.append(item)
		else:
			loser_double.checkout_items.append(item)
	var inherited_items := loser_double.take_all_items()
	for item_index: int in inherited_items.size():
		var item := inherited_items[item_index]
		if item_index < 16:
			winner_double.checkout_items.append(item)
			transferred.append(item)
		else:
			spilled.append(item)
	assert_eq(winner_double.checkout_items.size(), 24)
	assert_eq(loser_double.checkout_items.size(), 0)

	loser.cart_robbed.emit(winner, loser, transferred, spilled)
	var floor_items := RoundManager.get_pickups()
	assert_eq(floor_items.size(), 4, "all four overflow items spill even with one listener connection")
	var conserved_value := 0
	var all_ids: Dictionary[int, bool] = {}
	for item: ItemData in winner_double.checkout_items:
		conserved_value += item.value
		all_ids[item.item_id] = true
	for pickup: Pickup in floor_items:
		assert_has(spilled, pickup.item)
		assert_does_not_have(transferred, pickup.item, "items already inherited never respawn")
		assert_lt(pickup.global_position.distance_to(loser.global_position), 2.0, "spill lands beside the loser")
		assert_eq(pickup.item.is_deal, pickup.item.category == GameTypes.Category.DEAL)
		all_ids[pickup.item.item_id] = true
		conserved_value += pickup.item.value
	assert_eq(all_ids.size(), 28, "each identity ends in exactly one destination")
	assert_eq(conserved_value, original_value, "all 28 item values remain in the winner or on the floor")
	for item: ItemData in spilled:
		var found := false
		for pickup: Pickup in floor_items:
			if pickup.item == item:
				found = true
		assert_true(found, "the original spilled ItemData instance and ID survive")


func test_spills_ignore_regular_floor_cap_and_pause_regular_spawning() -> void:
	_make_store()
	_begin_active_round()
	var loser := _make_cart()
	RoundManager.register_cart(loser)
	for index: int in REGULAR_PICKUP_CAP:
		RoundManager._spawn_regular_pickup()
	var spills: Array[ItemData] = []
	for index: int in 4:
		spills.append(_valued_item(700 + index, 10))
	var no_transfers: Array[ItemData] = []
	loser.cart_robbed.emit(loser, loser, no_transfers, spills)
	assert_eq(RoundManager.get_pickups().size(), REGULAR_PICKUP_CAP + 4)
	RoundManager._physics_process(1.0)
	assert_eq(RoundManager.get_pickups().size(), REGULAR_PICKUP_CAP + 4, "ordinary spawns pause above the shared floor cap")


func _make_store() -> Store:
	var store := STORE_SCENE.instantiate() as Store
	add_child_autofree(store)
	return store


func _begin_active_round() -> void:
	RoundManager.phase = GameTypes.Phase.IDLE
	RoundManager._match_running = false
	RoundManager.start_match()
	RoundManager._set_phase(GameTypes.Phase.RUSH)
	RoundManager.time_left = 120.0


func _category_node_name(category: GameTypes.Category) -> String:
	return ["Produce", "Bakery", "Dairy", "Snacks", "Frozen", "Electronics"][int(category)]
