extends GutTest
## The shopper pushing every cart: Evan's animated model driven by cart state
## (docs/features/cart/05-evan-shopper/FEATURE.md; earlier box placeholder: cart/03-shopper).

const CART_SCENE := "res://systems/cart/cart.tscn"


func _make_cart(profile_name := "") -> Cart:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	if profile_name != "":
		cart.profile = load("res://systems/shared/profiles/%s.tres" % profile_name)
	add_child_autofree(cart)
	return cart


func test_every_cart_has_evans_model_with_its_clips() -> void:
	var model := _make_cart().get_node_or_null("Visual/ShopperModel") as Node3D
	assert_not_null(model, "cart.tscn has Visual/ShopperModel")
	if model == null:
		return
	var players := model.find_children("*", "AnimationPlayer", true, false)
	assert_eq(players.size(), 1, "the model has one AnimationPlayer")
	if players.is_empty():
		return
	var clips := []
	for full_name: StringName in (players[0] as AnimationPlayer).get_animation_list():
		clips.append(String(full_name).get_slice("|", 1).to_lower())
	for needed: String in ["idle", "walk", "turn", "backwards", "hit"]:
		assert_has(clips, needed, "clip %s is present" % needed)


func test_shopper_is_visual_only() -> void:
	var model := _make_cart().get_node_or_null("Visual/ShopperModel")
	assert_not_null(model)
	if model == null:
		return
	var bodies := model.find_children("*", "CollisionObject3D", true, false)
	var shapes := model.find_children("*", "CollisionShape3D", true, false)
	assert_eq(bodies.size() + shapes.size(), 0, "no collision on the shopper model")


func test_box_placeholders_are_hidden() -> void:
	var cart := _make_cart()
	for path: String in ["Visual/PlaceholderMesh", "Visual/Nose", "Visual/Shopper"]:
		var node := cart.get_node_or_null(path) as Node3D
		assert_not_null(node, "%s kept (Evan's preview references it)" % path)
		if node != null:
			assert_false(node.visible, "%s is hidden" % path)


func test_cart_collision_box_unchanged() -> void:
	var cart := _make_cart()
	var box := (cart.get_node("CollisionShape3D") as CollisionShape3D).shape as BoxShape3D
	assert_eq(box.size, Vector3(0.8, 1.0, 1.2), "cart box is still 0.8 x 1.0 x 1.2 m")
	assert_eq(cart.find_children("*", "CollisionShape3D", true, false).size(), 1, "still one collision box")


func test_shirt_tinted_with_profile_color() -> void:
	var cart := _make_cart("carl")
	var shirt: Variant = _find_surface(cart.get_node("Visual/ShopperModel"), "Petrol blue cotton")
	assert_not_null(shirt, "found a shirt surface")
	if shirt == null:
		return
	var mesh: MeshInstance3D = shirt[0]
	var surface: int = shirt[1]
	var override := mesh.get_surface_override_material(surface) as BaseMaterial3D
	assert_not_null(override, "shirt has an override material")
	if override != null:
		assert_eq(override.albedo_color, cart.profile.color, "shirt is Carl's teal")


func test_pick_clip_rules() -> void:
	assert_eq(CartShopperAnimator.pick_clip(0.0, 0.0, false), "idle")
	assert_eq(CartShopperAnimator.pick_clip(5.0, 0.0, false), "walk")
	assert_eq(CartShopperAnimator.pick_clip(5.0, 1.5, false), "turn")
	assert_eq(CartShopperAnimator.pick_clip(5.0, -1.5, false), "turn", "left turns use the (mirrored) turn clip")
	assert_eq(CartShopperAnimator.pick_clip(-2.0, 0.0, false), "backwards")
	assert_eq(CartShopperAnimator.pick_clip(0.0, 3.0, false), "idle", "pivoting in place without moving is idle")
	assert_eq(CartShopperAnimator.pick_clip(8.0, 0.0, true), "stunned", "stunned beats everything")


func test_items_ride_in_the_animated_basket() -> void:
	var cart := _make_cart()
	var animator := cart.get_node_or_null("ShopperAnimator") as CartShopperAnimator
	var stack := cart.get_node("ItemStackDisplay") as Node3D
	var skeleton := cart.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	assert_not_null(animator, "cart.tscn has a ShopperAnimator")
	if animator == null:
		return
	var basket := skeleton.find_bone("CART")
	assert_gt(basket, -1, "Evan's rig has the CART bone the basket is skinned to")
	var before := stack.position
	# Swing the basket sideways the way Evan's turn clip does.
	skeleton.set_bone_pose_rotation(basket, skeleton.get_bone_pose_rotation(basket) * Quaternion(Vector3.UP, 0.4))
	animator._follow_basket()
	assert_gt(stack.position.distance_to(before), 0.05, "the item cubes moved with the basket")


## [MeshInstance3D, surface index] of the first surface using `material_name`, or null.
func _find_surface(root: Node, material_name: String) -> Variant:
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		for s: int in mesh.mesh.get_surface_count():
			var material := mesh.mesh.surface_get_material(s)
			if material != null and material.resource_name == material_name:
				return [mesh, s]
	return null
