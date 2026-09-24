extends GutTest
## Tests for the shared contract classes in systems/shared/ (docs/CONTRACTS.md §1).


func test_game_types_enums() -> void:
	assert_eq(
		GameTypes.Category.keys(),
		["PRODUCE", "BAKERY", "DAIRY", "SNACKS", "FROZEN", "ELECTRONICS", "DEAL"],
		"Category order matches CONTRACTS.md §1.1"
	)
	assert_eq(
		GameTypes.Phase.keys(),
		["IDLE", "COUNTDOWN", "RUSH", "FINAL_CALL", "CLOSED", "RESULTS", "MATCH_OVER"],
		"Phase order matches CONTRACTS.md §1.1"
	)


func test_drive_command_defaults() -> void:
	var cmd := DriveCommand.new()
	assert_eq(cmd.throttle, 0.0)
	assert_eq(cmd.brake, 0.0)
	assert_eq(cmd.steer, 0.0)
	assert_false(cmd.boost)


func test_item_data_defaults() -> void:
	var item := ItemData.new()
	assert_eq(item.item_id, -1, "item_id is unassigned until Store spawns the item")
	assert_eq(item.category, GameTypes.Category.PRODUCE)
	assert_eq(item.value, 0)
	assert_false(item.is_deal)
	assert_null(item.mesh)


func test_item_data_instances_are_independent() -> void:
	var a := ItemData.new()
	var b := ItemData.new()
	a.item_id = 1
	a.value = 40
	a.category = GameTypes.Category.ELECTRONICS
	assert_eq(b.item_id, -1)
	assert_eq(b.value, 0)
	assert_eq(b.category, GameTypes.Category.PRODUCE)


func test_cart_state_defaults() -> void:
	var state := CartState.new()
	assert_eq(state.speed, 0.0)
	assert_eq(state.items.size(), 0)
	assert_eq(state.value, 0)
	assert_eq(state.boost_meter, 0.0)
	assert_false(state.is_stunned)
	assert_false(state.is_immune)


func test_round_results_defaults() -> void:
	var results := RoundResults.new()
	assert_eq(results.round_number, 0)
	assert_eq(results.banked.size(), 0)
	assert_eq(results.winner_ids.size(), 0)
	assert_eq(results.stamps.size(), 0)
	assert_eq(results.match_banked.size(), 0)
	assert_false(results.is_match_over)
	assert_eq(results.match_winner_ids.size(), 0)


func test_profiles_load() -> void:
	var expected := {
		"player": ["You", "Platinum"],
		"carl": ["Coupon Carl", "Gold"],
		"bev": ["Aunt Bev", "Platinum"],
		"rita": ["Rolling Rita", "Silver"],
	}
	for key: String in expected:
		var profile := load("res://systems/shared/profiles/%s.tres" % key) as ShopperProfile
		assert_not_null(profile, "%s.tres loads as a ShopperProfile" % key)
		if profile == null:
			continue
		assert_eq(profile.display_name, expected[key][0])
		assert_eq(profile.tier, expected[key][1])
		assert_ne(profile.color, Color(), "%s has a color" % key)
		assert_ne(profile.blurb, "", "%s has a blurb" % key)


# --- Contract conformance: the stubs (and later the real code) must keep these. ---

const CART_SCENE := "res://systems/cart/cart.tscn"


func _signal_arg_count(obj: Object, signal_name: String) -> int:
	for sig: Dictionary in obj.get_signal_list():
		if sig["name"] == signal_name:
			return (sig["args"] as Array).size()
	return -1


func _method_arg_count(obj: Object, method_name: String) -> int:
	for method: Dictionary in obj.get_method_list():
		if method["name"] == method_name:
			return (method["args"] as Array).size()
	return -1


func _assert_signals(obj: Object, expected: Dictionary, owner_name: String) -> void:
	for signal_name: String in expected:
		assert_eq(_signal_arg_count(obj, signal_name), expected[signal_name],
			"%s signal %s has %d args" % [owner_name, signal_name, expected[signal_name]])


func _assert_methods(obj: Object, expected: Dictionary, owner_name: String) -> void:
	for method_name: String in expected:
		assert_eq(_method_arg_count(obj, method_name), expected[method_name],
			"%s method %s() has %d args" % [owner_name, method_name, expected[method_name]])


func _make_cart() -> Cart:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	return cart


func test_cart_conforms_to_contract() -> void:
	var cart := _make_cart()
	assert_not_null(cart, "cart.tscn root is a Cart")
	if cart == null:
		return
	assert_true(cart is CharacterBody3D, "Cart is a CharacterBody3D (D-015)")
	_assert_signals(cart, {"item_collected": 2, "cart_robbed": 4, "cart_full": 1}, "Cart")
	_assert_methods(cart, {
		"apply_command": 1,
		"try_add_item": 1,
		"take_all_items": 0,
		"reset_for_round": 1,
		"get_state": 0,
		"apply_slip": 1,
	}, "Cart")
	assert_true("cart_id" in cart, "Cart has cart_id")
	assert_true("profile" in cart, "Cart has profile")
	assert_true(cart.get_collision_layer_value(2), "Cart is on physics layer 2 (carts)")
	assert_not_null(cart.get_node_or_null("Visual"), "Cart has a Visual child (assets seam)")


func test_cart_state_items_is_a_copy() -> void:
	var cart := _make_cart()
	cart.profile = load("res://systems/shared/profiles/carl.tres")
	cart.cart_id = 1
	var first := cart.get_state()
	first.items.append(ItemData.new())
	var second := cart.get_state()
	assert_eq(second.items.size(), 0, "changing a snapshot doesn't change the cart")
	assert_eq(second.cart_id, 1)
	assert_eq(second.display_name, "Coupon Carl", "snapshot takes its name from the profile")


func test_pickup_conforms_to_contract() -> void:
	var pickup := Pickup.new()
	autofree(pickup)
	assert_true(pickup is Area3D, "Pickup is an Area3D")
	assert_true("item" in pickup, "Pickup has item")
	assert_true(pickup.get_collision_layer_value(3), "Pickup is on physics layer 3 (pickups)")
	assert_true(pickup.get_collision_mask_value(2), "Pickup detects layer 2 (carts)")


func _round_manager() -> Node:
	return get_tree().root.get_node_or_null("RoundManager")


func test_round_manager_conforms_to_contract() -> void:
	var rm := _round_manager()
	assert_not_null(rm, "RoundManager autoload is registered")
	if rm == null:
		return
	_assert_signals(rm, {
		"phase_changed": 1,
		"round_started": 1,
		"round_ended": 1,
		"checked_out": 2,
		"hazard_spawned": 1,
		"deal_spawned": 1,
	}, "RoundManager")
	_assert_methods(rm, {
		"register_cart": 1,
		"get_carts": 0,
		"get_pickups": 0,
		"get_checkout_position": 0,
		"is_gameplay_active": 0,
		"get_round_banked": 1,
		"get_match_banked": 1,
		"get_stamps": 1,
		"get_banked_items": 1,
		"start_match": 0,
	}, "RoundManager")
	for variable: String in ["phase", "round_number", "time_left", "doors_open"]:
		assert_true(variable in rm, "RoundManager has %s" % variable)


func test_is_gameplay_active_only_in_rush_and_final_call() -> void:
	var rm := _round_manager()
	if rm == null:
		fail_test("RoundManager autoload is missing")
		return
	var saved: GameTypes.Phase = rm.phase
	for phase: GameTypes.Phase in GameTypes.Phase.values():
		rm.phase = phase
		var expected := phase == GameTypes.Phase.RUSH or phase == GameTypes.Phase.FINAL_CALL
		assert_eq(rm.is_gameplay_active(), expected,
			"is_gameplay_active() in %s" % GameTypes.Phase.keys()[phase])
	rm.phase = saved


func test_register_cart_adds_it_once() -> void:
	var rm := _round_manager()
	if rm == null:
		fail_test("RoundManager autoload is missing")
		return
	var cart := _make_cart()
	rm.register_cart(cart)
	rm.register_cart(cart)
	var carts: Array = rm.get_carts()
	assert_eq(carts.count(cart), 1, "a cart registered twice appears once")
