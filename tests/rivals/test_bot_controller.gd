extends GutTest

const CART_SCENE := "res://systems/cart/cart.tscn"

func after_each() -> void:
	RoundManager._carts.clear()


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
	RoundManager.time_left = 60.0
	controller._evaluate_decisions()
	
	# The FSM state should be COLLECTING
	assert_eq(controller.state, BotController.AIState.COLLECTING, "FSM should be in COLLECTING state")
	
	# Target position should be Pickup B's position because 2.5 > 1.0
	assert_eq(controller.target_position, pB.global_position, "Target position should be set to Pickup B (highest utility)")


func test_greed_threshold_triggers_banking() -> void:
	# 1. Create mock cart
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	
	# 2. Create controller with a test personality (greed = 2 items)
	var controller := BotController.new()
	var personality := BotPersonality.new()
	personality.greed = 2
	controller.personality = personality
	controller.cart = cart
	add_child_autofree(controller)
	
	# Set active phase so try_add_item is allowed
	RoundManager.phase = GameTypes.Phase.RUSH
	RoundManager.time_left = 60.0 # High timer
	
	# Decision tick when empty -> should be in COLLECTING state
	controller._evaluate_decisions()
	assert_eq(controller.state, BotController.AIState.COLLECTING, "Empty cart should COLLECT")
	
	# Add 1 item -> still below greed
	var item1 := ItemData.new()
	item1.item_id = 1
	item1.value = 10
	var added1 := cart.try_add_item(item1)
	assert_true(added1, "Should successfully add first item")
	
	controller._evaluate_decisions()
	assert_eq(controller.state, BotController.AIState.COLLECTING, "Cart with 1 item (< greed 2) should COLLECT")
	
	# Add 2nd item -> reaches greed threshold (2)
	var item2 := ItemData.new()
	item2.item_id = 2
	item2.value = 20
	var added2 := cart.try_add_item(item2)
	assert_true(added2, "Should successfully add second item")
	
	# Decision tick when full -> should transition to BANKING
	controller._evaluate_decisions()
	assert_eq(controller.state, BotController.AIState.BANKING, "Reaching greed threshold should trigger BANKING")
	assert_eq(controller.target_position, RoundManager.get_checkout_position(), "Target should be the checkout position")


func test_low_timer_forces_banking() -> void:
	# 1. Create mock cart
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	
	# 2. Create controller
	var controller := BotController.new()
	var personality := BotPersonality.new()
	personality.greed = 10 # High greed
	controller.personality = personality
	controller.cart = cart
	add_child_autofree(controller)
	
	RoundManager.phase = GameTypes.Phase.RUSH
	
	# Timer is high (60.0s) -> should collect
	RoundManager.time_left = 60.0
	controller._evaluate_decisions()
	assert_eq(controller.state, BotController.AIState.COLLECTING, "High timer should COLLECT")
	
	# Timer drops to 19s (inside final call, < 20s) -> should force banking
	RoundManager.time_left = 19.0
	controller._evaluate_decisions()
	assert_eq(controller.state, BotController.AIState.BANKING, "Low timer (< 20s) should force BANKING")
	assert_eq(controller.target_position, RoundManager.get_checkout_position(), "Target should be the checkout position")


func test_chasing_aggression_roll_success() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	cart.cart_id = 0
	cart.global_position = Vector3.ZERO
	RoundManager.register_cart(cart)
	
	var controller := BotController.new()
	var personality := BotPersonality.new()
	personality.base_aggression = 0.8
	controller.personality = personality
	controller.cart = cart
	add_child_autofree(controller)
	
	# Create and register a loaded rival cart
	var rival := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(rival)
	rival.cart_id = 1
	rival.global_position = Vector3(10, 0, 0)
	RoundManager.register_cart(rival)
	
	# Put 12 items into rival cart
	RoundManager.phase = GameTypes.Phase.RUSH
	for i in range(12):
		var item := ItemData.new()
		item.item_id = 100 + i
		item.value = 10
		rival.try_add_item(item)
		
	# Setup test variables and success roll (randf_override = 0.0 <= 0.8)
	RoundManager.time_left = 60.0
	controller.current_aggression = 0.8
	controller._randf_override = 0.0
	
	controller._evaluate_decisions()
	assert_eq(controller.state, BotController.AIState.CHASING, "Successful aggression roll should trigger CHASING")
	assert_eq(controller.target_position, rival.global_position, "Target should be the eligible rival")


func test_chasing_aggression_roll_fail() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	cart.cart_id = 0
	cart.global_position = Vector3.ZERO
	RoundManager.register_cart(cart)
	
	var controller := BotController.new()
	var personality := BotPersonality.new()
	personality.base_aggression = 0.8
	controller.personality = personality
	controller.cart = cart
	add_child_autofree(controller)
	
	# Create and register a loaded rival cart
	var rival := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(rival)
	rival.cart_id = 1
	rival.global_position = Vector3(10, 0, 0)
	RoundManager.register_cart(rival)
	
	# Put 12 items into rival cart
	RoundManager.phase = GameTypes.Phase.RUSH
	for i in range(12):
		var item := ItemData.new()
		item.item_id = 100 + i
		item.value = 10
		rival.try_add_item(item)
		
	# Setup failing roll (randf_override = 1.0 > 0.8)
	RoundManager.time_left = 60.0
	controller.current_aggression = 0.8
	controller._randf_override = 1.0
	
	controller._evaluate_decisions()
	assert_eq(controller.state, BotController.AIState.COLLECTING, "Failed aggression roll should fallback to COLLECTING")


func test_chasing_targets_highest_haul() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	cart.cart_id = 0
	cart.global_position = Vector3.ZERO
	RoundManager.register_cart(cart)
	
	var controller := BotController.new()
	var personality := BotPersonality.new()
	personality.base_aggression = 1.0
	controller.personality = personality
	controller.cart = cart
	add_child_autofree(controller)
	
	# Rival A at 10m with 12 items
	var rivalA := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(rivalA)
	rivalA.cart_id = 1
	rivalA.global_position = Vector3(10, 0, 0)
	RoundManager.register_cart(rivalA)
	RoundManager.phase = GameTypes.Phase.RUSH
	for i in range(12):
		var item := ItemData.new()
		item.item_id = 100 + i
		item.value = 10
		rivalA.try_add_item(item)
		
	# Rival B at 20m with 20 items (higher cargo size!)
	var rivalB := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(rivalB)
	rivalB.cart_id = 2
	rivalB.global_position = Vector3(0, 0, 20)
	RoundManager.register_cart(rivalB)
	for i in range(20):
		var item := ItemData.new()
		item.item_id = 200 + i
		item.value = 10
		rivalB.try_add_item(item)
		
	RoundManager.time_left = 60.0
	controller.current_aggression = 1.0
	controller._randf_override = 0.0
	
	controller._evaluate_decisions()
	assert_eq(controller.state, BotController.AIState.CHASING, "Should chase")
	assert_eq(controller.target_position, rivalB.global_position, "Should target Rival B with the highest cargo size")
	
	# Add Rival C at 5m with 20 items (tie for cargo size, but closer!)
	var rivalC := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(rivalC)
	rivalC.cart_id = 3
	rivalC.global_position = Vector3(5, 0, 0)
	RoundManager.register_cart(rivalC)
	for i in range(20):
		var item := ItemData.new()
		item.item_id = 300 + i
		item.value = 10
		rivalC.try_add_item(item)
		
	controller._evaluate_decisions()
	assert_eq(controller.target_position, rivalC.global_position, "Should target Rival C because it is closer than Rival B")
