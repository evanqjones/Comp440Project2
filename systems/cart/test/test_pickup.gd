extends Area3D
## TEST-ONLY pickup for systems/cart/test/ (Store's real Pickup replaces it in the game).
## Holds one random grocery; a Cart driving through calls try_add_item. Respawns 3 s after
## being taken. Categories and values follow GAME_SPEC.md §6 / §12.

const CATEGORIES := [
	GameTypes.Category.PRODUCE, GameTypes.Category.BAKERY, GameTypes.Category.DAIRY,
	GameTypes.Category.SNACKS, GameTypes.Category.FROZEN, GameTypes.Category.ELECTRONICS,
]
const VALUES := [5, 10, 10, 15, 20, 40]
const WEIGHTS := [30, 25, 25, 12, 6, 2]
const RESPAWN_SECONDS := 3.0

static var _next_id: int = 1

var item: ItemData

var _mesh: MeshInstance3D
var _material := StandardMaterial3D.new()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true) # pickups
	set_collision_mask_value(2, true) # carts
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.6
	shape.shape = sphere
	shape.position = Vector3(0.0, 0.4, 0.0)
	add_child(shape)
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.35
	_mesh.mesh = box
	_mesh.position = Vector3(0.0, 0.3, 0.0)
	_mesh.material_override = _material
	add_child(_mesh)
	body_entered.connect(_on_body_entered)
	_respawn()


func _respawn() -> void:
	item = ItemData.new()
	item.item_id = _next_id
	_next_id += 1
	var index := _weighted_index()
	item.category = CATEGORIES[index]
	item.value = VALUES[index]
	_material.albedo_color = CartItemStack.color_for(item)
	visible = true
	set_deferred("monitoring", true)


func _weighted_index() -> int:
	var roll := randi_range(1, 100)
	for i: int in WEIGHTS.size():
		roll -= WEIGHTS[i]
		if roll <= 0:
			return i
	return 0


func _on_body_entered(body: Node3D) -> void:
	if visible and body is Cart and (body as Cart).try_add_item(item):
		visible = false
		set_deferred("monitoring", false)
		get_tree().create_timer(RESPAWN_SECONDS).timeout.connect(_respawn)
