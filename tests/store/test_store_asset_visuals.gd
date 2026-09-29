extends GutTest
## Production Store must show Evan's visuals without replacing Store behavior.

const STORE_SCENE: PackedScene = preload("res://systems/store/store.tscn")

var _store: Store


func before_each() -> void:
	_store = STORE_SCENE.instantiate()
	add_child_autofree(_store)


func test_production_store_instances_the_authored_visual_composition() -> void:
	var visuals := _store.get_node_or_null("ProductionStoreVisuals") as Node3D
	assert_not_null(visuals)
	assert_not_null(visuals.get_node_or_null("StoreShellVisual"))
	assert_not_null(visuals.get_node_or_null("AislesVisual"))
	assert_not_null(visuals.get_node_or_null("CelebrationSet"))
	assert_not_null(visuals.get_node_or_null("ParkingCars"))
	assert_almost_eq((visuals.get_node("AislesVisual") as Node3D).position.z, -5.0, 0.001)


func test_six_cars_stay_in_outer_parking_rows() -> void:
	var parking_cars := _store.get_node("ProductionStoreVisuals/ParkingCars") as Node3D
	assert_eq(parking_cars.get_child_count(), 6)
	var model_counts: Dictionary[String, int] = {
		"Hatchback": 0,
		"Sedan": 0,
		"SUV": 0,
	}
	for car_node: Node in parking_cars.get_children():
		var car := car_node as Node3D
		assert_gte(absf(car.position.x), 22.5, "cars stay outside the center approach")
		assert_true(is_equal_approx(car.position.z, 12.95) or is_equal_approx(car.position.z, 27.05))
		assert_almost_eq(car.position.y, 0.0, 0.001, "car roots touch the parking plane")
		if "Hatchback" in car.name:
			model_counts["Hatchback"] += 1
		elif "Sedan" in car.name:
			model_counts["Sedan"] += 1
		elif "SUV" in car.name:
			model_counts["SUV"] += 1
	assert_eq(model_counts["Hatchback"], 2)
	assert_eq(model_counts["Sedan"], 2)
	assert_eq(model_counts["SUV"], 2)


func test_art_composition_is_visual_only() -> void:
	var visuals := _store.get_node("ProductionStoreVisuals") as Node3D
	assert_null(visuals.get_script())
	assert_eq(visuals.find_children("*", "CollisionObject3D", true, false).size(), 0)
	assert_eq(visuals.find_children("*", "CollisionShape3D", true, false).size(), 0)
	assert_eq(visuals.find_children("*", "Light3D", true, false).size(), 0)


func test_placeholder_art_is_hidden_but_gameplay_collisions_stay_active() -> void:
	var floor_body := _store.get_node("Floor") as StaticBody3D
	var floor_visual := floor_body.get_node("Visual") as MeshInstance3D
	var floor_shape := floor_body.get_node("CollisionShape3D") as CollisionShape3D
	assert_false(floor_visual.visible)
	assert_false(floor_shape.disabled)

	var shelf := _store.get_node("Aisles/Produce/LeftShelf") as StaticBody3D
	var shelf_visual := shelf.get_node("Visual") as MeshInstance3D
	var shelf_shape := shelf.get_node("CollisionShape3D") as CollisionShape3D
	assert_false(shelf_visual.visible)
	assert_false(shelf_shape.disabled)
	assert_false((_store.get_node("Aisles/Produce/Sign") as MeshInstance3D).visible)

	var door_visual := _store.get_node("Doors/LeftDoor/Body/Visual") as MeshInstance3D
	var checkout_visual := _store.get_node("CheckoutZone/Visual") as MeshInstance3D
	assert_true(door_visual.visible, "phase-driven door panels remain visible")
	assert_true(checkout_visual.visible, "checkout marker remains visible")
	assert_eq((_store.get_node("Aisles") as Node3D).get_child_count(), 6)


func test_cart_starts_fit_through_the_open_doorway() -> void:
	const DOORWAY_HALF_WIDTH := 4.0
	const CART_HALF_WIDTH := 0.4
	for start: Transform3D in _store.get_start_transforms():
		assert_almost_eq(start.origin.z, 11.5, 0.001, "cart starts outside the closed doors")
		assert_true(
			absf(start.origin.x) + CART_HALF_WIDTH <= DOORWAY_HALF_WIDTH,
			"cart start %s fits through the open doorway" % start.origin
		)


func test_collision_floor_and_walls_follow_store_shell_bounds() -> void:
	var floor_body := _store.get_node("Floor") as StaticBody3D
	var floor_shape := floor_body.get_node("CollisionShape3D") as CollisionShape3D
	var floor_box := floor_shape.shape as BoxShape3D
	assert_true(floor_box.size.is_equal_approx(Vector3(50.5, 0.2, 30.5)))
	assert_true(floor_body.position.is_equal_approx(Vector3(0.0, -0.1, -5.0)))
	var parking_floor := _store.get_node("ParkingLotFloor") as StaticBody3D
	var parking_box := (parking_floor.get_node("CollisionShape3D") as CollisionShape3D).shape as BoxShape3D
	assert_true(parking_box.size.is_equal_approx(Vector3(60.0, 0.2, 39.5)))
	assert_true(parking_floor.position.is_equal_approx(Vector3(0.0, -0.1, 20.125)))
	assert_almost_eq((_store.get_node("LeftWall") as StaticBody3D).position.x, -25.25, 0.001)
	assert_almost_eq((_store.get_node("RightWall") as StaticBody3D).position.x, 25.25, 0.001)
	assert_almost_eq((_store.get_node("BackWall") as StaticBody3D).position.z, -20.0, 0.001)


func test_shelf_collisions_center_on_the_authored_aisle_fixtures() -> void:
	var aisle_centers: Array[float] = [-18.75, -11.25, -3.75, 3.75, 11.25, 18.75]
	var fixture_offsets: Array[float] = [3.025, 2.975, 3.28, 3.28, 3.26, 3.28]
	var fixture_widths: Array[float] = [1.45, 1.55, 0.94, 1.0, 0.98, 1.02]
	var aisle_nodes: Node3D = _store.get_node("Aisles") as Node3D
	assert_eq(aisle_nodes.get_child_count(), aisle_centers.size())
	for index: int in aisle_centers.size():
		var aisle := aisle_nodes.get_child(index) as Node3D
		assert_almost_eq(aisle.position.x, aisle_centers[index], 0.001)
		for side: int in 2:
			var shelf_name := "LeftShelf" if side == 0 else "RightShelf"
			var shelf := aisle.get_node(shelf_name) as StaticBody3D
			var expected_side := -1.0 if side == 0 else 1.0
			assert_almost_eq(shelf.position.x, expected_side * fixture_offsets[index], 0.001)
			assert_almost_eq(shelf.position.z, -5.0, 0.001)
			var box := (shelf.get_node("CollisionShape3D") as CollisionShape3D).shape as BoxShape3D
			assert_almost_eq(box.size.x, fixture_widths[index], 0.001)
			assert_almost_eq(box.size.z, 14.0, 0.001)


func test_cart_shape_hits_fixture_but_fits_in_the_walkable_aisle() -> void:
	await wait_physics_frames(2)
	var cart_shape := BoxShape3D.new()
	cart_shape.size = Vector3(0.8, 1.0, 1.2)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = cart_shape
	query.collision_mask = 1
	var space: PhysicsDirectSpaceState3D = _store.get_world_3d().direct_space_state
	var shelf := _store.get_node("Aisles/Produce/LeftShelf") as StaticBody3D
	query.transform = Transform3D(Basis.IDENTITY, shelf.global_position + Vector3.UP * 0.5)
	assert_gt(space.intersect_shape(query, 8).size(), 0, "a cart-sized body contacts the visible fixture")
	var aisle := _store.get_node("Aisles/Produce") as Node3D
	query.transform = Transform3D(Basis.IDENTITY, aisle.global_position + Vector3(0.0, 1.2, -5.0))
	assert_eq(space.intersect_shape(query, 8).size(), 0, "a cart-sized body fits between the fixture rows")
