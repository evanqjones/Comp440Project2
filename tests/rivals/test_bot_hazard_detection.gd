extends GutTest

const CART_SCENE := "res://systems/cart/cart.tscn"

func after_each() -> void:
	RoundManager._carts.clear()


func test_hazard_spawned_registers_active_hazard() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)

	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)

	var hazard := Node3D.new()
	add_child_autofree(hazard)

	RoundManager.hazard_spawned.emit(hazard)

	var active: Array[Node3D] = controller.get_active_hazards()
	assert_eq(active.size(), 1, "One active hazard should be registered")
	assert_true(active.has(hazard), "Tracked active hazards should contain the spawned hazard")


func test_hazard_tree_exited_removes_hazard() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)

	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)

	var hazard := Node3D.new()
	add_child(hazard)

	RoundManager.hazard_spawned.emit(hazard)
	assert_eq(controller.get_active_hazards().size(), 1, "Should have 1 active hazard")

	hazard.queue_free()
	# Allow deferred free to take place
	await wait_physics_frames(2)

	assert_eq(controller.get_active_hazards().size(), 0, "Hazard should be removed after tree_exited/free")


func test_round_end_clears_active_hazards() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)

	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)

	var hazard := Node3D.new()
	add_child_autofree(hazard)

	RoundManager.hazard_spawned.emit(hazard)
	assert_eq(controller.get_active_hazards().size(), 1, "Should have 1 active hazard before round end")

	var results := RoundResults.new()
	RoundManager.round_ended.emit(results)

	assert_eq(controller.get_active_hazards().size(), 0, "All active hazards should be cleared on round_ended")


func test_hazards_override_bypasses_registered() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)

	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)

	var hazard_real := Node3D.new()
	add_child_autofree(hazard_real)
	RoundManager.hazard_spawned.emit(hazard_real)

	var hazard_mock := Node3D.new()
	add_child_autofree(hazard_mock)
	controller.test_hazards_override = [hazard_mock]

	var active: Array[Node3D] = controller.get_active_hazards()
	assert_eq(active.size(), 1, "Override should supply hazards")
	assert_true(active.has(hazard_mock), "Override hazard should be present")
	assert_false(active.has(hazard_real), "Real hazard should be bypassed when override is set")


func test_position_inside_hazard_radius_rejected() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)

	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)

	var hazard := Node3D.new()
	add_child_autofree(hazard)
	hazard.global_position = Vector3(0.0, 0.0, 0.0)
	controller.test_hazards_override = [hazard]

	# Point inside default 2.5m danger radius (distance = 2.0m)
	assert_false(controller.is_position_safe_from_hazards(Vector3(2.0, 0.0, 0.0)), "Point at 2.0m should be rejected")
	# Point outside danger radius (distance = 3.0m)
	assert_true(controller.is_position_safe_from_hazards(Vector3(3.0, 0.0, 0.0)), "Point at 3.0m should be accepted")


func test_hazard_custom_danger_radius_respected() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)

	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)

	var hazard := Node3D.new()
	add_child_autofree(hazard)
	hazard.set_meta("danger_radius", 4.0)
	hazard.global_position = Vector3(0.0, 0.0, 0.0)
	controller.test_hazards_override = [hazard]

	# Distance 3.0m: safe under default 2.5m, but unsafe under custom 4.0m radius
	assert_false(controller.is_position_safe_from_hazards(Vector3(3.0, 0.0, 0.0)), "Point at 3.0m should be rejected with 4.0m danger radius")
	# Distance 4.5m: safe
	assert_true(controller.is_position_safe_from_hazards(Vector3(4.5, 0.0, 0.0)), "Point at 4.5m should be accepted")


func test_path_segment_crossing_hazard_rejected() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)

	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)

	# Hazard at (5, 0, 1.0)
	var hazard := Node3D.new()
	add_child_autofree(hazard)
	hazard.global_position = Vector3(5.0, 0.0, 1.0)
	controller.test_hazards_override = [hazard]

	# Path segment from (0, 0, 0) to (10, 0, 0).
	# Distance from (5, 0, 1.0) to segment is 1.0m, which is < 2.5m.
	var path: PackedVector3Array = [Vector3(0.0, 0.0, 0.0), Vector3(10.0, 0.0, 0.0)]
	assert_false(controller.is_path_safe_from_hazards(path), "Path crossing within 1.0m of hazard should be rejected")


func test_path_segment_clearing_hazard_accepted() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)

	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)

	# Hazard at (5, 0, 4.0)
	var hazard := Node3D.new()
	add_child_autofree(hazard)
	hazard.global_position = Vector3(5.0, 0.0, 4.0)
	controller.test_hazards_override = [hazard]

	# Path segment from (0, 0, 0) to (10, 0, 0).
	# Distance from (5, 0, 4.0) to segment is 4.0m, which is >= 2.5m.
	var path: PackedVector3Array = [Vector3(0.0, 0.0, 0.0), Vector3(10.0, 0.0, 0.0)]
	assert_true(controller.is_path_safe_from_hazards(path), "Path 4.0m away from hazard should be accepted")


func test_candidate_pickup_in_hazard_radius_rejected() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	cart.global_position = Vector3(0.0, 0.0, 0.0)

	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)

	var hazard := Node3D.new()
	add_child_autofree(hazard)
	hazard.global_position = Vector3(5.0, 0.0, 0.0)
	controller.test_hazards_override = [hazard]

	var pA := Pickup.new()
	add_child_autofree(pA)
	var itemA := ItemData.new()
	itemA.value = 50
	itemA.item_id = 1
	pA.item = itemA
	pA.global_position = Vector3(5.0, 0.0, 0.0)

	var pB := Pickup.new()
	add_child_autofree(pB)
	var itemB := ItemData.new()
	itemB.value = 10
	itemB.item_id = 2
	pB.item = itemB
	pB.global_position = Vector3(0.0, 0.0, 8.0)

	controller.test_pickups_override = [pA, pB]
	RoundManager.time_left = 60.0
	controller._evaluate_decisions()

	assert_eq(controller.target_position, pB.global_position, "Pickup A in hazard should be skipped in favor of safe Pickup B")


func test_candidate_pickup_with_blocked_path_rejected() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	cart.global_position = Vector3(0.0, 0.0, 0.0)

	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)

	# Hazard in the middle of path to A: at (5, 0, 0)
	var hazard := Node3D.new()
	add_child_autofree(hazard)
	hazard.global_position = Vector3(5.0, 0.0, 0.0)
	controller.test_hazards_override = [hazard]

	# Pickup A is at (10, 0, 0) -> 5m away from hazard, but direct path crosses (5, 0, 0)
	var pA := Pickup.new()
	add_child_autofree(pA)
	var itemA := ItemData.new()
	itemA.value = 50
	itemA.item_id = 1
	pA.item = itemA
	pA.global_position = Vector3(10.0, 0.0, 0.0)

	var pB := Pickup.new()
	add_child_autofree(pB)
	var itemB := ItemData.new()
	itemB.value = 10
	itemB.item_id = 2
	pB.item = itemB
	pB.global_position = Vector3(0.0, 0.0, 8.0)

	controller.test_pickups_override = [pA, pB]
	RoundManager.time_left = 60.0
	controller._evaluate_decisions()

	assert_eq(controller.target_position, pB.global_position, "Pickup A with hazard on path should be rejected for safe Pickup B")


func test_chasing_rival_in_hazard_rejected() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	cart.cart_id = 0
	cart.global_position = Vector3.ZERO
	RoundManager.register_cart(cart)

	var controller := BotController.new()
	controller.cart = cart
	controller.current_aggression = 1.0
	controller._randf_override = 0.0
	add_child_autofree(controller)

	# Loaded rival in hazard
	var rival := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(rival)
	rival.cart_id = 1
	rival.global_position = Vector3(10.0, 0.0, 0.0)
	for i in range(12):
		var item := ItemData.new()
		item.item_id = 100 + i
		item.value = 10
		rival.try_add_item(item)
	RoundManager.register_cart(rival)

	var hazard := Node3D.new()
	add_child_autofree(hazard)
	hazard.global_position = Vector3(10.0, 0.0, 0.0)
	controller.test_hazards_override = [hazard]

	RoundManager.time_left = 60.0
	controller._evaluate_decisions()

	assert_ne(controller.state, BotController.AIState.CHASING, "Should not chase rival inside hazard")


func test_all_pickups_blocked_coasts_safely() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	cart.global_position = Vector3.ZERO

	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)

	var hazard := Node3D.new()
	add_child_autofree(hazard)
	hazard.global_position = Vector3(5.0, 0.0, 0.0)
	controller.test_hazards_override = [hazard]

	var pA := Pickup.new()
	add_child_autofree(pA)
	var itemA := ItemData.new()
	itemA.value = 50
	itemA.item_id = 1
	pA.item = itemA
	pA.global_position = Vector3(5.0, 0.0, 0.0)

	controller.test_pickups_override = [pA]
	RoundManager.time_left = 60.0
	controller._evaluate_decisions()

	assert_eq(controller.target_position, Vector3.ZERO, "When all pickups are blocked, target should be ZERO")
	var cmd := controller.build_command(0.016)
	assert_eq(cmd.throttle, 0.0, "Should coast with 0 throttle when no safe target")
	assert_eq(cmd.boost, false, "Should not boost when no safe target")


func test_slip_spin_neutralizes_commands() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	cart.global_position = Vector3.ZERO

	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)

	RoundManager.phase = GameTypes.Phase.RUSH
	RoundManager.round_started.emit(1)

	controller.target_position = Vector3(0.0, 0.0, 10.0)

	# Active slip
	cart.apply_slip(3.0)

	var cmd := controller.build_command(0.016)
	assert_eq(cmd.throttle, 0.0, "Throttle should be 0.0 during slip spin")
	assert_eq(cmd.brake, 0.0, "Brake should be 0.0 during slip spin")
	assert_eq(cmd.steer, 0.0, "Steer should be 0.0 during slip spin")
	assert_eq(cmd.boost, false, "Boost should be false during slip spin")


func test_slip_expiration_restores_commands() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	cart.global_position = Vector3.ZERO

	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)

	RoundManager.phase = GameTypes.Phase.RUSH
	RoundManager.round_started.emit(1)

	controller.target_position = Vector3(0.0, 0.0, 10.0)

	cart.apply_slip(0.1)
	var cmd := controller.build_command(0.016)
	assert_eq(cmd.throttle, 0.0, "Should be neutralized initially during slip")

	# Advance cart physics to let slip expire
	cart._physics_process(0.2)

	var resumed_cmd := controller.build_command(0.016)
	assert_gt(resumed_cmd.throttle, 0.0, "Throttle should resume once slip expires")


func test_immediate_reroute_on_threatening_hazard_spawn() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	cart.global_position = Vector3.ZERO

	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)

	RoundManager.phase = GameTypes.Phase.RUSH
	RoundManager.round_started.emit(1)

	var pA := Pickup.new()
	add_child_autofree(pA)
	var itemA := ItemData.new()
	itemA.value = 50
	itemA.item_id = 1
	pA.item = itemA
	pA.global_position = Vector3(10.0, 0.0, 0.0)

	var pB := Pickup.new()
	add_child_autofree(pB)
	var itemB := ItemData.new()
	itemB.value = 10
	itemB.item_id = 2
	pB.item = itemB
	pB.global_position = Vector3(0.0, 0.0, 10.0)

	controller.test_pickups_override = [pA, pB]
	controller._evaluate_decisions()
	assert_eq(controller.target_position, pA.global_position, "Initially targets Pickup A")

	# Stop decision timer to verify reaction is immediate upon hazard_spawned
	controller.decision_timer.stop()

	# Spawn hazard along path to Pickup A
	var hazard := Node3D.new()
	add_child_autofree(hazard)
	hazard.global_position = Vector3(5.0, 0.0, 0.0)
	RoundManager.hazard_spawned.emit(hazard)

	assert_eq(controller.target_position, pB.global_position, "Should immediately reroute to Pickup B on threatening hazard spawn")


func test_distant_hazard_spawn_does_not_interrupt_target() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	cart.global_position = Vector3.ZERO

	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)

	RoundManager.phase = GameTypes.Phase.RUSH
	RoundManager.round_started.emit(1)

	var pA := Pickup.new()
	add_child_autofree(pA)
	var itemA := ItemData.new()
	itemA.value = 50
	itemA.item_id = 1
	pA.item = itemA
	pA.global_position = Vector3(10.0, 0.0, 0.0)

	controller.test_pickups_override = [pA]
	controller._evaluate_decisions()
	assert_eq(controller.active_target, pA, "Initially targets Pickup A")

	controller.decision_timer.stop()

	# Spawn distant hazard that does not intersect route
	var distant_hazard := Node3D.new()
	add_child_autofree(distant_hazard)
	distant_hazard.global_position = Vector3(0.0, 0.0, -20.0)
	RoundManager.hazard_spawned.emit(distant_hazard)

	assert_eq(controller.active_target, pA, "Distant hazard should not interrupt or clear target")


func test_hazard_despawn_triggers_reevaluation_if_holding() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	cart.global_position = Vector3.ZERO

	var controller := BotController.new()
	controller.cart = cart
	add_child_autofree(controller)

	RoundManager.phase = GameTypes.Phase.RUSH
	RoundManager.round_started.emit(1)

	var pA := Pickup.new()
	add_child_autofree(pA)
	var itemA := ItemData.new()
	itemA.value = 50
	itemA.item_id = 1
	pA.item = itemA
	pA.global_position = Vector3(5.0, 0.0, 0.0)

	var hazard := Node3D.new()
	add_child(hazard)
	hazard.global_position = Vector3(5.0, 0.0, 0.0)
	RoundManager.hazard_spawned.emit(hazard)

	controller.test_pickups_override = [pA]
	controller._evaluate_decisions()
	assert_eq(controller.target_position, Vector3.ZERO, "Initially holding because all pickups are blocked")

	controller.decision_timer.stop()

	# Despawn the blocking hazard
	hazard.queue_free()
	await wait_physics_frames(2)

	assert_eq(controller.target_position, pA.global_position, "Despawn should trigger reevaluation and target unblocked pickup")



