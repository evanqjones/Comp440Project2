extends GutTest
## Box-placeholder shopper pushing every cart (docs/features/cart/03-shopper/FEATURE.md).

const CART_SCENE := "res://systems/cart/cart.tscn"


func _make_cart() -> Cart:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	return cart


func test_every_cart_has_a_shopper_behind_it() -> void:
	var shopper := _make_cart().get_node_or_null("Visual/Shopper") as Node3D
	assert_not_null(shopper, "cart.tscn has Visual/Shopper")
	if shopper == null:
		return
	assert_gt(shopper.position.z, 0.6, "stands behind the cart's back face (+Z is behind)")


func test_shopper_is_visual_only() -> void:
	var shopper := _make_cart().get_node_or_null("Visual/Shopper")
	assert_not_null(shopper)
	if shopper == null:
		return
	var bodies := shopper.find_children("*", "CollisionObject3D", true, false)
	var shapes := shopper.find_children("*", "CollisionShape3D", true, false)
	assert_eq(bodies.size() + shapes.size(), 0, "no collision on the shopper")


func test_cart_collision_box_unchanged() -> void:
	var cart := _make_cart()
	var box := (cart.get_node("CollisionShape3D") as CollisionShape3D).shape as BoxShape3D
	assert_eq(box.size, Vector3(0.8, 1.0, 1.2), "cart box is still 0.8 x 1.0 x 1.2 m")
	assert_eq(cart.find_children("*", "CollisionShape3D", true, false).size(), 1, "still one collision box")
