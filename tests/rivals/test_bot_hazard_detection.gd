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
