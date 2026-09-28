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
