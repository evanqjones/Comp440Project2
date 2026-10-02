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
	if item.is_deal:
		_dress_deal(visual_root, placeholder, material)


## Deal of the Day (store/06-deal-of-the-day): a glowing gold box that spins under a beam you can
## see across the store. The beam is an unshaded, additive mesh, not a light (web budget).
func _dress_deal(visual_root: Node3D, box: MeshInstance3D, material: StandardMaterial3D) -> void:
	material.emission_enabled = true
	material.emission = CATEGORY_COLORS[GameTypes.Category.DEAL]
	material.emission_energy_multiplier = 0.6
	box.scale = Vector3.ONE * 1.4
	var spin := box.create_tween().set_loops()
	spin.tween_property(box, "rotation:y", TAU, 2.5).from(0.0)
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.18
	cylinder.bottom_radius = 0.32
	cylinder.height = 9.0
	cylinder.radial_segments = 12
	cylinder.cap_top = false
	cylinder.cap_bottom = false
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow.cull_mode = BaseMaterial3D.CULL_DISABLED
	glow.albedo_color = Color(1.0, 0.84, 0.2, 0.35)
	var beam := MeshInstance3D.new()
	beam.name = "Beam"
	beam.mesh = cylinder
	beam.material_override = glow
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.position = Vector3(0.0, cylinder.height / 2.0, 0.0)
	visual_root.add_child(beam)


func _init() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true) # pickups
	set_collision_mask_value(2, true) # carts
