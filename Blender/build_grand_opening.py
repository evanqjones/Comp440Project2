"""Build reusable Checkout Chaos grand-opening props in Assets.blend.

Run with Blender's background Python from the project root:
    blender --background Assets.blend --python Blender/build_grand_opening.py

Only the generated "CC Grand Opening" collection is replaced. Existing aisle
and cart content in the source file is preserved.
"""

import math
import os

import bpy
import bmesh


ROOT_NAME = "CC Grand Opening"
MESH_CACHE = {}
REPORT = {}


def srgb_component(value):
	value /= 255.0
	return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def rgba(hex_color):
	text = hex_color.lstrip("#")
	return tuple(srgb_component(int(text[index:index + 2], 16)) for index in (0, 2, 4)) + (1.0,)


def material(name, color, roughness=0.5, metallic=0.0):
	mat_name = "GOA_" + name
	mat = bpy.data.materials.get(mat_name) or bpy.data.materials.new(mat_name)
	mat.diffuse_color = rgba(color)
	mat.use_nodes = True
	shader = mat.node_tree.nodes.get("Principled BSDF")
	if shader:
		shader.inputs["Base Color"].default_value = rgba(color)
		shader.inputs["Roughness"].default_value = roughness
		shader.inputs["Metallic"].default_value = metallic
	return mat


def mesh_for(kind, mat):
	key = (kind, mat.name)
	if key in MESH_CACHE:
		return MESH_CACHE[key]
	bm = bmesh.new()
	if kind == "cube":
		bmesh.ops.create_cube(bm, size=1.0)
	elif kind == "sphere":
		bmesh.ops.create_uvsphere(bm, u_segments=12, v_segments=8, radius=1.0)
	elif kind == "sphere_low":
		bmesh.ops.create_uvsphere(bm, u_segments=8, v_segments=6, radius=1.0)
	elif kind == "cylinder":
		bmesh.ops.create_cone(bm, segments=10, radius1=0.5, radius2=0.5, depth=1.0, cap_ends=True)
	else:
		bm.free()
		raise ValueError("Unknown mesh kind: " + kind)
	mesh = bpy.data.meshes.new("GOA_" + kind + "_" + mat.name)
	bm.to_mesh(mesh)
	bm.free()
	mesh.materials.append(mat)
	MESH_CACHE[key] = mesh
	return mesh


def add_shape(name, kind, location, dimensions, mat, col, bevel=0.0, rotation=None):
	obj = bpy.data.objects.new(name, mesh_for(kind, mat))
	col.objects.link(obj)
	obj.location = location
	obj.dimensions = dimensions
	if rotation is not None:
		obj.rotation_euler = rotation
	if bevel > 0.0:
		modifier = obj.modifiers.new("Soft low-poly edges", "BEVEL")
		modifier.width = bevel
		modifier.segments = 1
		modifier.limit_method = "ANGLE"
	return obj


def add_text(body, location, size, mat, col):
	curve = bpy.data.curves.new("GOA_sign_text", "FONT")
	curve.body = body
	curve.size = size
	curve.extrude = 0.0
	curve.resolution_u = 2
	curve.align_x = "CENTER"
	curve.align_y = "CENTER"
	obj = bpy.data.objects.new("Sign " + body, curve)
	col.objects.link(obj)
	obj.location = location
	# The text faces Blender -Y, which is the front (+Z) in the Godot export.
	obj.rotation_euler = (math.pi / 2.0, 0.0, 0.0)
	curve.materials.append(mat)
	return obj


def new_collection(name, parent):
	col = bpy.data.collections.new(name)
	parent.children.link(col)
	return col


def build_banner(parent, mats):
	col = new_collection("Grand Opening Banner", parent)
	# An 8 m door opening remains mostly unobstructed, with a 2.8 m clear height.
	for side in (-1, 1):
		x = side * 3.78
		add_shape("Banner support foot", "cube", (x, 0.0, 0.11), (0.46, 0.5, 0.22), mats["gold"], col, 0.025)
		add_shape("Banner support post", "cube", (x, 0.0, 1.42), (0.14, 0.18, 2.72), mats["teal"], col)
		add_shape("Banner post cap", "sphere_low", (x, 0.0, 2.84), (0.28, 0.28, 0.28), mats["gold"], col)
	add_shape("Banner top rail", "cube", (0.0, 0.0, 2.84), (7.72, 0.18, 0.16), mats["teal"], col)
	add_shape("Grand opening banner panel", "cube", (0.0, -0.015, 3.34), (7.48, 0.12, 0.88), mats["red"], col, 0.02)
	add_shape("Banner top gold trim", "cube", (0.0, -0.089, 3.72), (7.12, 0.03, 0.055), mats["gold"], col)
	add_shape("Banner bottom gold trim", "cube", (0.0, -0.089, 2.96), (7.12, 0.03, 0.055), mats["gold"], col)
	add_text("GRAND OPENING!", (0.0, -0.094, 3.34), 0.57, mats["cream"], col)
	# Bright alternating pennants hang just below the cross rail, outside the text.
	for index in range(13):
		x = (index - 6) * 0.54
		color = mats["gold"] if index % 2 == 0 else mats["cream"]
		add_shape("Banner pennant", "cube", (x, -0.015, 2.78), (0.34, 0.035, 0.32), color, col)
	return col


def build_balloon_bunch(parent, mats):
	col = new_collection("Balloon Bunch", parent)
	# Eight bright low-poly balloons rise from floor-contacted gathered strings.
	layout = [
		(-0.34, 1.68, "red"), (-0.12, 2.08, "gold"), (0.14, 1.78, "blue"), (0.37, 2.16, "pink"),
		(-0.43, 2.34, "teal"), (-0.15, 2.55, "purple"), (0.16, 2.38, "cream"), (0.43, 2.62, "green"),
	]
	for index, (x, height, color_name) in enumerate(layout):
		depth = 0.10 if index % 2 == 0 else -0.10
		width = 0.40 if index % 3 == 0 else 0.36
		add_shape("Balloon", "sphere_low", (x, depth, height), (width, 0.34, 0.48), mats[color_name], col)
		add_shape("Balloon knot", "sphere_low", (x, depth, height - 0.27), (0.105, 0.09, 0.12), mats[color_name], col)
		string_length = height - 0.32
		add_shape("Balloon string", "cube", (x * 0.18, depth * 0.25, string_length * 0.5), (0.012, 0.012, string_length), mats["string"], col)
	add_shape("Balloon bunch ribbon", "cube", (0.0, 0.0, 0.31), (0.11, 0.11, 0.62), mats["gold"], col, 0.018)
	add_shape("Balloon weight", "cylinder", (0.0, 0.0, 0.10), (0.40, 0.40, 0.20), mats["red"], col, 0.02)
	return col


def build_mascot_standee(parent, mats):
	col = new_collection("Produce Mascot Standee", parent)
	# A friendly tomato mascot printed on a framed cardboard cutout.
	add_shape("Mascot backing", "cube", (0.0, 0.09, 1.00), (1.12, 0.12, 1.90), mats["cream"], col, 0.055)
	add_shape("Mascot base", "cube", (0.0, 0.02, 0.10), (1.30, 0.56, 0.20), mats["teal"], col, 0.05)
	add_shape("Mascot tomato body", "sphere_low", (0.0, -0.015, 0.91), (0.90, 0.34, 0.91), mats["red"], col)
	# Green leafy crown and stem.
	for index, angle in enumerate((-0.65, -0.22, 0.22, 0.65)):
		add_shape("Mascot leaf", "sphere_low", (math.sin(angle) * 0.18, -0.04, 1.40 + math.cos(angle) * 0.045), (0.31, 0.13, 0.14), mats["green"], col, rotation=(0.0, angle, 0.0))
	add_shape("Mascot stem", "cube", (0.0, -0.035, 1.49), (0.13, 0.13, 0.20), mats["green"], col, 0.025)
	# Eyes, cheeks and smile sit just proud of the tomato face.
	for x in (-0.19, 0.19):
		add_shape("Mascot eye", "sphere_low", (x, -0.205, 1.05), (0.12, 0.07, 0.16), mats["dark"], col)
		add_shape("Mascot eye glint", "sphere_low", (x - 0.025, -0.248, 1.09), (0.035, 0.022, 0.045), mats["white"], col)
	for x in (-0.31, 0.31):
		add_shape("Mascot cheek", "sphere_low", (x, -0.197, 0.86), (0.13, 0.045, 0.075), mats["pink"], col)
	add_shape("Mascot smile", "cube", (0.0, -0.222, 0.80), (0.21, 0.04, 0.035), mats["dark"], col, rotation=(0.0, 0.0, 0.0))
	# Short arms and shoes make the cutout read clearly from the entrance.
	for side in (-1, 1):
		add_shape("Mascot arm", "cube", (side * 0.51, -0.025, 0.86), (0.28, 0.18, 0.18), mats["red"], col, 0.045, rotation=(0.0, 0.0, side * -0.35))
		add_shape("Mascot shoe", "cube", (side * 0.23, -0.035, 0.25), (0.30, 0.23, 0.16), mats["blue"], col, 0.045)
	add_shape("Mascot welcome plaque", "cube", (0.0, -0.205, 0.53), (0.78, 0.07, 0.18), mats["gold"], col, 0.035)
	add_text("FRESH!", (0.0, -0.247, 0.535), 0.13, mats["dark"], col)
	return col


def build_shopper_standee(parent, mats):
	col = new_collection("Shopper Standee", parent)
	# A generic shopper waving beside a compact, colorful grocery cart.
	add_shape("Shopper backing", "cube", (0.0, 0.12, 0.98), (1.62, 0.12, 1.86), mats["cream"], col, 0.055)
	add_shape("Shopper base", "cube", (0.0, 0.0, 0.10), (1.82, 0.62, 0.20), mats["purple"], col, 0.05)
	# Person stands to the left; the cart is clearly visible to their right.
	add_shape("Shopper head", "sphere_low", (-0.40, -0.02, 1.49), (0.40, 0.34, 0.42), mats["skin"], col)
	add_shape("Shopper hair", "sphere_low", (-0.40, -0.005, 1.66), (0.42, 0.34, 0.20), mats["brown"], col)
	add_shape("Shopper torso", "cube", (-0.40, 0.005, 0.99), (0.48, 0.30, 0.66), mats["blue"], col, 0.09)
	for side in (-1, 1):
		add_shape("Shopper leg", "cube", (-0.40 + side * 0.13, 0.0, 0.48), (0.17, 0.23, 0.38), mats["navy"], col, 0.045)
		add_shape("Shopper shoe", "cube", (-0.40 + side * 0.13, -0.045, 0.25), (0.23, 0.30, 0.14), mats["dark"], col, 0.035)
	# Waving arm is raised at the outer edge; the other reaches toward the cart.
	add_shape("Shopper waving upper arm", "cube", (-0.69, -0.01, 1.18), (0.18, 0.23, 0.40), mats["blue"], col, 0.05, rotation=(0.0, 0.0, 0.60))
	add_shape("Shopper waving hand", "sphere_low", (-0.80, -0.02, 1.48), (0.18, 0.20, 0.18), mats["skin"], col)
	add_shape("Shopper reaching arm", "cube", (-0.11, -0.01, 0.99), (0.42, 0.20, 0.16), mats["blue"], col, 0.04, rotation=(0.0, 0.0, -0.16))
	# Face details face the same way as the banner and aisle signage (+Godot Z).
	for x in (-0.47, -0.33):
		add_shape("Shopper eye", "sphere_low", (x, -0.195, 1.51), (0.045, 0.04, 0.065), mats["dark"], col)
	add_shape("Shopper smile", "cube", (-0.40, -0.196, 1.40), (0.11, 0.035, 0.025), mats["pink"], col)
	# Basket, rim, handle, and wheels make the shopping prop legible at a glance.
	add_shape("Cart basket", "cube", (0.47, -0.02, 0.77), (0.63, 0.38, 0.40), mats["teal"], col, 0.045)
	add_shape("Cart basket front", "cube", (0.47, -0.228, 0.77), (0.51, 0.025, 0.26), mats["gold"], col)
	add_shape("Cart rim", "cube", (0.47, -0.025, 0.99), (0.70, 0.43, 0.07), mats["orange"], col, 0.02)
	add_shape("Cart handle", "cube", (0.13, -0.01, 1.07), (0.22, 0.10, 0.07), mats["orange"], col, 0.025)
	for x in (0.27, 0.67):
		add_shape("Cart wheel", "cylinder", (x, -0.04, 0.38), (0.16, 0.13, 0.16), mats["dark"], col)
	for x, color_name in ((0.34, "red"), (0.49, "green"), (0.61, "gold")):
		add_shape("Cart groceries", "sphere_low", (x, -0.04, 0.99), (0.14, 0.14, 0.16), mats[color_name], col)
	return col


def evaluated_triangle_count(objects):
	depsgraph = bpy.context.evaluated_depsgraph_get()
	count = 0
	for obj in objects:
		if obj.type not in {"MESH", "FONT", "CURVE"}:
			raise RuntimeError("Non-visual object in generated asset: " + obj.name + " (" + obj.type + ")")
		evaluated = obj.evaluated_get(depsgraph)
		mesh = evaluated.to_mesh()
		if mesh is not None:
			mesh.calc_loop_triangles()
			object_count = len(mesh.loop_triangles)
			count += object_count
			evaluated.to_mesh_clear()
	if count > 2000:
		raise RuntimeError("Asset exceeds 2,000-triangle guidance: " + str(count))
	return count


def export_collection(col, filepath):
	objects = list(col.objects)
	if not objects:
		raise RuntimeError("Cannot export empty collection: " + col.name)
	triangles = evaluated_triangle_count(objects)
	bpy.ops.object.select_all(action="DESELECT")
	for obj in objects:
		obj.select_set(True)
	bpy.context.view_layer.objects.active = objects[0]
	bpy.ops.export_scene.gltf(
		filepath=filepath,
		export_format="GLB",
		use_selection=True,
		export_apply=True,
		export_materials="EXPORT",
		export_cameras=False,
		export_lights=False,
	)
	REPORT[col.name] = {"triangles": triangles, "objects": len(objects), "path": filepath}


def build():
	if not bpy.data.filepath:
		raise RuntimeError("Open Assets.blend before running this builder.")
	MESH_CACHE.clear()
	REPORT.clear()
	old = bpy.data.collections.get(ROOT_NAME)
	if old:
		for child in list(old.children):
			for obj in list(child.objects):
				bpy.data.objects.remove(obj, do_unlink=True)
			bpy.data.collections.remove(child)
		for obj in list(old.objects):
			bpy.data.objects.remove(obj, do_unlink=True)
		bpy.data.collections.remove(old)
	for mesh in list(bpy.data.meshes):
		if mesh.users == 0 and mesh.name.startswith("GOA_"):
			bpy.data.meshes.remove(mesh)
	root = new_collection(ROOT_NAME, bpy.context.scene.collection)
	mats = {
		"red": material("Celebration red", "#D32F2F", roughness=0.48),
		"gold": material("Celebration yellow", "#FFD600", roughness=0.44),
		"cream": material("Celebration cream", "#FFF6E0", roughness=0.52),
		"teal": material("Celebration teal", "#2F8F84", roughness=0.5),
		"blue": material("Celebration blue", "#43A8D3", roughness=0.42),
		"pink": material("Celebration pink", "#EC407A", roughness=0.5),
		"purple": material("Celebration purple", "#8E24AA", roughness=0.5),
		"green": material("Celebration green", "#4CAF50", roughness=0.54),
		"string": material("Balloon string", "#FFF6E0", roughness=0.72),
		"skin": material("Shopper skin", "#E7A875", roughness=0.65),
		"brown": material("Shopper hair", "#63412E", roughness=0.7),
		"navy": material("Shopper trousers", "#23436D", roughness=0.68),
		"dark": material("Dark feature", "#292D32", roughness=0.65),
		"white": material("Eye highlight", "#FFFFFF", roughness=0.45),
		"orange": material("Cart orange", "#F28C28", roughness=0.55),
	}
	banner = build_banner(root, mats)
	balloons = build_balloon_bunch(root, mats)
	mascot = build_mascot_standee(root, mats)
	shopper = build_shopper_standee(root, mats)
	# Save the editable source and export only the two new prop collections.
	source_path = bpy.data.filepath
	output_dir = os.path.join(os.path.dirname(source_path), "assets", "models", "store", "grand_opening")
	os.makedirs(output_dir, exist_ok=True)
	bpy.ops.wm.save_as_mainfile(filepath=source_path)
	export_collection(banner, os.path.join(output_dir, "grand_opening_banner.glb"))
	export_collection(balloons, os.path.join(output_dir, "balloon_bunch.glb"))
	export_collection(mascot, os.path.join(output_dir, "mascot_standee.glb"))
	export_collection(shopper, os.path.join(output_dir, "shopper_standee.glb"))
	print("GRAND_OPENING_REPORT", REPORT)


build()
