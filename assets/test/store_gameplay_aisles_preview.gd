extends Node3D
## Playable asset preview: the existing demo supplies movement, bots and collisions;
## this scene uses Evan's shelf-matched products for floor pickups and cart loads.

const ITEM_VISUALS: Array[PackedScene] = [
	preload("res://assets/models/items/produce_visual.tscn"),
	preload("res://assets/models/items/bakery_visual.tscn"),
	preload("res://assets/models/items/dairy_visual.tscn"),
	preload("res://assets/models/items/snacks_visual.tscn"),
	preload("res://assets/models/items/frozen_visual.tscn"),
	preload("res://assets/models/items/electronics_visual.tscn"),
]

const DEMO_PICKUP_SCRIPT := "res://systems/cart/test/test_pickup.gd"
const CART_ITEM_SIZE := 0.22
const CART_ITEM_SPACING := 0.24

var _pickup_visual_ids: Dictionary[int, bool] = {}
var _cart_item_roots: Dictionary[int, Node3D] = {}
var _cart_signatures: Dictionary[int, String] = {}

func _ready() -> void:
	_hide_demo_shelf_visuals()
	_hide_demo_lane_stripes()
	_hide_aisle_floor_trim()
	_sync_demo_pickups()
	_sync_cart_item_visuals()


func _process(_delta: float) -> void:
	_sync_demo_pickups()
	_sync_cart_item_visuals()


func _visual_scene_for(item: ItemData) -> PackedScene:
	if item == null or item.is_deal or item.category == GameTypes.Category.DEAL:
		return null
	var category_index: int = int(item.category)
	if category_index < 0 or category_index >= ITEM_VISUALS.size():
		return null
	return ITEM_VISUALS[category_index]


func _sync_demo_pickups() -> void:
	for pickup_node: Node in $DemoRound.find_children("*", "Area3D", true, false):
		var pickup_script := pickup_node.get_script() as Script
		if pickup_script == null or pickup_script.resource_path != DEMO_PICKUP_SCRIPT:
			continue
		var pickup_id: int = pickup_node.get_instance_id()
		if _pickup_visual_ids.has(pickup_id):
			continue
		var item := pickup_node.get("item") as ItemData
		var visual_scene := _visual_scene_for(item)
		if visual_scene == null:
			continue
		for child: Node in pickup_node.get_children():
			var mesh := child as MeshInstance3D
			if mesh != null:
				mesh.visible = false
		var visual := visual_scene.instantiate() as Node3D
		if visual == null:
			continue
		pickup_node.add_child(visual)
		_pickup_visual_ids[pickup_id] = true


func _sync_cart_item_visuals() -> void:
	for cart_node: Node in $DemoRound.find_children("*", "CharacterBody3D", true, false):
		var cart := cart_node as Cart
		if cart == null:
			continue
		var stack := cart.get_node_or_null("ItemStackDisplay") as Node3D
		if stack == null:
			continue
		var cart_id: int = cart.get_instance_id()
		for child: Node in stack.get_children():
			var cube := child as MeshInstance3D
			if cube != null:
				cube.visible = false
		if not _cart_item_roots.has(cart_id):
			var item_root := Node3D.new()
			item_root.name = "ShelfProductStackPreview"
			stack.add_child(item_root)
			_cart_item_roots[cart_id] = item_root
		var items: Array[ItemData] = cart.get_state().items
		var signature := _items_signature(items)
		if _cart_signatures.get(cart_id, "") == signature:
			continue
		_cart_signatures[cart_id] = signature
		_refresh_cart_item_visuals(_cart_item_roots[cart_id], items)


func _items_signature(items: Array[ItemData]) -> String:
	var parts: Array[String] = []
	for item: ItemData in items:
		parts.append("%d:%d:%s" % [item.item_id, int(item.category), str(item.is_deal)])
	return ",".join(parts)


func _refresh_cart_item_visuals(item_root: Node3D, items: Array[ItemData]) -> void:
	for child: Node in item_root.get_children():
		child.queue_free()
	for index: int in mini(items.size(), 24):
		var visual_scene := _visual_scene_for(items[index])
		if visual_scene == null:
			continue
		var visual := visual_scene.instantiate() as Node3D
		if visual == null:
			continue
		var layer: int = floori(float(index) / 6.0)
		var slot: int = index % 6
		var column: int = slot % 3
		var row: int = floori(float(slot) / 3.0)
		visual.position = Vector3(
			float(column - 1) * CART_ITEM_SPACING,
			CART_ITEM_SIZE * 0.5 + float(layer) * CART_ITEM_SPACING,
			(float(row) - 0.5) * CART_ITEM_SPACING
		)
		visual.scale = Vector3.ONE * 0.5
		item_root.add_child(visual)


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
