class_name CartShopperMerge
extends RefCounted
## Merges Evan's shopper into one skinned mesh (docs/features/cart/11-shopper-merge/FEATURE.md).
## The FBX imports as 186 separate skinned parts, each rigidly bound to one bone, which the renderer
## skins and draws one by one: about 1,400 draw calls for four shoppers, and the main cause of the
## web build's lag. This rebuilds them as ONE MeshInstance3D on the same skeleton with one surface
## per material (12), so the animations, the look and the per-cart tint stay the same. The merged
## mesh and skin are built once and shared by every cart.

## Merged results, keyed by the source parts (every cart instances the same imported meshes).
static var _cache: Dictionary = {}


## Replace the skinned parts under `skeleton` with one merged MeshInstance3D and return it.
## Returns null (and changes nothing) unless there are 2+ parts, every one rigid (each vertex fully
## on a single bone, all of a part's vertices on the same bone) and made of triangles.
static func merge(skeleton: Skeleton3D) -> MeshInstance3D:
	var parts: Array[MeshInstance3D] = []
	for child: Node in skeleton.get_children():
		var part := child as MeshInstance3D
		if part != null and part.mesh != null and part.skin != null:
			parts.append(part)
	if parts.size() < 2:
		return null
	var key := "%d:%d:%d" % [parts[0].mesh.get_instance_id(), parts.size(), skeleton.get_bone_count()]
	if not _cache.has(key):
		var built := _build(skeleton, parts)
		if built.is_empty():
			return null
		_cache[key] = built
	var entry: Dictionary = _cache[key]
	var merged := MeshInstance3D.new()
	merged.name = "MergedShopper"
	merged.mesh = entry["mesh"]
	merged.skin = entry["skin"]
	merged.extra_cull_margin = 1.0 # animated poses swing a little past the rest-pose bounds
	merged.cast_shadow = parts[0].cast_shadow
	skeleton.add_child(merged)
	merged.skeleton = merged.get_path_to(skeleton) # the default path is empty: unbound, it would render unposed
	for part: MeshInstance3D in parts:
		skeleton.remove_child(part)
		part.queue_free()
	return merged


## Where every vertex of every skinned part under `skeleton` sits in skeleton space right now
## (rigid parts: the vertex's heaviest bind). For tests comparing merged and original shoppers.
static func skinned_points(skeleton: Skeleton3D) -> PackedVector3Array:
	var points := PackedVector3Array()
	for child: Node in skeleton.get_children():
		var part := child as MeshInstance3D
		if part == null or part.mesh == null or part.skin == null or part.is_queued_for_deletion():
			continue
		for surface: int in part.mesh.get_surface_count():
			var arrays := part.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var per := bones.size() / maxi(1, vertices.size())
			for i: int in vertices.size():
				var bind := _heaviest(bones, weights, i, per)
				var bone := _bone_for_bind(skeleton, part.skin, bind)
				var pose := skeleton.get_bone_global_pose(bone) * part.skin.get_bind_pose(bind)
				points.append(pose * vertices[i])
	return points


static func _build(skeleton: Skeleton3D, parts: Array[MeshInstance3D]) -> Dictionary:
	var bone_count := skeleton.get_bone_count()
	var binds: Array[Transform3D] = []
	var has_bind: Array[bool] = []
	binds.resize(bone_count)
	has_bind.resize(bone_count)
	for b: int in bone_count:
		binds[b] = Transform3D.IDENTITY
		has_bind[b] = false
	var groups: Dictionary = {} # material -> surface buffers
	var order: Array = []
	for part: MeshInstance3D in parts:
		for surface: int in part.mesh.get_surface_count():
			if part.mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
				return {}
			var arrays := part.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			if arrays[Mesh.ARRAY_BONES] == null or arrays[Mesh.ARRAY_WEIGHTS] == null or vertices.is_empty():
				return {}
			var bind := _rigid_bind(arrays[Mesh.ARRAY_BONES], arrays[Mesh.ARRAY_WEIGHTS], vertices.size())
			if bind < 0:
				return {}
			var bone := _bone_for_bind(skeleton, part.skin, bind)
			if bone < 0:
				return {}
			var part_bind := part.skin.get_bind_pose(bind)
			if not has_bind[bone]:
				binds[bone] = part_bind
				has_bind[bone] = true
			var material := part.mesh.surface_get_material(surface)
			if not groups.has(material):
				groups[material] = _new_buffers()
				order.append(material)
			_append(groups[material], arrays, bone, binds[bone].affine_inverse() * part_bind)
	var mesh := ArrayMesh.new()
	for material: Variant in order:
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _to_arrays(groups[material]))
		mesh.surface_set_material(mesh.get_surface_count() - 1, material as Material)
	var skin := Skin.new()
	for b: int in bone_count:
		skin.add_named_bind(skeleton.get_bone_name(b), binds[b])
	return {"mesh": mesh, "skin": skin}


## The single bind every vertex of a rigid part uses fully, or -1 if the part blends bones.
static func _rigid_bind(bones: PackedInt32Array, weights: PackedFloat32Array, count: int) -> int:
	var per := bones.size() / count
	var bind := -1
	for i: int in count:
		var heaviest := _heaviest(bones, weights, i, per)
		if weights[i * per + _heaviest_slot(weights, i, per)] < 0.999:
			return -1
		if bind == -1:
			bind = heaviest
		elif heaviest != bind:
			return -1
	return bind


static func _heaviest(bones: PackedInt32Array, weights: PackedFloat32Array, vertex: int, per: int) -> int:
	return bones[vertex * per + _heaviest_slot(weights, vertex, per)]


static func _heaviest_slot(weights: PackedFloat32Array, vertex: int, per: int) -> int:
	var best := 0
	for slot: int in per:
		if weights[vertex * per + slot] > weights[vertex * per + best]:
			best = slot
	return best


static func _bone_for_bind(skeleton: Skeleton3D, skin: Skin, bind: int) -> int:
	var bone_name := skin.get_bind_name(bind)
	return skeleton.find_bone(bone_name) if bone_name != "" else skin.get_bind_bone(bind)


static func _new_buffers() -> Dictionary:
	return {
		"vertex": PackedVector3Array(), "normal": PackedVector3Array(), "tangent": PackedFloat32Array(),
		"uv": PackedVector2Array(), "color": PackedColorArray(), "bones": PackedInt32Array(),
		"weights": PackedFloat32Array(), "index": PackedInt32Array(),
		"has_normal": false, "has_tangent": false, "has_uv": false, "has_color": false,
	}


## Append one rigid part surface to a material's buffers, moved into the unified bind of `bone`.
## (Packed arrays are values: work on locals and store them back.)
static func _append(buffers: Dictionary, arrays: Array, bone: int, to_unified: Transform3D) -> void:
	var source_vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var count := source_vertices.size()
	var vertex: PackedVector3Array = buffers["vertex"]
	var normal: PackedVector3Array = buffers["normal"]
	var tangent: PackedFloat32Array = buffers["tangent"]
	var uv: PackedVector2Array = buffers["uv"]
	var color: PackedColorArray = buffers["color"]
	var bones: PackedInt32Array = buffers["bones"]
	var weights: PackedFloat32Array = buffers["weights"]
	var index: PackedInt32Array = buffers["index"]
	var start := vertex.size()
	var identity := to_unified.is_equal_approx(Transform3D.IDENTITY)
	var normal_basis := to_unified.basis.inverse().transposed()
	var normals: Variant = arrays[Mesh.ARRAY_NORMAL]
	var tangents: Variant = arrays[Mesh.ARRAY_TANGENT]
	var uvs: Variant = arrays[Mesh.ARRAY_TEX_UV]
	var colors: Variant = arrays[Mesh.ARRAY_COLOR]
	# An attribute a part brings for the first time is back-filled for the parts before it.
	if normals != null and not buffers["has_normal"]:
		buffers["has_normal"] = true
		for i: int in start:
			normal.append(Vector3.UP)
	if tangents != null and not buffers["has_tangent"]:
		buffers["has_tangent"] = true
		for i: int in start:
			tangent.append_array([1.0, 0.0, 0.0, 1.0])
	if uvs != null and not buffers["has_uv"]:
		buffers["has_uv"] = true
		for i: int in start:
			uv.append(Vector2.ZERO)
	if colors != null and not buffers["has_color"]:
		buffers["has_color"] = true
		for i: int in start:
			color.append(Color.WHITE)
	for i: int in count:
		vertex.append(source_vertices[i] if identity else to_unified * source_vertices[i])
		if buffers["has_normal"]:
			normal.append(Vector3.UP if normals == null else ((normals as PackedVector3Array)[i] if identity else (normal_basis * (normals as PackedVector3Array)[i]).normalized()))
		if buffers["has_tangent"]:
			if tangents == null:
				tangent.append_array([1.0, 0.0, 0.0, 1.0])
			else:
				var source_tangents := tangents as PackedFloat32Array
				var t := Vector3(source_tangents[i * 4], source_tangents[i * 4 + 1], source_tangents[i * 4 + 2])
				if not identity:
					t = (to_unified.basis * t).normalized()
				tangent.append_array([t.x, t.y, t.z, source_tangents[i * 4 + 3]])
		if buffers["has_uv"]:
			uv.append(Vector2.ZERO if uvs == null else (uvs as PackedVector2Array)[i])
		if buffers["has_color"]:
			color.append(Color.WHITE if colors == null else (colors as PackedColorArray)[i])
		bones.append_array([bone, 0, 0, 0])
		weights.append_array([1.0, 0.0, 0.0, 0.0])
	if arrays[Mesh.ARRAY_INDEX] == null:
		for i: int in count:
			index.append(start + i)
	else:
		for source_index: int in (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array):
			index.append(start + source_index)
	buffers["vertex"] = vertex
	buffers["normal"] = normal
	buffers["tangent"] = tangent
	buffers["uv"] = uv
	buffers["color"] = color
	buffers["bones"] = bones
	buffers["weights"] = weights
	buffers["index"] = index


static func _to_arrays(buffers: Dictionary) -> Array:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = buffers["vertex"]
	if buffers["has_normal"]:
		arrays[Mesh.ARRAY_NORMAL] = buffers["normal"]
	if buffers["has_tangent"]:
		arrays[Mesh.ARRAY_TANGENT] = buffers["tangent"]
	if buffers["has_uv"]:
		arrays[Mesh.ARRAY_TEX_UV] = buffers["uv"]
	if buffers["has_color"]:
		arrays[Mesh.ARRAY_COLOR] = buffers["color"]
	arrays[Mesh.ARRAY_BONES] = buffers["bones"]
	arrays[Mesh.ARRAY_WEIGHTS] = buffers["weights"]
	arrays[Mesh.ARRAY_INDEX] = buffers["index"]
	return arrays
