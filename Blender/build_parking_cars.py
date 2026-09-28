"""Build and export three visual-only cars for the Checkout Chaos parking lot.

Run from the project root with Blender 5.2:
    blender --background --python Blender/build_parking_cars.py

The generated collection is kept in the current Blender session for inspection;
only the three GLBs are written to the repository. Existing scene collections
are left untouched.
"""

import math
import os

import bpy
from mathutils import Vector


ROOT_NAME = "CC Parking Cars"
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "models", "store", "parking_cars")
TRIANGLE_LIMIT = 2000

VEHICLES = [
	{
		"name": "CompactHatchback",
		"file": "compact_hatchback.glb",
		"width": 1.74,
		"length": 3.75,
		"height": 1.56,
		"cabin_length": 1.78,
		"cabin_center": 0.24,
		"cabin_height": 0.48,
		"body_color": "#E45B4D",
		"style": "hatchback",
	},
	{
		"name": "FamilySedan",
		"file": "family_sedan.glb",
		"width": 1.82,
		"length": 4.05,
		"height": 1.52,
		"cabin_length": 1.62,
		"cabin_center": 0.08,
		"cabin_height": 0.46,
		"body_color": "#43A8D3",
		"style": "sedan",
	},
	{
		"name": "SmallSUV",
		"file": "small_suv.glb",
		"width": 1.90,
		"length": 4.18,
		"height": 1.68,
		"cabin_length": 1.94,
		"cabin_center": 0.12,
		"cabin_height": 0.56,
		"body_color": "#5C9B64",
		"style": "suv",
	},
]


def srgb_component(value):
	value /= 255.0
	return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def rgba(hex_color):
	text = hex_color.lstrip("#")
	return tuple(srgb_component(int(text[index:index + 2], 16)) for index in (0, 2, 4)) + (1.0,)


def make_material(name, hex_color, roughness=0.55, metallic=0.0):
	material_name = "PC_" + name
	mat = bpy.data.materials.get(material_name) or bpy.data.materials.new(material_name)
	mat.diffuse_color = rgba(hex_color)
	mat.use_nodes = True
	shader = mat.node_tree.nodes.get("Principled BSDF")
	if shader:
		shader.inputs["Base Color"].default_value = rgba(hex_color)
		shader.inputs["Roughness"].default_value = roughness
		shader.inputs["Metallic"].default_value = metallic
	return mat


def link_object(obj, collection):
	for old_collection in list(obj.users_collection):
		old_collection.objects.unlink(obj)
	collection.objects.link(obj)
	return obj


def add_box(name, dimensions, location, mat, collection, bevel=0.0, rotation_x=0.0):
	bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
	obj = link_object(bpy.context.object, collection)
	obj.name = name
	obj.dimensions = dimensions
	obj.rotation_euler.x = rotation_x
	obj.data.materials.append(mat)
	if bevel > 0.0:
		modifier = obj.modifiers.new("Single-segment soft edges", "BEVEL")
		modifier.width = bevel
		modifier.segments = 1
		modifier.limit_method = "ANGLE"
	return obj


def add_wheel(name, location, radius, depth, mat, collection, rotation_x=False):
	bpy.ops.mesh.primitive_cylinder_add(
		vertices=12,
		radius=radius,
		depth=depth,
		location=location,
	)
	obj = link_object(bpy.context.object, collection)
	obj.name = name
	if rotation_x:
		obj.rotation_euler.y = math.radians(90.0)
	obj.data.materials.append(mat)
	return obj


def new_collection(name, parent):
	collection = bpy.data.collections.new(name)
	parent.children.link(collection)
	return collection


def remove_collection_tree(collection):
	for child in list(collection.children):
		remove_collection_tree(child)
	for obj in list(collection.objects):
		bpy.data.objects.remove(obj, do_unlink=True)
	bpy.data.collections.remove(collection)


def build_vehicle(spec, root, materials):
	name = spec["name"]
	width = spec["width"]
	length = spec["length"]
	height = spec["height"]
	cabin_length = spec["cabin_length"]
	cabin_center = spec["cabin_center"]
	cabin_height = spec["cabin_height"]
	body = make_material(name + " body", spec["body_color"], roughness=0.42, metallic=0.04)
	variant = new_collection(name, root)

	# A broad lower body, short hood and rear deck give each car a clear profile.
	add_box(name + " body shell", (width, length - 0.12, 0.50), (0.0, 0.0, 0.55), body, variant, 0.10)
	add_box(name + " hood", (width * 0.94, length * 0.29, 0.22), (0.0, -length * 0.32, 0.82), body, variant, 0.07)
	add_box(name + " rear deck", (width * 0.92, length * 0.22, 0.20), (0.0, length * 0.36, 0.79), body, variant, 0.06)
	if spec["style"] == "hatchback":
		add_box(name + " hatch", (width * 0.72, 0.11, 0.48), (0.0, length * 0.38, 1.08), materials["glass"], variant, 0.025, math.radians(-18.0))

	# The raised cabin establishes a distinct roofline; glass panels sit on its sides.
	add_box(
		name + " cabin",
		(width * 0.76, cabin_length, cabin_height),
		(0.0, cabin_center, 0.91 + cabin_height * 0.5),
		body,
		variant,
		0.055,
	)
	roof_height = height - 0.17
	add_box(
		name + " roof",
		(width * 0.65, cabin_length * 0.74, 0.13),
		(0.0, cabin_center + cabin_length * 0.025, roof_height),
		body,
		variant,
		0.045,
	)
	add_box(
		name + " front windshield",
		(width * 0.63, 0.045, cabin_height * 0.69),
		(0.0, cabin_center - cabin_length * 0.40, 1.15 + cabin_height * 0.38),
		materials["glass"],
		variant,
		0.018,
		math.radians(13.0),
	)
	add_box(
		name + " rear windshield",
		(width * 0.61, 0.045, cabin_height * 0.58),
		(0.0, cabin_center + cabin_length * 0.40, 1.13 + cabin_height * 0.34),
		materials["glass"],
		variant,
		0.018,
		math.radians(-13.0),
	)
	for side in (-1.0, 1.0):
		for row, fraction in (("front", -0.22), ("rear", 0.25)):
			add_box(
				name + " " + row + " side window",
				(0.035, cabin_length * 0.37, cabin_height * 0.48),
				(side * width * 0.385, cabin_center + cabin_length * fraction, 1.15 + cabin_height * 0.40),
				materials["glass"],
				variant,
				0.014,
			)
		add_box(
			name + " door handle",
			(0.035, 0.13, 0.045),
			(side * (width * 0.5 - 0.035), cabin_center + 0.02, 0.91),
			materials["trim"],
			variant,
			0.012,
		)
		add_box(
			name + " side mirror",
			(0.13, 0.18, 0.12),
			(side * (width * 0.5 - 0.12), -length * 0.23, 1.03),
			body,
			variant,
			0.035,
		)

	# Chunky 12-sided wheels and plain hubs keep the vehicle readable at game scale.
	wheel_radius = 0.32 if spec["style"] != "suv" else 0.34
	wheel_depth = 0.22
	wheel_x = width * 0.5 - 0.15
	wheel_y = length * 0.5 - 0.67
	for side in (-1.0, 1.0):
		for axle, y in (("front", -wheel_y), ("rear", wheel_y)):
			add_wheel(
				name + " " + axle + " tire " + str(int(side)),
				(side * wheel_x, y, wheel_radius),
				wheel_radius,
				wheel_depth,
				materials["tire"],
				variant,
				rotation_x=True,
			)
			add_wheel(
				name + " " + axle + " hub " + str(int(side)),
				(side * (wheel_x + wheel_depth * 0.5 + 0.008), y, wheel_radius),
				wheel_radius * 0.54,
				0.04,
				materials["hub"],
				variant,
				rotation_x=True,
			)

	# Bumpers, grille, headlights and tail lights provide readable front/back cues.
	add_box(name + " front bumper", (width * 0.88, 0.12, 0.15), (0.0, -length * 0.5 + 0.07, 0.39), materials["trim"], variant, 0.035)
	add_box(name + " rear bumper", (width * 0.88, 0.12, 0.15), (0.0, length * 0.5 - 0.07, 0.39), materials["trim"], variant, 0.035)
	add_box(name + " grille", (width * 0.29, 0.035, 0.13), (0.0, -length * 0.5 + 0.018, 0.65), materials["trim"], variant, 0.018)
	for side in (-1.0, 1.0):
		add_box(name + " headlight", (0.22, 0.04, 0.12), (side * width * 0.34, -length * 0.5 + 0.015, 0.70), materials["light"], variant, 0.025)
		add_box(name + " tail light", (0.18, 0.045, 0.20), (side * width * 0.37, length * 0.5 - 0.02, 0.71), materials["tail"], variant, 0.025)
	add_box(name + " front plate", (0.34, 0.025, 0.08), (0.0, -length * 0.5 + 0.03, 0.49), materials["plate"], variant, 0.012)
	add_box(name + " rear plate", (0.34, 0.025, 0.08), (0.0, length * 0.5 - 0.03, 0.49), materials["plate"], variant, 0.012)

	if spec["style"] == "suv":
		for side in (-1.0, 1.0):
			add_box(
				name + " roof rail " + str(int(side)),
				(0.055, cabin_length * 0.64, 0.055),
				(side * width * 0.29, cabin_center, height - 0.075),
				materials["trim"],
				variant,
				0.014,
			)
	return variant


def triangle_count(collection):
	depsgraph = bpy.context.evaluated_depsgraph_get()
	total = 0
	for obj in collection.objects:
		if obj.type != "MESH":
			continue
		evaluated = obj.evaluated_get(depsgraph)
		mesh = evaluated.to_mesh()
		mesh.calc_loop_triangles()
		total += len(mesh.loop_triangles)
		evaluated.to_mesh_clear()
	return total


def world_bounds(collection):
	depsgraph = bpy.context.evaluated_depsgraph_get()
	minimum = Vector((float("inf"), float("inf"), float("inf")))
	maximum = Vector((float("-inf"), float("-inf"), float("-inf")))
	for obj in collection.objects:
		if obj.type != "MESH":
			continue
		evaluated = obj.evaluated_get(depsgraph)
		mesh = evaluated.to_mesh()
		for vertex in mesh.vertices:
			point = evaluated.matrix_world @ vertex.co
			minimum.x = min(minimum.x, point.x)
			minimum.y = min(minimum.y, point.y)
			minimum.z = min(minimum.z, point.z)
			maximum.x = max(maximum.x, point.x)
			maximum.y = max(maximum.y, point.y)
			maximum.z = max(maximum.z, point.z)
		evaluated.to_mesh_clear()
	return minimum, maximum


def export_vehicle(collection, filepath):
	objects = list(collection.objects)
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


def build():
	root = bpy.data.collections.get(ROOT_NAME)
	if root:
		remove_collection_tree(root)
	root = bpy.data.collections.new(ROOT_NAME)
	bpy.context.scene.collection.children.link(root)
	materials = {
		"glass": make_material("Window glass", "#72BFD0", roughness=0.24, metallic=0.08),
		"tire": make_material("Tire rubber", "#30383A", roughness=0.78),
		"hub": make_material("Hub silver", "#C6CFCA", roughness=0.34, metallic=0.2),
		"trim": make_material("Charcoal trim", "#394347", roughness=0.52),
		"light": make_material("Warm headlights", "#FFF0B0", roughness=0.4),
		"tail": make_material("Tail lamps", "#D33F3A", roughness=0.4),
		"plate": make_material("Blank plates", "#E7E7D8", roughness=0.55),
	}
	os.makedirs(OUTPUT_DIR, exist_ok=True)
	report = {}
	for spec in VEHICLES:
		variant = build_vehicle(spec, root, materials)
		triangles = triangle_count(variant)
		minimum, maximum = world_bounds(variant)
		measured = [maximum.x - minimum.x, maximum.y - minimum.y, maximum.z - minimum.z]
		if triangles > TRIANGLE_LIMIT:
			raise RuntimeError(spec["name"] + " exceeds the triangle budget: " + str(triangles))
		if measured[0] > 1.95 or measured[1] > 4.2 or measured[2] > 1.7:
			raise RuntimeError(spec["name"] + " exceeds the parking-stall dimensions: " + str(measured))
		if abs(minimum.z) > 0.005:
			raise RuntimeError(spec["name"] + " does not sit on the ground plane: " + str(minimum.z))
		filepath = os.path.join(OUTPUT_DIR, spec["file"])
		export_vehicle(variant, filepath)
		report[spec["name"]] = {
			"triangles": triangles,
			"dimensions_m": [round(value, 3) for value in measured],
			"floor_min_z_m": round(minimum.z, 4),
			"path": filepath,
		}
	print("PARKING_CARS_REPORT", report)


build()
