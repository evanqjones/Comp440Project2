extends GutTest
## John's bots in the fallback demo (docs/features/player/03-demo-bots/FEATURE.md).

const DEMO_SCENE := "res://systems/player/demo/demo_round.tscn"
const STUB_PATH := "res://systems/store/round_manager.gd"
const PickupScript := preload("res://systems/cart/test/test_pickup.gd")
## GAME_SPEC §12: greed items / aggression / boost habit.
const PERSONALITIES := {
	"carl": [12, 0.8, 0.4],
	"bev": [6, 0.2, 0.2],
	"rita": [20, 0.4, 0.9],
}


func _make_demo() -> Node3D:
	var demo := (load(DEMO_SCENE) as PackedScene).instantiate() as Node3D
	add_child_autofree(demo)
	return demo


func _bot_controller(cart: Cart) -> BotController:
	for child: Node in cart.get_children():
		if child is BotController:
			return child as BotController
	return null


func test_test_pickup_is_a_contract_pickup() -> void:
	var pickup := PickupScript.new()
	assert_true(pickup is Pickup, "TestPickup extends the contract's Pickup, so get_pickups() can return it")
	pickup.free()


func test_stand_in_offers_visible_pickups_and_the_pad() -> void:
	var floor_items := Node3D.new()
	add_child_autofree(floor_items)
	var on_floor := PickupScript.new()
	var taken := PickupScript.new()
	floor_items.add_child(on_floor)
	floor_items.add_child(taken)
	taken.visible = false
	var stand_in := DemoRoundManager.new()
	autofree(stand_in)
	stand_in.demo_pickup_parent = floor_items
	stand_in.demo_checkout_position = Vector3(0.0, 0.0, 15.0)
	assert_eq(stand_in.get_pickups().size(), 1, "only the untaken pickup is offered")
	assert_has(stand_in.get_pickups(), on_floor)
	assert_eq(stand_in.get_checkout_position(), Vector3(0.0, 0.0, 15.0), "bots bank at the pad")


func test_demo_runs_johns_bots_with_game_spec_personalities() -> void:
	_make_demo()
	assert_true(RoundManager is DemoRoundManager, "the stand-in is on the RoundManager autoload")
	var carts := RoundManager.get_carts()
	assert_eq(carts.size(), 4, "all four carts registered")
	var bots := 0
	for cart: Cart in carts:
		var controller := _bot_controller(cart)
		if cart.cart_id == 0:
			assert_null(controller, "the player's cart has no bot")
			continue
		bots += 1
		var name := cart.profile.resource_path.get_file().get_basename()
		assert_not_null(controller, "%s has a BotController" % name)
		if controller == null:
			continue
		var agent := cart.get_node_or_null("NavigationAgent3D") as NavigationAgent3D
		assert_not_null(agent, "%s has a NavigationAgent3D" % name)
		assert_eq(controller.nav_agent, agent, "%s's controller steers with that agent" % name)
		assert_eq(controller.cart, cart)
		var expected: Array = PERSONALITIES[name]
		assert_eq(controller.personality.greed, expected[0], "%s greed" % name)
		assert_almost_eq(controller.personality.base_aggression, expected[1], 0.001, "%s aggression" % name)
		assert_almost_eq(controller.personality.boost_habit, expected[2], 0.001, "%s boost habit" % name)
	assert_eq(bots, 3, "three bots")
	for cart: Cart in carts:
		for child: Node in cart.get_children():
			assert_false(child.get_script() == load("res://systems/cart/test/test_rammer_driver.gd"), "no test rammers left")


func test_demo_offers_its_pickups_and_pad_to_the_bots() -> void:
	_make_demo()
	assert_eq(RoundManager.get_pickups().size(), 30, "5 pickups in each of the 6 aisles")
	assert_eq(RoundManager.get_checkout_position(), Vector3(0.0, 0.0, 15.0))


func test_demo_bakes_a_navmesh_of_the_store() -> void:
	var demo := _make_demo()
	var regions := demo.find_children("*", "NavigationRegion3D", true, false)
	assert_eq(regions.size(), 1, "one navigation region")
	if regions.is_empty():
		return
	var nav_mesh := (regions[0] as NavigationRegion3D).navigation_mesh
	assert_not_null(nav_mesh)
	if nav_mesh != null:
		assert_gt(nav_mesh.get_polygon_count(), 0, "the navmesh was baked on load")


func test_round_started_fires_when_the_rush_begins() -> void:
	var demo := _make_demo()
	watch_signals(RoundManager)
	demo._physics_process(DemoRoundClock.COUNTDOWN + 0.1)
	assert_eq(RoundManager.phase, GameTypes.Phase.RUSH)
	assert_signal_emitted_with_parameters(RoundManager, "round_started", [1])


func test_leaving_the_demo_restores_anthonys_stub() -> void:
	var demo := _make_demo()
	remove_child(demo)
	demo.free()
	assert_eq(RoundManager.get_script().resource_path, STUB_PATH, "the stub is back on RoundManager")
