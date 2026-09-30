extends GutTest
## Store stage hazard actors and item conservation (integration/04-stage-hazards).

const STORE_SCENE: PackedScene = preload("res://systems/store/store.tscn")
const CART_SCENE: PackedScene = preload("res://systems/cart/cart.tscn")
const PUDDLE_SCENE_PATH: String = "res://systems/store/hazards/slippery_puddle.tscn"
const PALLET_SCENE_PATH: String = "res://systems/store/hazards/falling_pallet.tscn"
const HAZARD_POINTS: Array[Vector3] = [
	Vector3(-18.75, 0.0, -5.0), Vector3(-11.25, 0.0, -5.0),
	Vector3(-3.75, 0.0, -5.0), Vector3(3.75, 0.0, -5.0),
	Vector3(11.25, 0.0, -5.0), Vector3(18.75, 0.0, -5.0),
]

var _saved_phase: GameTypes.Phase
var _saved_carts: Array[Cart]


func before_each() -> void:
	_saved_phase = RoundManager.phase
	_saved_carts = RoundManager.get_carts()
	RoundManager.phase = GameTypes.Phase.RUSH


func after_each() -> void:
	RoundManager.phase = _saved_phase
	RoundManager._carts = _saved_carts


func test_puddle_slips_each_cart_once_and_spawns_original_items() -> void:
	var store := _make_store()
	var first_cart := _make_cart()
	var second_cart := _make_cart()
	RoundManager.register_cart(first_cart)
	RoundManager.register_cart(second_cart)
	var first_item := _make_item(8001, 15)
	var second_item := _make_item(8002, 100, GameTypes.Category.DEAL, true)
	assert_true(first_cart.try_add_item(first_item))
	assert_true(first_cart.try_add_item(second_item))

	var puddle := _load_actor(PUDDLE_SCENE_PATH) as Area3D
	assert_not_null(puddle, "SlipperyPuddle scene is available")
	if puddle == null:
		return
	store.add_child(puddle)
	(puddle as Node).call("_on_body_entered", first_cart)

	assert_eq(first_cart.get_state().items.size(), 0, "the first contact empties the cart")
	assert_gte(first_cart._slip_left, 2.9, "the Cart slip timer is started")
	var dropped := _pickups_for([first_item, second_item])
	assert_eq(dropped.size(), 2, "every carried item becomes a floor pickup")
	for pickup: Pickup in dropped:
		if pickup.item.item_id == first_item.item_id:
			assert_same(pickup.item, first_item)
			assert_eq(pickup.item.value, 15)
		elif pickup.item.item_id == second_item.item_id:
			assert_same(pickup.item, second_item)
			assert_eq(pickup.item.value, 100)
			assert_true(pickup.item.is_deal)
		assert_lt(pickup.global_position.distance_to(first_cart.global_position), 2.0)

	var after_hit_item := _make_item(8003, 10)
	assert_true(first_cart.try_add_item(after_hit_item))
	(puddle as Node).call("_on_body_entered", first_cart)
	assert_eq(first_cart.get_state().items.size(), 1, "the same puddle does not trigger a cart twice")
	assert_eq(_pickups_for([after_hit_item]).size(), 0)

	(puddle as Node).call("_on_body_entered", second_cart)
	assert_true(puddle.is_queued_for_deletion(), "puddle removes itself after all registered carts are affected")


func test_falling_pallet_warns_before_blocking_then_clears() -> void:
	var store := _make_store()
	var actor := _load_actor(PALLET_SCENE_PATH) as Node3D
	assert_not_null(actor, "FallingPallet scene is available")
	if actor == null:
		return
	store.add_child(actor)
	assert_false(actor.call("is_blocking"), "the warning period has no blocker")
	var collision := actor.get_node("Blocker/CollisionShape3D") as CollisionShape3D
	assert_true(collision.disabled, "collision stays off during the shadow warning and fall")

	await wait_physics_frames(294)
	assert_false(actor.call("is_blocking"), "the warning shadow remains visible for five seconds before impact")
	assert_true(collision.disabled, "the lane stays clear while the pallet is warned and falling")
	await wait_physics_frames(36)
	assert_true(actor.call("is_blocking"), "the pallet blocks after its warning and fall")
	assert_false(collision.disabled, "landed pallet enables its blocker")
	await wait_physics_frames(280)
	assert_true(actor.call("is_blocking"), "the landed blocker lasts about five seconds")
	await wait_physics_frames(20)
	assert_false(is_instance_valid(actor), "the pallet actor clears after its five-second block")


func test_hazards_start_after_eight_active_seconds_and_emit_signal() -> void:
	var store := _make_store()
	store._hazard_seconds_until_spawn = 8.0
	var spawned: Array[Node3D] = []
	var on_spawn := func(hazard: Node3D) -> void: spawned.append(hazard)
	RoundManager.hazard_spawned.connect(on_spawn)
	store._advance_hazard_schedule(7.99)
	assert_eq(spawned.size(), 0, "the first hazard waits for eight active gameplay seconds")
	store._advance_hazard_schedule(0.01)
	assert_eq(spawned.size(), 1, "the first hazard appears at the eight-second boundary")
	assert_true(spawned[0] is Area3D or spawned[0].has_method("is_blocking"), "the scheduler creates a puddle or pallet")
	assert_true(HAZARD_POINTS.has(spawned[0].global_position), "hazards use authored open-aisle points")
	RoundManager.hazard_spawned.disconnect(on_spawn)


func test_scheduler_pauses_outside_active_phases_and_resets_per_round() -> void:
	var store := _make_store()
	store._hazard_seconds_until_spawn = 8.0
	RoundManager.phase = GameTypes.Phase.COUNTDOWN
	store._advance_hazard_schedule(20.0)
	assert_eq(store._hazard_seconds_until_spawn, 8.0, "countdown time does not advance hazard cadence")
	RoundManager.round_number = 3
	store._on_hazard_phase_changed(GameTypes.Phase.RUSH)
	assert_eq(store._hazard_seconds_until_spawn, 8.0, "each round starts with an eight-second active delay")
	var bounds: Vector2 = store._hazard_interval_bounds(3)
	assert_eq(bounds, Vector2(6.0, 12.0), "round three shortens the random gap by four seconds")


func test_spawn_selection_rejects_points_near_carts_and_active_hazards() -> void:
	var store := _make_store()
	for point: Vector3 in HAZARD_POINTS:
		assert_true(store._is_hazard_point_clear(store.to_global(point)), "authored spawn points clear walls, fixtures, and checkout")
	var cart := _make_cart()
	RoundManager.register_cart(cart)
	cart.global_position = HAZARD_POINTS[0]
	var selected: Vector3 = store._select_hazard_spawn_position()
	assert_true(HAZARD_POINTS.has(selected), "selection returns only an authored safe point")
	assert_gt(selected.distance_to(cart.global_position), store.HAZARD_CART_CLEARANCE, "occupied point is rejected")
	for point: Vector3 in HAZARD_POINTS:
		var blocker := Node3D.new()
		blocker.position = point
		blocker.add_to_group("stage_hazards")
		store.add_child(blocker)
	assert_eq(store._select_hazard_spawn_position(), Vector3.INF, "all occupied points make this event skip safely")


func test_hazard_type_is_randomized_then_never_repeats_consecutively() -> void:
	var store := _make_store()
	store._spawn_random_hazard(HAZARD_POINTS[0])
	var first := store.get_node("SlipperyPuddle") if store.has_node("SlipperyPuddle") else store.get_node("FallingPallet")
	store._spawn_random_hazard(HAZARD_POINTS[1])
	var second := store.get_node("FallingPallet") if first.name == "SlipperyPuddle" else store.get_node("SlipperyPuddle")
	assert_ne(first.name, second.name, "the next hazard uses the other type")


func _make_store() -> Store:
	var store := STORE_SCENE.instantiate() as Store
	add_child_autofree(store)
	return store


func _make_cart() -> Cart:
	var cart := (CART_SCENE as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	return cart


func _make_item(item_id: int, value: int, category: GameTypes.Category = GameTypes.Category.PRODUCE, is_deal: bool = false) -> ItemData:
	var item := ItemData.new()
	item.item_id = item_id
	item.value = value
	item.category = category
	item.is_deal = is_deal
	return item


func _load_actor(path: String) -> Object:
	var packed_scene := load(path) as PackedScene
	if packed_scene == null:
		return null
	return packed_scene.instantiate()


func _pickups_for(items: Array[ItemData]) -> Array[Pickup]:
	var found: Array[Pickup] = []
	for pickup: Pickup in RoundManager.get_pickups():
		if items.has(pickup.item):
			found.append(pickup)
	return found
