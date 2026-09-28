"""Export compact pickup models from the shelf products in Assets.blend.

Run from the repository root with Blender in background mode. The script
copies source meshes in memory, centers and scales each copy, and exports six
GLBs without saving changes back into Assets.blend.
"""

import os

import bpy
from mathutils import Vector


OUTPUT_DIR = os.path.join(os.path.dirname(bpy.data.filepath), "assets", "models", "items")
TARGET_SIZE = 0.42
ITEMS = {
	"produce": ["Fresh produce"],
	"bakery": ["Bakery loaf"],
	"dairy": ["Cold drink carton", "Carton cap"],
	"snacks": ["Potato chips bag", "Bag front label"],
	"frozen": ["Frozen pizza box", "Pizza front panel"],
	"electronics": ["Game console", "Console power light"],
}


def world_corners(obj):
	return [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]


def export_item(category, source_names, export_collection):
	source_objects = [bpy.data.objects.get(name) for name in source_names]
	if any(source is None or source.type != "MESH" for source in source_objects):
		missing = [name for name, source in zip(source_names, source_objects) if source is None]
		raise RuntimeError("Missing shelf model objects: " + ", ".join(missing))

	base = source_objects[0].matrix_world.translation.copy()
	duplicates = []
	for source in source_objects:
		duplicate = source.copy()
		duplicate.data = source.data
		export_collection.objects.link(duplicate)
		duplicate.matrix_world = source.matrix_world.copy()
		duplicates.append(duplicate)

	# Recenter in X/Y and put the lowest mesh point at the floor origin.
	bpy.context.view_layer.update()
	lowest_z = min(point.z for obj in duplicates for point in world_corners(obj))
	for obj in duplicates:
		obj.location.x -= base.x
		obj.location.y -= base.y
		obj.location.z -= lowest_z
	bpy.context.view_layer.update()

	points = [point for obj in duplicates for point in world_corners(obj)]
	maximum_dimension = max(
		max(point.x for point in points) - min(point.x for point in points),
		max(point.y for point in points) - min(point.y for point in points),
		max(point.z for point in points) - min(point.z for point in points),
	)
	if maximum_dimension <= 0.0:
		raise RuntimeError("Degenerate pickup model: " + category)
	factor = TARGET_SIZE / maximum_dimension
	for obj in duplicates:
		obj.location *= factor
		obj.scale *= factor
	bpy.context.view_layer.update()

	bpy.ops.object.select_all(action="DESELECT")
	for obj in duplicates:
		obj.select_set(True)
	bpy.context.view_layer.objects.active = duplicates[0]
	output_path = os.path.join(OUTPUT_DIR, category + "_item.glb")
	bpy.ops.export_scene.gltf(
		filepath=output_path,
		export_format="GLB",
		use_selection=True,
		export_apply=True,
		export_materials="EXPORT",
		export_cameras=False,
		export_lights=False,
	)
	print("EXPORTED_PICKUP", category, output_path, "size", TARGET_SIZE, "parts", len(duplicates))
	for obj in duplicates:
		bpy.data.objects.remove(obj, do_unlink=True)


def main():
	os.makedirs(OUTPUT_DIR, exist_ok=True)
	export_collection = bpy.data.collections.new("__CC Pickup Export Temporary")
	bpy.context.scene.collection.children.link(export_collection)
	try:
		for category, source_names in ITEMS.items():
			export_item(category, source_names, export_collection)
	finally:
		bpy.data.collections.remove(export_collection)


main()
