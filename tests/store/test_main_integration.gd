extends GutTest
## Startup-scene integration for Anthony's greybox Store.

const MAIN_SCENE := preload("res://systems/core/main.tscn")


func test_main_starts_with_real_store_and_player_cart() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child_autofree(main)
	await wait_process_frames(1)

	assert_null(main.get_node_or_null("DemoRound"), "the fallback demo is no longer the startup gameplay scene")
	assert_not_null(main.get_node_or_null("Store"), "the Store scene is instanced in the startup scene")
	var player := main.get_node_or_null("Carts/PlayerCart") as Cart
	assert_not_null(player, "the human cart is present")
	if player != null:
		assert_eq(player.cart_id, 0)
		assert_eq(player.profile.display_name, "You")
		assert_not_null(player.get_node_or_null("PlayerController"), "the human cart receives keyboard/gamepad input")
		assert_true(RoundManager.get_carts().has(player), "the human cart is registered with the round manager")
	assert_not_null(main.get_node_or_null("ChaseCamera"), "the human player has a chase camera")
	assert_not_null(main.get_node_or_null("PlayerHud"), "the real player HUD is connected")
	assert_eq(RoundManager.get_checkout_position(), Vector3(0.0, 1.0, 13.0))


func test_main_spawns_and_connects_all_three_rivals() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child_autofree(main)
	await wait_process_frames(1)

	var carts_root := main.get_node_or_null("Carts") as Node3D
	assert_not_null(carts_root, "main owns the four-cart container")
	if carts_root == null:
		return
	var expected: Array[Dictionary] = [
		{"node": "CarlCart", "id": 1, "name": "Coupon Carl", "greed": 12, "aggression": 0.8, "boost": 0.4},
		{"node": "BevCart", "id": 2, "name": "Aunt Bev", "greed": 6, "aggression": 0.2, "boost": 0.2},
		{"node": "RitaCart", "id": 3, "name": "Rolling Rita", "greed": 20, "aggression": 0.4, "boost": 0.9},
	]
	var starts := (main.get_node("Store") as Store).get_start_transforms()
	assert_eq(carts_root.get_child_count(), 4, "one human plus three rival carts")
	var controllers: Array[BotController] = []
	for entry: Dictionary in expected:
		var cart := carts_root.get_node_or_null(entry["node"]) as Cart
		assert_not_null(cart, "%s is present" % entry["node"])
		if cart == null:
			continue
		assert_eq(cart.cart_id, entry["id"])
		assert_eq(cart.profile.display_name, entry["name"])
		assert_eq(cart.global_position, starts[entry["id"]].origin, "the rival starts at its indexed Store marker")
		assert_true(RoundManager.get_carts().has(cart), "%s is registered with Store" % entry["node"])
		var agent := cart.get_node_or_null("NavigationAgent3D") as NavigationAgent3D
		assert_not_null(agent, "%s has a navigation agent" % entry["node"])
		if agent != null:
			assert_true(agent.get_navigation_map().is_valid(), "%s agent uses the active navigation map" % entry["node"])
		var controller := cart.get_node_or_null("BotController") as BotController
		assert_not_null(controller, "%s has John's controller" % entry["node"])
		if controller == null:
			continue
		assert_same(controller.cart, cart)
		assert_same(controller.nav_agent, agent)
		assert_eq(controller.personality.greed, entry["greed"])
		assert_almost_eq(controller.personality.base_aggression, entry["aggression"], 0.001)
		assert_almost_eq(controller.personality.boost_habit, entry["boost"], 0.001)
		assert_true(RoundManager.round_started.is_connected(Callable(controller, "_on_round_started")))
		assert_true(cart.cart_robbed.is_connected(Callable(controller, "_on_cart_robbed")))
		controllers.append(controller)
	for controller: BotController in controllers:
		assert_true(controller.decision_timer.is_stopped(), "bots wait for round_started")
	RoundManager.round_started.emit(1)
	for controller: BotController in controllers:
		assert_false(controller.decision_timer.is_stopped(), "round_started activates the bot decision loop")
