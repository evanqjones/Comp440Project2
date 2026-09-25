extends GutTest

const CART_SCENE := "res://systems/cart/cart.tscn"

func test_personality_resource_defaults() -> void:
	var personality = BotPersonality.new()
	assert_eq(personality.greed, 10, "Default greed should be 10")
	assert_eq(personality.base_aggression, 0.5, "Default base_aggression should be 0.5")
	assert_eq(personality.boost_habit, 0.5, "Default boost_habit should be 0.5")


func test_countdown_locks_controls() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	
	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)
	
	RoundManager.phase = GameTypes.Phase.COUNTDOWN
	
	var cmd := controller.build_command(0.016)
	assert_eq(cmd.throttle, 0.0, "Countdown should lock throttle to 0")
	assert_eq(cmd.steer, 0.0, "Countdown should lock steer to 0")
	assert_false(cmd.boost, "Countdown should lock boost to false")


func test_round_start_enables_timer() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	
	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)
	
	assert_true(controller.decision_timer.is_stopped(), "Decision timer should be stopped initially")
	
	# Mock RoundManager round_started signal
	RoundManager.round_started.emit(1)
	
	assert_false(controller.decision_timer.is_stopped(), "Decision timer should start after round_started")


func test_round_end_neutralizes_commands() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	
	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)
	
	# Mock active gameplay phase
	RoundManager.phase = GameTypes.Phase.RUSH
	RoundManager.round_started.emit(1)
	
	assert_false(controller.decision_timer.is_stopped(), "Decision timer should be running during RUSH")
	
	# Emit round_ended
	var results := RoundResults.new()
	RoundManager.round_ended.emit(results)
	
	assert_true(controller.decision_timer.is_stopped(), "Decision timer should stop after round_ended")
	
	# Commands should be locked
	var cmd := controller.build_command(0.016)
	assert_eq(cmd.throttle, 0.0, "Post-round should lock throttle to 0")
	assert_eq(cmd.steer, 0.0, "Post-round should lock steer to 0")
	assert_false(cmd.boost, "Post-round should lock boost to false")


func test_collecting_utility_targeting() -> void:
	# 1. Create a mock cart and place it at (0, 0, 0)
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	cart.global_position = Vector3.ZERO
	
	# 2. Create the BotController
	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)
	
	# 3. Create mock Pickups and ItemData
	# Pickup A: value = 10, distance = 10m (global_position = (10, 0, 0)) -> utility = 10 / 10 = 1.0
	var pA := Pickup.new()
	add_child_autofree(pA)
	var itemA := ItemData.new()
	itemA.value = 10
	itemA.item_id = 1
	pA.item = itemA
	pA.global_position = Vector3(10, 0, 0)
	
	# Pickup B: value = 50, distance = 20m (global_position = (0, 0, 20)) -> utility = 50 / 20 = 2.5
	var pB := Pickup.new()
	add_child_autofree(pB)
	var itemB := ItemData.new()
	itemB.value = 50
	itemB.item_id = 2
	pB.item = itemB
	pB.global_position = Vector3(0, 0, 20)
	
	# Inject mock pickups into controller's override
	controller.test_pickups_override = [pA, pB]
	
	# 4. Trigger active game phase and run decision tick
	RoundManager.phase = GameTypes.Phase.RUSH
	controller._evaluate_decisions()
	
	# The FSM state should be COLLECTING
	assert_eq(controller.state, BotController.AIState.COLLECTING, "FSM should be in COLLECTING state")
	
	# Target position should be Pickup B's position because 2.5 > 1.0
	assert_eq(controller.target_position, pB.global_position, "Target position should be set to Pickup B (highest utility)")
