"""Build the six Checkout Chaos grocery aisles in the currently open .blend.

Run this from Blender's Scripting workspace with Assets.blend open. It only
replaces its own generated collections, keeps all other scene content, saves
the .blend, and exports a visual-only GLB to assets/models/store/.
"""

import math
import os

import bpy
import bmesh
from mathutils import Vector


ROOT_NAME = "CC Aisles"
PREVIEW_NAME = "CC Aisle Preview"
AISLE_WIDTH = 7.5
AISLE_LENGTH = 14.0
AISLE_SPACING = 7.5
MESH_CACHE = {}
GENERATED_OBJECTS = []

AISLES = [
	{"name": "Produce", "color": "#4CAF50", "value": "$5 each"},
	{"name": "Bakery", "color": "#FF9800", "value": "$10 each"},
	{"name": "Dairy", "color": "#F5F5F5", "value": "$10 each"},
	{"name": "Snacks", "color": "#E53935", "value": "$15 each"},
	{"name": "Frozen", "color": "#1E88E5", "value": "$20 each"},
	{"name": "Electronics", "color": "#8E24AA", "value": "$40 each"},
]


def srgb_component(value):
	value /= 255.0
	return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def rgba(hex_color, alpha=1.0):
	text = hex_color.lstrip("#")
	return tuple(srgb_component(int(text[index:index + 2], 16)) for index in (0, 2, 4)) + (alpha,)


def material(name, color, metallic=0.0, roughness=0.48, alpha=1.0):
	mat_name = "CCA_" + name
	mat = bpy.data.materials.get(mat_name) or bpy.data.materials.new(mat_name)
	mat.diffuse_color = (*rgba(color, alpha)[:3], alpha)
	mat.use_nodes = True
	shader = mat.node_tree.nodes.get("Principled BSDF")
	if shader:
		shader.inputs["Base Color"].default_value = rgba(color, alpha)
		shader.inputs["Metallic"].default_value = metallic
		shader.inputs["Roughness"].default_value = roughness
		if "Alpha" in shader.inputs:
			shader.inputs["Alpha"].default_value = alpha
	if alpha < 1.0:
		try:
			mat.surface_render_method = "DITHERED"
		except (AttributeError, TypeError):
			pass
	return mat


def collection(name, parent):
	result = bpy.data.collections.new(name)
	parent.children.link(result)
	return result


def remove_collection_tree(col):
	for child in list(col.children):
		remove_collection_tree(child)
	for obj in list(col.objects):
		bpy.data.objects.remove(obj, do_unlink=True)
	bpy.data.collections.remove(col)


def get_mesh(kind, mat):
	key = (kind, mat.name)
	if key in MESH_CACHE:
		return MESH_CACHE[key]
	bm = bmesh.new()
	if kind == "cube":
		bmesh.ops.create_cube(bm, size=1.0)
	elif kind == "sphere":
		bmesh.ops.create_uvsphere(bm, u_segments=12, v_segments=8, radius=1.0)
		for face in bm.faces:
			face.smooth = True
	elif kind == "cylinder":
		bmesh.ops.create_cone(bm, segments=12, radius1=1.0, radius2=1.0, depth=1.0, cap_ends=True)
	else:
		bm.free()
		raise ValueError("Unknown primitive: " + kind)
	mesh = bpy.data.meshes.new("CCA_" + kind + "_" + mat.name)
	bm.to_mesh(mesh)
	bm.free()
	mesh.materials.append(mat)
	MESH_CACHE[key] = mesh
	return mesh


def make_object(name, kind, loc, dims, mat, col, bevel=0.0, rotation=None):
	obj = bpy.data.objects.new(name, get_mesh(kind, mat))
	col.objects.link(obj)
	obj.location = loc
	obj.dimensions = dims
	if rotation is not None:
		obj.rotation_euler = rotation
	if bevel > 0.0:
		mod = obj.modifiers.new("Soft product edges", "BEVEL")
		mod.width = bevel
		mod.segments = 2
		mod.limit_method = "ANGLE"
	GENERATED_OBJECTS.append(obj)
	return obj


def box(name, loc, dims, mat, col, bevel=0.025, rotation=None):
	return make_object(name, "cube", loc, dims, mat, col, bevel, rotation)


def ball(name, loc, dims, mat, col):
	return make_object(name, "sphere", loc, dims, mat, col)


def cylinder(name, loc, dims, mat, col, rotation=None):
	return make_object(name, "cylinder", loc, dims, mat, col, 0.0, rotation)


def sign_text(body, loc, col, mat, size=0.28):
	curve = bpy.data.curves.new("CCA_sign_text", "FONT")
	curve.body = body
	curve.size = size
	curve.extrude = 0.002
	curve.align_x = "CENTER"
	curve.align_y = "CENTER"
	obj = bpy.data.objects.new("Sign " + body, curve)
	col.objects.link(obj)
	obj.location = loc
	obj.rotation_euler = (math.pi / 2.0, 0.0, 0.0)
	obj.data.materials.append(mat)
	bpy.ops.object.select_all(action="DESELECT")
	obj.select_set(True)
	bpy.context.view_layer.objects.active = obj
	bpy.ops.object.convert(target="MESH")
	GENERATED_OBJECTS.append(obj)
	return obj


def aisle_sign(x, spec, col, mats):
	y = -7.45
	box(spec["name"] + " aisle header", (x, y, 2.62), (3.1, 0.22, 0.82), mats["navy"], col, 0.07)
	box(spec["name"] + " color band", (x, y - 0.13, 2.29), (2.86, 0.035, 0.07), mats[spec["name"]], col, 0.015)
	sign_text(spec["name"].upper(), (x, y - 0.135, 2.72), col, mats["white_text"], 0.31)
	sign_text(spec["value"], (x, y - 0.135, 2.47), col, mats["white_text"], 0.15)
	post_height = 2.21  # Floor top (z=0) to the bottom of the header.
	post_center_z = post_height * 0.5
	box(spec["name"] + " sign post L", (x - 1.48, y, post_center_z), (0.08, 0.09, post_height), mats["steel"], col, 0.015)
	box(spec["name"] + " sign post R", (x + 1.48, y, post_center_z), (0.08, 0.09, post_height), mats["steel"], col, 0.015)


def floor_and_trim(x, spec, col, mats):
	# The 15 m floor apron runs under the aisle header and its sign posts.
	box(spec["name"] + " aisle floor", (x, 0.0, -0.06), (AISLE_WIDTH, 15.0, 0.12), mats["tile"], col, 0.025)
	for side in (-1, 1):
		box(spec["name"] + " aisle edge", (x + side * 3.12, 0.0, 0.012), (0.09, 13.7, 0.024), mats[spec["name"]], col, 0.008)
	for index in range(5):
		y = -5.4 + index * 2.7
		box(spec["name"] + " floor tile seam", (x, y, 0.004), (6.05, 0.012, 0.006), mats["tile_line"], col, 0.0)


def open_case(x, y, side, label, col, mats, width=1.55, length=2.25, height=0.96):
	# Keep this fixture's outside edge on its lane boundary so adjacent aisle
	# fixtures meet back-to-back at the demo shelf line.
	cx = x + side * (AISLE_SPACING * 0.5 - 1.45 * 0.5)
	box(label + " chilled case base", (cx, y, height * 0.42), (width, length, height * 0.84), mats["case"], col, 0.065)
	box(label + " open case top", (cx, y, height * 0.88), (width + 0.06, length + 0.08, 0.10), mats["case_top"], col, 0.035)
	box(label + " product well", (cx, y, height * 0.95), (width - 0.25, length - 0.28, 0.06), mats["well"], col, 0.02)
	return cx


def build_produce(x, col, mats):
	fruit = [mats[name] for name in ("apple_red", "apple_green", "citrus", "tomato", "leaf")]
	case_height = 0.88
	for side in (-1, 1):
		for bay in range(5):
			y = -5.25 + bay * 2.55
			cx = open_case(x, y, side, "Produce", col, mats, width=1.45, length=2.25, height=case_height)
			for row in range(3):
				for col_idx in range(4):
					product_mat = fruit[(bay + row + col_idx) % len(fruit)]
					px = cx + (col_idx - 1.5) * 0.31
					py = y + (row - 1.0) * 0.52
					if product_mat == mats["leaf"]:
						dims = (0.29, 0.22, 0.13)
						z = case_height * 0.95 + 0.03 + dims[2] * 0.5 - 0.004
						ball("Leafy greens", (px, py, z), dims, product_mat, col)
					else:
						dims = (0.22, 0.22, 0.22)
						z = case_height * 0.95 + 0.03 + dims[2] * 0.5 - 0.004
						ball("Fresh produce", (px, py, z), dims, product_mat, col)
			for corner in (-1, 1):
				box("Produce bin label", (cx + corner * 0.57, y - 1.12, 0.91), (0.24, 0.045, 0.12), mats["navy"], col, 0.012)


def build_bakery(x, col, mats):
	for side in (-1, 1):
		for bay in range(5):
			y = -5.15 + bay * 2.55
			cx = x + side * (AISLE_SPACING * 0.5 - 1.55 * 0.5)
			box("Bakery warm wood island", (cx, y, 0.58), (1.55, 2.18, 0.95), mats["wood"], col, 0.07)
			box("Bakery basket liner", (cx, y, 1.09), (1.38, 1.98, 0.10), mats["basket_liner"], col, 0.035)
			for row in range(2):
				for item in range(4):
					px = cx + (item - 1.5) * 0.31
					py = y + (row - 0.5) * 0.72
					bread_mat = mats["bread_dark"] if (item + bay) % 3 == 0 else mats["bread"]
					liner_top = 1.14
					loaf_dims = (0.24, 0.42, 0.16)
					loaf_z = liner_top + loaf_dims[2] * 0.5 - 0.004
					ball("Bakery loaf", (px, py, loaf_z), loaf_dims, bread_mat, col)
					if item % 2 == 0:
						pastry_dims = (0.13, 0.14, 0.08)
						pastry_z = loaf_z + loaf_dims[2] * 0.5 + pastry_dims[2] * 0.5 - 0.003
						ball("Golden pastry", (px + 0.05, py + 0.17, pastry_z), pastry_dims, mats["pastry"], col)
			box("Bakery tray", (cx, y + 1.08, 1.15), (1.34, 0.045, 0.09), mats["steel"], col, 0.012)
			if bay in (1, 3):
				cake_sponge_dims = (0.60, 0.60, 0.12)
				cake_sponge_z = 1.14 + cake_sponge_dims[2] * 0.5 - 0.004
				cake_frosting_dims = (0.58, 0.58, 0.14)
				cake_frosting_z = cake_sponge_z + cake_sponge_dims[2] * 0.5 + cake_frosting_dims[2] * 0.5 - 0.003
				cylinder("Celebration cake", (cx, y - 0.22, cake_frosting_z), cake_frosting_dims, mats["cake_frosting"], col)
				cylinder("Cake sponge layer", (cx, y - 0.22, cake_sponge_z), cake_sponge_dims, mats["cake_sponge"], col)


def fridge_case(x, y, side, label, col, mats, length=2.28, height=2.22):
	cx = x + side * (AISLE_SPACING * 0.5 - 0.94 * 0.5)
	box(label + " cold cabinet", (cx, y, height * 0.5), (0.94, length, height), mats["case"], col, 0.065)
	box(label + " cabinet back", (cx + side * 0.35, y, height * 0.55), (0.12, length - 0.20, height - 0.34), mats["cabinet_inside"], col, 0.02)
	for shelf in range(3):
		z = 0.58 + shelf * 0.48
		box(label + " interior shelf", (cx - side * 0.16, y, z), (0.64, length - 0.16, 0.055), mats["case_top"], col, 0.012)
		for idx in range(5):
			py = y - 0.78 + idx * 0.38
			if shelf < 2 and idx % 2 == 0:
				box("Cold drink carton", (cx - side * 0.39, py, z + 0.22), (0.19, 0.20, 0.39), mats["milk_carton"], col, 0.025)
				cap_height = 0.07
				cap_z = z + 0.22 + 0.39 * 0.5 + cap_height * 0.5 - 0.003
				cylinder("Carton cap", (cx - side * 0.39, py, cap_z), (0.065, 0.065, cap_height), mats["blue_cap"], col)
			else:
				box("Cheese packet", (cx - side * 0.39, py, z + 0.15), (0.27, 0.26, 0.25), mats["cheese"], col, 0.035)
	# Separate glossy door panels leave the cases' products visible through the gaps.
	front = cx - side * 0.49
	for panel in range(3):
		py = y + (panel - 1) * 0.68
		box(label + " glass door", (front, py, 1.28), (0.035, 0.63, 1.62), mats["glass"], col, 0.012)
		box(label + " door handle", (front - side * 0.03, py + 0.20, 1.30), (0.035, 0.035, 0.45), mats["steel"], col, 0.01)
	return cx


def build_dairy(x, col, mats):
	for side in (-1, 1):
		for bay in range(6):
			y = -5.7 + bay * 2.28
			fridge_case(x, y, side, "Dairy refrigerator", col, mats, length=2.18)
			if bay % 2 == 0:
				box("Dairy shelf price strip", (x + side * (AISLE_SPACING * 0.5 - 0.94 - 0.045), y, 0.18), (0.045, 1.75, 0.12), mats["navy"], col, 0.015)


def rack_bay(x, y, side, label, col, mats, height=2.08):
	cx = x + side * (AISLE_SPACING * 0.5 - 0.94 * 0.5)
	box(label + " shelf back", (cx + side * 0.42, y, height * 0.5), (0.10, 2.15, height), mats["steel_dark"], col, 0.035)
	for level in range(4):
		z = 0.40 + level * 0.47
		box(label + " shelf", (cx, y, z), (0.82, 2.18, 0.07), mats["steel"], col, 0.025)
		box(label + " shelf lip", (cx - side * 0.38, y, z + 0.055), (0.06, 2.13, 0.12), mats["steel_dark"], col, 0.018)
	for side_offset in (-1, 1):
		for end in (-1, 1):
			box(label + " upright", (cx + side_offset * 0.38, y + end * 1.02, height * 0.5), (0.06, 0.07, height), mats["steel_dark"], col, 0.015)
	return cx


def build_snacks(x, col, mats):
	bag_colors = [mats["chips_red"], mats["chips_yellow"], mats["chips_green"], mats["chips_blue"]]
	for side in (-1, 1):
		for bay in range(6):
			y = -5.5 + bay * 2.15
			# Leave headroom for product on the top shelf, and keep each row
			# within the shelf depth, behind the aisle-facing retaining lip.
			cx = rack_bay(x, y, side, "Snack display", col, mats, height=2.30)
			for level in range(4):
				z = 0.40 + level * 0.47
				shelf_top = z + 0.035
				for item in range(3):
					px = cx - side * 0.21
					py = y + (item - 1) * 0.48
					if (bay + item + level) % 2 == 0:
						bag_mat = bag_colors[(bay + level + item) % len(bag_colors)]
						bag_height = 0.38
						bag_z = shelf_top + bag_height * 0.5 - 0.003
						box("Potato chips bag", (px, py, bag_z), (0.20, 0.25, bag_height), bag_mat, col, 0.055)
						box("Bag front label", (px - side * 0.105, py, bag_z + 0.01), (0.018, 0.11, 0.13), mats["package_cream"], col, 0.008)
					else:
						cracker_height = 0.34
						cracker_z = shelf_top + cracker_height * 0.5 - 0.003
						box("Cracker box", (px, py, cracker_z), (0.22, 0.28, cracker_height), mats["cracker_box"], col, 0.025)
						box("Cracker label", (px - side * 0.117, py, cracker_z + 0.01), (0.016, 0.14, 0.15), mats["package_gold"], col, 0.007)


def build_frozen(x, col, mats):
	for side in (-1, 1):
		for bay in range(5):
			y = -5.0 + bay * 2.5
			cx = x + side * (AISLE_SPACING * 0.5 - 0.98 * 0.5)
			box("Frozen island case", (cx, y, 1.02), (0.98, 2.32, 2.04), mats["freezer"], col, 0.065)
			box("Freezer shelf interior", (cx + side * 0.18, y, 1.02), (0.54, 2.14, 1.70), mats["cabinet_inside"], col, 0.02)
			for shelf in range(3):
				z = 0.48 + shelf * 0.49
				box("Freezer product shelf", (cx - side * 0.11, y, z), (0.62, 2.15, 0.05), mats["case_top"], col, 0.01)
				for item in range(3):
					py = y + (item - 1) * 0.58
					if (bay + item) % 2 == 0:
						box("Frozen pizza box", (cx - side * 0.34, py, z + 0.21), (0.20, 0.46, 0.38), mats["pizza_box"], col, 0.025)
						box("Pizza front panel", (cx - side * 0.455, py, z + 0.21), (0.018, 0.25, 0.20), mats["pizza_label"], col, 0.006)
					else:
						box("Frozen meat pack", (cx - side * 0.34, py, z + 0.17), (0.19, 0.44, 0.30), mats["meat_pack"], col, 0.025)
			front = cx - side * 0.505
			box("Freezer glass door", (front, y, 1.13), (0.035, 2.15, 1.72), mats["glass"], col, 0.015)
			box("Freezer door handle", (front - side * 0.03, y + 0.78, 1.13), (0.045, 0.04, 0.82), mats["steel"], col, 0.015)


def build_electronics(x, col, mats):
	for side in (-1, 1):
		for bay in range(4):
			y = -4.95 + bay * 3.15
			cx = rack_bay(x, y, side, "Electronics wall", col, mats, height=2.28)
			# Large televisions at eye height, all aimed toward the aisle center.
			tv_x = cx - side * 0.22
			tv_shelf_top = 1.34 + 0.035
			tv_stand_height = 0.08
			tv_screen_height = 0.82
			tv_stand_z = tv_shelf_top + tv_stand_height * 0.5 - 0.003
			tv_screen_z = tv_shelf_top + tv_stand_height + tv_screen_height * 0.5 - 0.006
			box("Slim television screen", (tv_x, y, tv_screen_z), (0.16, 1.30, tv_screen_height), mats["screen"], col, 0.035)
			box("TV picture panel", (tv_x - side * 0.087, y, tv_screen_z + 0.01), (0.025, 1.18, 0.68), mats["screen_glow"], col, 0.008)
			box("Television stand", (tv_x, y, tv_stand_z), (0.40, 0.62, tv_stand_height), mats["steel_dark"], col, 0.025)
			for item in range(3):
				py = y + (item - 1) * 0.48
				console_dims = (0.38, 0.36, 0.20)
				console_z = 0.40 + 0.035 + console_dims[2] * 0.5 - 0.003
				box("Game console", (cx - side * 0.24, py, console_z), console_dims, mats["console_white"] if item % 2 else mats["console_black"], col, 0.04)
				ball("Console power light", (cx - side * 0.45, py - 0.09, console_z + console_dims[2] * 0.5), (0.035, 0.035, 0.035), mats["power_blue"], col)
			# Two simple controllers with colored face buttons.
			for item in (-1, 1):
				py = y + item * 0.36
				controller_dims = (0.30, 0.20, 0.11)
				controller_z = 0.40 + 0.035 + controller_dims[2] * 0.5 - 0.003
				ball("Game controller body", (cx - side * 0.25, py, controller_z), controller_dims, mats["controller"], col)
				button_dims = (0.035, 0.035, 0.025)
				button_z = controller_z + controller_dims[2] * 0.5 + button_dims[2] * 0.5 - 0.002
				ball("Controller button", (cx - side * 0.37, py + 0.045, button_z), button_dims, mats["chips_red"], col)


def shared_materials():
	mats = {
		"navy": material("Sign navy", "#17324D", roughness=0.42),
		"white_text": material("Warm white lettering", "#FFF6E0", roughness=0.5),
		"steel": material("Satin store steel", "#AAB8BF", metallic=0.58, roughness=0.32),
		"steel_dark": material("Blue grey steel", "#50636D", metallic=0.48, roughness=0.38),
		"case": material("Refrigerated case enamel", "#D7E2E4", metallic=0.16, roughness=0.32),
		"case_top": material("Cool case ledge", "#F4F6F1", metallic=0.08, roughness=0.3),
		"cabinet_inside": material("Cool cabinet interior", "#B9D5DC", roughness=0.34),
		"well": material("Produce bin liner", "#354A41", roughness=0.7),
		"glass": material("Cool glass", "#A5DCE7", metallic=0.12, roughness=0.12, alpha=0.28),
		"tile": material("Warm polished tile", "#E7E4D9", roughness=0.72),
		"tile_line": material("Tile grout", "#C8C5BB", roughness=0.85),
		"wood": material("Bakery honey wood", "#A96F3D", roughness=0.65),
		"basket_liner": material("Bakery basket liner", "#D2A05A", roughness=0.7),
		"bread": material("Bread crust", "#C77A3C", roughness=0.74),
		"bread_dark": material("Dark crust", "#8E4E2D", roughness=0.75),
		"pastry": material("Golden pastry", "#E5AE54", roughness=0.65),
		"cake_sponge": material("Cake sponge", "#F2D39A", roughness=0.65),
		"cake_frosting": material("Berry frosting", "#E89BA7", roughness=0.38),
		"milk_carton": material("Milk carton", "#F7F6ED", roughness=0.5),
		"blue_cap": material("Milk bottle blue cap", "#43A8D3", roughness=0.32),
		"cheese": material("Cheddar cheese", "#EABF46", roughness=0.6),
		"chips_red": material("Snack red", "#D94D40", roughness=0.38),
		"chips_yellow": material("Snack yellow", "#F3C04F", roughness=0.38),
		"chips_green": material("Snack green", "#53966A", roughness=0.4),
		"chips_blue": material("Snack blue", "#4F82B5", roughness=0.4),
		"package_cream": material("Snack bag print", "#F7E7BF", roughness=0.48),
		"cracker_box": material("Cracker kraft pack", "#B67B46", roughness=0.55),
		"package_gold": material("Cracker pack accent", "#E9C15D", roughness=0.45),
		"freezer": material("Freezer enamel blue", "#547B91", metallic=0.14, roughness=0.3),
		"pizza_box": material("Frozen pizza box", "#B94733", roughness=0.52),
		"pizza_label": material("Pizza label", "#F0CA73", roughness=0.48),
		"meat_pack": material("Frozen meat pack", "#B65B5A", roughness=0.4),
		"screen": material("TV bezel", "#1C2229", metallic=0.18, roughness=0.25),
		"screen_glow": material("TV screen", "#3B7089", metallic=0.05, roughness=0.18),
		"console_white": material("Console ivory", "#E5E6E1", roughness=0.34),
		"console_black": material("Console charcoal", "#333941", roughness=0.34),
		"controller": material("Controller dark grey", "#565E65", roughness=0.36),
		"power_blue": material("Console status light", "#4AA8E5", roughness=0.24),
		"apple_red": material("Produce red apple", "#C9473E", roughness=0.33),
		"apple_green": material("Produce green apple", "#6DAD53", roughness=0.36),
		"citrus": material("Produce citrus", "#F0B440", roughness=0.43),
		"tomato": material("Produce tomato", "#DD5641", roughness=0.37),
		"leaf": material("Produce leafy greens", "#3D8051", roughness=0.7),
	}
	for aisle in AISLES:
		mats[aisle["name"]] = material(aisle["name"] + " category", aisle["color"], roughness=0.5)
	return mats


def preview_setup(root):
	col = collection(PREVIEW_NAME, bpy.context.scene.collection)
	col.hide_viewport = False
	width = AISLE_SPACING * (len(AISLES) - 1) + AISLE_WIDTH + 2.0
	box("Store preview ground", (0.0, 0.0, -0.18), (width, 18.0, 0.12), material("Preview floor", "#CED4D2", roughness=0.9), col, 0.0)
	cam_data = bpy.data.cameras.new("CC Aisle Overview Camera")
	cam = bpy.data.objects.new("CC Aisle Overview Camera", cam_data)
	col.objects.link(cam)
	cam.location = (0.0, -35.0, 29.0)
	target = Vector((0.0, 0.0, 0.8))
	cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
	cam_data.type = "ORTHO"
	cam_data.ortho_scale = width + 9.0
	bpy.context.scene.camera = cam
	for name, loc, energy, size in (
		("CC Aisle Key", (-14.0, -10.0, 22.0), 4200.0, 18.0),
		("CC Aisle Fill", (20.0, 9.0, 18.0), 2600.0, 16.0),
	):
		data = bpy.data.lights.new(name, "AREA")
		data.energy = energy
		data.shape = "DISK"
		data.size = size
		obj = bpy.data.objects.new(name, data)
		col.objects.link(obj)
		obj.location = loc
		obj.rotation_euler = (Vector((0.0, 0.0, 0.0)) - obj.location).to_track_quat("-Z", "Y").to_euler()
	scene = bpy.context.scene
	# The bundled Blender 5.2 build exposes EEVEE under BLENDER_EEVEE.
	engines = {item.identifier for item in scene.render.bl_rna.properties["engine"].enum_items}
	scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
	scene.render.resolution_x = 1600
	scene.render.resolution_y = 900
	scene.render.resolution_percentage = 100
	return col


def build():
	if not bpy.data.filepath:
		raise RuntimeError("Open Assets.blend before running this builder.")
	# Assets.blend started from Blender's default scene. Remove its lone default
	# cube (verified at the aisle origin); retain the original camera and light.
	default_cube = bpy.data.objects.get("Cube")
	if default_cube and default_cube.type == "MESH" and default_cube.location.length < 0.001:
		bpy.data.objects.remove(default_cube, do_unlink=True)
	old_root = bpy.data.collections.get(ROOT_NAME)
	if old_root:
		remove_collection_tree(old_root)
	old_preview = bpy.data.collections.get(PREVIEW_NAME)
	if old_preview:
		remove_collection_tree(old_preview)
	root = bpy.data.collections.new(ROOT_NAME)
	bpy.context.scene.collection.children.link(root)
	mats = shared_materials()
	builders = {
		"Produce": build_produce,
		"Bakery": build_bakery,
		"Dairy": build_dairy,
		"Snacks": build_snacks,
		"Frozen": build_frozen,
		"Electronics": build_electronics,
	}
	for index, spec in enumerate(AISLES):
		x = (index - (len(AISLES) - 1) / 2.0) * AISLE_SPACING
		col = collection("Aisle " + spec["name"], root)
		floor_and_trim(x, spec, col, mats)
		aisle_sign(x, spec, col, mats)
		builders[spec["name"]](x, col, mats)
	# Export only the aisle models. The inspection platform, camera and lights
	# added below are for the Blender source preview, not the in-game asset.
	aisle_objects = list(GENERATED_OBJECTS)
	preview_setup(root)

	# Leave the aisle set easy to inspect in the viewport without changing the
	# visibility or selection of objects that were already in Assets.blend.
	bpy.ops.object.select_all(action="DESELECT")
	for obj in aisle_objects:
		obj.select_set(True)
	if aisle_objects:
		bpy.context.view_layer.objects.active = aisle_objects[0]

	source_path = bpy.data.filepath
	output_dir = os.path.join(os.path.dirname(source_path), "assets", "models", "store")
	os.makedirs(output_dir, exist_ok=True)
	glb_path = os.path.join(output_dir, "checkout_chaos_aisles.glb")
	# Save the native source first. Blender keeps its normal .blend1 backup.
	bpy.ops.wm.save_as_mainfile(filepath=source_path)
	if hasattr(bpy.ops.export_scene, "gltf"):
		bpy.ops.export_scene.gltf(
			filepath=glb_path,
			export_format="GLB",
			use_selection=True,
			export_apply=True,
			export_materials="EXPORT",
			export_cameras=False,
			export_lights=False,
		)
		print("EXPORTED_GLB", glb_path)
	else:
		print("GLTF_EXPORTER_MISSING; saved Blender source only:", source_path)
	print("BUILT_AISLES", [spec["name"] for spec in AISLES])
	print("GENERATED_OBJECTS", len(GENERATED_OBJECTS))


build()
