extends GutTest
## Pickup collection and live floor registry (store/03-spawns-checkout Step 1.1).

const CART_DOUBLE_SCRIPT = preload("res://tests/store/support/cart_double.gd")

var _saved_phase: GameTypes.Phase


func before_each() -> void:
	_saved_phase = RoundManager.phase
	RoundManager.phase = GameTypes.Phase.RUSH


func after_each() -> void:
	RoundManager.phase = _saved_phase


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
