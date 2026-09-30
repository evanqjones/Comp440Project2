extends GutTest
## Bigger carts and floor items (docs/features/cart/10-bigger-carts-and-items/FEATURE.md, D-031).

const CART_SCENE := "res://systems/cart/cart.tscn"
const BASE_BOX := Vector3(0.8, 1.0, 1.2)


func _make_cart() -> Cart:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	return cart


func test_size_scale_is_one_point_three() -> void:
	assert_eq(Cart.SIZE_SCALE, 1.3)


func test_collision_box_grows_with_the_scale() -> void:
	var cart := _make_cart()
	var shape := cart.get_node("CollisionShape3D") as CollisionShape3D
	var box := shape.shape as BoxShape3D
	assert_almost_eq(box.size, BASE_BOX * Cart.SIZE_SCALE, Vector3.ONE * 0.001, "1.04 x 1.3 x 1.56 m")
	assert_almost_eq(shape.position.y, box.size.y / 2.0, 0.001, "box sits on the floor")


func test_visual_is_scaled_to_match() -> void:
	var cart := _make_cart()
	var visual := cart.get_node("Visual") as Node3D
	assert_almost_eq(visual.scale, Vector3.ONE * Cart.SIZE_SCALE, Vector3.ONE * 0.001)


func test_name_tag_keeps_its_old_size_so_tags_at_the_start_line_dont_overlap() -> void:
	var cart := _make_cart()
	var tag := cart.get_node("Visual/NameTag") as Node3D
	assert_almost_eq(tag.global_basis.get_scale(), Vector3.ONE, Vector3.ONE * 0.001, "Visual 1.3x cancelled on the tag")


func test_tip_over_keeps_the_scale_and_pivots_on_the_scaled_edge() -> void:
	var cart := _make_cart()
	var visual := cart.get_node("Visual") as Node3D
	CartStealEffects._apply_tip(visual, 1.0)
	assert_almost_eq(visual.basis.get_scale(), Vector3.ONE * Cart.SIZE_SCALE, Vector3.ONE * 0.001, "still 1.3x on its side")
	assert_almost_eq(visual.rotation.z, deg_to_rad(90.0), 0.001, "rolled onto its side")
	var edge := Vector3(-0.4 * Cart.SIZE_SCALE, 0.0, 0.0)
	var edge_local := edge / Cart.SIZE_SCALE
	assert_almost_eq(visual.transform * edge_local, edge, Vector3.ONE * 0.001, "the bottom edge stays put")


func test_reset_leaves_it_upright_at_the_scale() -> void:
	var cart := _make_cart()
	var visual := cart.get_node("Visual") as Node3D
	CartStealEffects._apply_tip(visual, 0.6)
	CartStealEffects.reset(cart)
	assert_almost_eq(visual.scale, Vector3.ONE * Cart.SIZE_SCALE, Vector3.ONE * 0.001)
	assert_almost_eq(visual.rotation, Vector3.ZERO, Vector3.ONE * 0.001, "upright")
	assert_almost_eq(visual.position, Vector3.ZERO, Vector3.ONE * 0.001)


func test_pickup_is_one_point_six_times_bigger_with_a_wider_trigger() -> void:
	var pickup := (load("res://systems/store/pickup.tscn") as PackedScene).instantiate() as Pickup
	add_child_autofree(pickup)
	var visual := pickup.get_node("Visual") as Node3D
	assert_almost_eq(visual.scale, Vector3.ONE * 1.6, Vector3.ONE * 0.001, "item model 1.6x")
	var sphere := (pickup.get_node("CollisionShape3D") as CollisionShape3D).shape as SphereShape3D
	assert_almost_eq(sphere.radius, 0.96, 0.001, "trigger 0.6 m x 1.6")
