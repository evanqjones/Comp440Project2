class_name Pickup
extends Area3D
## A grocery item lying on the store floor (docs/CONTRACTS.md §3.1).
##
## A Cart can claim this item only during active gameplay. A rejected collection leaves the
## pickup available for another cart; a successful collection removes it from the live registry
## before it is queued for deletion.

const CATEGORY_COLORS: Array[Color] = [
	Color("4caf50"),
	Color("ff9800"),
	Color("f5f5f5"),
	Color("e53935"),
	Color("1e88e5"),
	Color("8e24aa"),
	Color("ffd600"),
]
const CATEGORY_VISUALS: Array[PackedScene] = [
	preload("res://assets/models/items/produce_visual.tscn"),
	preload("res://assets/models/items/bakery_visual.tscn"),
	preload("res://assets/models/items/dairy_visual.tscn"),
	preload("res://assets/models/items/snacks_visual.tscn"),
	preload("res://assets/models/items/frozen_visual.tscn"),
	preload("res://assets/models/items/electronics_visual.tscn"),
]
const DEAL_LABEL: String = "DEAL OF THE DAY!"
const DEAL_GOLD := Color("e6b422")

var item: ItemData
var _taken: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	RoundManager._register_pickup(self)
	_update_visual()


func _exit_tree() -> void:
	if is_instance_valid(RoundManager):
		RoundManager._unregister_pickup(self)


func is_taken() -> bool:
	return _taken


func _on_body_entered(body: Node3D) -> void:
	if _taken or not RoundManager.is_gameplay_active() or item == null:
		return
	var cart := body as Cart
	if cart == null or not cart.try_add_item(item):
		return
	_taken = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	RoundManager._unregister_pickup(self)
	queue_free()


func _update_visual() -> void:
	if item == null:
		return
	var visual_root := get_node_or_null("Visual") as Node3D
	if visual_root == null:
		return
	var category_index := clampi(int(item.category), 0, CATEGORY_COLORS.size() - 1)
	if item.category == GameTypes.Category.DEAL:
		_add_deal_presentation(visual_root)
		return
	if category_index < CATEGORY_VISUALS.size():
		var placeholder := visual_root.get_node_or_null("PlaceholderMesh") as MeshInstance3D
		if placeholder != null:
			placeholder.visible = false
		var visual := CATEGORY_VISUALS[category_index].instantiate()
		visual_root.add_child(visual)
		return
	var placeholder := visual_root.get_node_or_null("PlaceholderMesh") as MeshInstance3D
	if placeholder == null:
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = CATEGORY_COLORS[category_index]
	material.roughness = 0.8
	placeholder.material_override = material


func _add_deal_presentation(visual_root: Node3D) -> void:
	var placeholder := visual_root.get_node_or_null("PlaceholderMesh") as MeshInstance3D
	if placeholder != null:
		var material := StandardMaterial3D.new()
		material.albedo_color = DEAL_GOLD
		material.metallic = 0.85
		material.roughness = 0.12
		material.emission_enabled = true
		material.emission = DEAL_GOLD
		material.emission_energy_multiplier = 2.5
		placeholder.material_override = material
		placeholder.scale = Vector3.ONE * 1.35
	var beam := MeshInstance3D.new()
	beam.name = "DealBeam"
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.18
	beam_mesh.bottom_radius = 0.4
	beam_mesh.height = 2.2
	beam.mesh = beam_mesh
	beam.position = Vector3(0.0, 1.15, 0.0)
	var beam_material := StandardMaterial3D.new()
	beam_material.albedo_color = Color(DEAL_GOLD, 0.28)
	beam_material.emission_enabled = true
	beam_material.emission = DEAL_GOLD
	beam_material.emission_energy_multiplier = 2.0
	beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = beam_material
	visual_root.add_child(beam)
	var marker := Label3D.new()
	marker.name = "DealMarker"
	marker.text = DEAL_LABEL
	marker.position = Vector3(0.0, 2.8, 0.0)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.font_size = 64
	marker.outline_size = 12
	marker.modulate = DEAL_GOLD
	marker.outline_modulate = Color.BLACK
	visual_root.add_child(marker)


func _init() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true) # pickups
	set_collision_mask_value(2, true) # carts
