extends GutTest
## Shopper merge (docs/features/cart/11-shopper-merge/FEATURE.md): Evan's 186 rigid skinned parts
## become one skinned mesh with a surface per material, posed exactly like the originals.

const CART_SCENE := "res://systems/cart/cart.tscn"
const MODEL := "res://Blender/man_cart_godot.fbx"


func _make_cart() -> Cart:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	return cart


func _model() -> Node3D:
	var model := (load(MODEL) as PackedScene).instantiate() as Node3D
	add_child_autofree(model)
	return model


func _skeleton(root: Node) -> Skeleton3D:
	return root.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D


func _parts(skeleton: Skeleton3D) -> Array[MeshInstance3D]:
	var parts: Array[MeshInstance3D] = []
	for child: Node in skeleton.get_children():
		if child is MeshInstance3D and not child.is_queued_for_deletion():
			parts.append(child as MeshInstance3D)
	return parts


## Pose `model` at `seconds` into its `clip` ("turn", "walk", ...).
func _pose(model: Node3D, clip: String, seconds: float) -> void:
	var player := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for full_name: StringName in player.get_animation_list():
		if String(full_name).ends_with("|" + clip):
			player.play(full_name)
			player.seek(seconds, true)
	_skeleton(model).force_update_all_bone_transforms()


func _materials_and_vertices(skeleton: Skeleton3D) -> Array:
	var materials := {}
	var vertices := 0
	for part: MeshInstance3D in _parts(skeleton):
		for surface: int in part.mesh.get_surface_count():
			materials[part.mesh.surface_get_material(surface)] = true
			vertices += part.mesh.surface_get_array_len(surface)
	return [materials.size(), vertices]


func test_one_merged_mesh_with_a_surface_per_material() -> void:
	var original := _materials_and_vertices(_skeleton(_model()))
	assert_gt(original[0], 1, "Evan's model has several materials")
	var cart := _make_cart()
	var parts := _parts(_skeleton(cart.get_node("Visual/ShopperModel")))
	assert_eq(parts.size(), 1, "one merged mesh instead of 186 parts")
	if parts.size() != 1:
		return
	var merged := parts[0]
	assert_eq(merged.mesh.get_surface_count(), original[0], "one surface per material")
	assert_eq(_materials_and_vertices(_skeleton(cart.get_node("Visual/ShopperModel")))[1], original[1], "no vertices lost")
	assert_eq(merged.skin.get_bind_count(), _skeleton(cart).get_bone_count(), "one bind per skeleton bone")
	assert_eq(merged.get_node_or_null(merged.skeleton), _skeleton(cart), "bound to the shopper's skeleton (else it renders unposed)")


func test_merged_shopper_poses_exactly_like_the_parts() -> void:
	var original := _model()
	var merged := _model()
	assert_not_null(CartShopperMerge.merge(_skeleton(merged)), "merged")
	for clip_time: Array in [["turn", 0.5], ["walk", 0.3]]:
		_pose(original, clip_time[0], clip_time[1])
		_pose(merged, clip_time[0], clip_time[1])
		var a := CartShopperMerge.skinned_points(_skeleton(original))
		var b := CartShopperMerge.skinned_points(_skeleton(merged))
		assert_eq(a.size(), b.size(), "same vertex count")
		var box_a := AABB(a[0], Vector3.ZERO)
		var box_b := AABB(b[0], Vector3.ZERO)
		var sum_a := Vector3.ZERO
		var sum_b := Vector3.ZERO
		for i: int in a.size():
			box_a = box_a.expand(a[i])
			sum_a += a[i]
		for i: int in b.size():
			box_b = box_b.expand(b[i])
			sum_b += b[i]
		assert_almost_eq(box_b.position, box_a.position, Vector3.ONE * 0.001, "%s: same bounds (min)" % clip_time[0])
		assert_almost_eq(box_b.end, box_a.end, Vector3.ONE * 0.001, "%s: same bounds (max)" % clip_time[0])
		assert_almost_eq(sum_b / b.size(), sum_a / a.size(), Vector3.ONE * 0.001, "%s: same centroid" % clip_time[0])


func test_every_cart_shares_one_merged_mesh() -> void:
	var a := _parts(_skeleton(_make_cart().get_node("Visual/ShopperModel")))
	var b := _parts(_skeleton(_make_cart().get_node("Visual/ShopperModel")))
	assert_eq(a.size(), 1)
	assert_eq(b.size(), 1)
	if a.size() == 1 and b.size() == 1:
		assert_eq(a[0].mesh, b[0].mesh, "built once, shared")
		assert_eq(a[0].skin, b[0].skin)


func test_nothing_merges_when_a_part_is_not_rigid() -> void:
	var skeleton := Skeleton3D.new()
	skeleton.add_bone("a")
	skeleton.add_bone("b")
	add_child_autofree(skeleton)
	for i: int in 2:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.UP])
		arrays[Mesh.ARRAY_BONES] = PackedInt32Array([0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0])
		arrays[Mesh.ARRAY_WEIGHTS] = PackedFloat32Array([0.5, 0.5, 0, 0, 0.5, 0.5, 0, 0, 0.5, 0.5, 0, 0])
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var skin := Skin.new()
		skin.add_named_bind("a", Transform3D.IDENTITY)
		skin.add_named_bind("b", Transform3D.IDENTITY)
		var part := MeshInstance3D.new()
		part.mesh = mesh
		part.skin = skin
		skeleton.add_child(part)
	assert_null(CartShopperMerge.merge(skeleton), "blended weights: leave the parts alone")
	assert_eq(_parts(skeleton).size(), 2)
