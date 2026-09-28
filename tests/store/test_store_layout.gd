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
