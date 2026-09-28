extends GutTest
## Greybox Store layout contract (docs/features/store/01-greybox-store/01-spec.md).

const STORE_SCENE: PackedScene = preload("res://systems/store/store.tscn")
const CATEGORY_NAMES: Array[String] = [
	"Produce",
	"Bakery",
	"Dairy",
	"Snacks",
	"Frozen",
	"Electronics",
]

var _store: Store


func before_each() -> void:
	_store = STORE_SCENE.instantiate()
	add_child_autofree(_store)


func test_store_has_six_named_category_regions() -> void:
	var aisles := _store.get_node("Aisles")
	assert_eq(aisles.get_child_count(), CATEGORY_NAMES.size())
	for index: int in CATEGORY_NAMES.size():
		var aisle := aisles.get_child(index)
		assert_eq(aisle.name, CATEGORY_NAMES[index])
		assert_true(aisle.is_in_group("item_spawn_regions"), "%s is a spawn region" % aisle.name)


func test_store_has_four_distinct_start_transforms_facing_inside() -> void:
	var starts: Array[Transform3D] = _store.get_start_transforms()
	assert_eq(starts.size(), 4)
	var origins: Array[Vector3] = []
	for start: Transform3D in starts:
		assert_false(origins.has(start.origin), "start positions do not overlap")
		origins.append(start.origin)
		var forward: Vector3 = start.basis * Vector3.FORWARD
		assert_lt(forward.z, 0.0, "cart forward (-Z) points into the store")


func test_world_bodies_and_checkout_use_contract_layers() -> void:
	var world_bodies := get_tree().get_nodes_in_group("store_world")
	assert_gt(world_bodies.size(), 0)
	for body: Node in world_bodies:
		assert_true(body is StaticBody3D)
		assert_eq((body as StaticBody3D).collision_layer, 1)

	var checkout := _store.get_node("CheckoutZone") as Area3D
	assert_eq(checkout.collision_layer, 16, "checkout is on zones layer 5")
	assert_eq(checkout.collision_mask, 2, "checkout detects carts on layer 2")


func test_checkout_position_is_available_to_store_and_round_manager() -> void:
	var expected := (_store.get_node("CheckoutZone") as Node3D).global_position
	assert_eq(_store.get_checkout_position(), expected)
	assert_eq(RoundManager.get_checkout_position(), expected)


func test_navigation_region_has_a_baked_mesh() -> void:
	await wait_physics_frames(2)
	var region := _store.get_node("NavigationRegion3D") as NavigationRegion3D
	assert_not_null(region)
	assert_not_null(region.navigation_mesh)
	assert_gt(region.navigation_mesh.get_polygon_count(), 0, "navigation mesh contains walkable polygons")


func test_every_start_can_reach_every_aisle_and_checkout() -> void:
	await wait_physics_frames(2)
	await wait_seconds(0.1)
	var region := _store.get_node("NavigationRegion3D") as NavigationRegion3D
	var map: RID = region.get_navigation_map()
	var targets: Array[Vector3] = []
	for aisle: Node in _store.get_node("Aisles").get_children():
		targets.append((aisle as Node3D).global_position + Vector3(0.0, 0.0, -8.0))
	targets.append(_store.get_checkout_position())

	for start: Transform3D in _store.get_start_transforms():
		for target: Vector3 in targets:
			var path: PackedVector3Array = NavigationServer3D.map_get_path(map, start.origin, target, true)
			assert_gt(path.size(), 1, "route exists from %s to %s" % [start.origin, target])


func test_navigation_paths_do_not_cross_shelves() -> void:
	await wait_physics_frames(2)
	await wait_seconds(0.1)
	var region := _store.get_node("NavigationRegion3D") as NavigationRegion3D
	var map: RID = region.get_navigation_map()
	var start: Vector3 = _store.get_start_transforms()[0].origin
	var target := Vector3(Store.AISLE_X_POSITIONS[0], 0.0, -11.0)
	var path: PackedVector3Array = NavigationServer3D.map_get_path(map, start, target, true)
	assert_gt(path.size(), 1)
	for point: Vector3 in path:
		for body: Node in get_tree().get_nodes_in_group("store_shelves"):
			var shelf := body as StaticBody3D
			var shape := shelf.get_node("CollisionShape3D") as CollisionShape3D
			var box := shape.shape as BoxShape3D
			var bounds := AABB(shelf.global_position - box.size * 0.5, box.size)
			assert_false(bounds.has_point(point), "path point %s stays outside shelf %s" % [point, shelf.name])
