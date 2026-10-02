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
