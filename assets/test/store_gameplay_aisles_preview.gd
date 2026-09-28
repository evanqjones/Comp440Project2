extends Node3D
## Playable asset preview: the existing demo supplies movement, bots and collisions;
## this scene swaps its greybox shelf visuals for Evan's six modeled aisles.

func _ready() -> void:
	_hide_demo_shelf_visuals()
	_hide_demo_lane_stripes()
	_hide_aisle_floor_trim()


func _hide_demo_shelf_visuals() -> void:
	var nav_regions: Array[Node] = $DemoRound.find_children("*", "NavigationRegion3D", false, false)
	if nav_regions.is_empty():
		push_error("Playable aisle preview could not find the demo's navigation region.")
		return
	var nav_region := nav_regions[0] as NavigationRegion3D
	for body_node: Node in nav_region.get_children():
		var body := body_node as StaticBody3D
		if body == null:
			continue
		var collision: CollisionShape3D
		for child: Node in body.get_children():
			if child is CollisionShape3D:
				collision = child as CollisionShape3D
		var box_shape: BoxShape3D
		if collision != null:
			box_shape = collision.shape as BoxShape3D
		if box_shape == null or not box_shape.size.is_equal_approx(Vector3(1.0, 2.0, 14.0)):
			continue
		for child: Node in body.get_children():
			var mesh_instance := child as MeshInstance3D
			if mesh_instance != null:
				mesh_instance.visible = false


func _hide_demo_lane_stripes() -> void:
	for child: Node in $DemoRound.get_children():
		var mesh_instance := child as MeshInstance3D
		if mesh_instance != null and mesh_instance.mesh is BoxMesh:
			var box_mesh := mesh_instance.mesh as BoxMesh
			if box_mesh.size.is_equal_approx(Vector3(4.0, 0.02, 14.0)):
				mesh_instance.visible = false


func _hide_aisle_floor_trim() -> void:
	var aisle_scene: Node = $AislesVisual
	for node: Node in aisle_scene.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		var node_name := mesh_instance.name.to_lower()
		if "aisle floor" in node_name or "aisle edge" in node_name or "floor tile seam" in node_name:
			mesh_instance.visible = false
