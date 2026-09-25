class_name CartItemStack
extends Node3D
## Shows a cart's items as small colored cubes stacked in the basket
## (docs/features/cart/02-inventory/01-spec.md §3). A pool of 24 cubes is built once and
## shown or hidden, so pickups don't allocate. Colors come from ASSETS.md §3. Evan's item
## models can replace the cubes later.
## Place it as a child of the Cart. On ready it moves to the `anchor` marker (the basket's
## ItemStack) if one exists.

const MAX_CUBES := 24
const CUBE_SIZE := 0.22
const SPACING := 0.24
const COLORS := {
	GameTypes.Category.PRODUCE: Color("#4CAF50"),
	GameTypes.Category.BAKERY: Color("#FF9800"),
	GameTypes.Category.DAIRY: Color("#F5F5F5"),
	GameTypes.Category.SNACKS: Color("#E53935"),
	GameTypes.Category.FROZEN: Color("#1E88E5"),
	GameTypes.Category.ELECTRONICS: Color("#8E24AA"),
	GameTypes.Category.DEAL: Color("#E6B422"),
}

## The basket's ItemStack marker (inside Visual). Empty or missing = stay where placed.
@export var anchor: NodePath = NodePath("../Visual/ItemStack")

static var _materials: Dictionary = {}

var _cubes: Array[MeshInstance3D] = []


func _ready() -> void:
	var marker := get_node_or_null(anchor) as Node3D
	if marker != null:
		global_transform = marker.global_transform
	_ensure_cubes()


## Shows the first MAX_CUBES items, oldest at the bottom.
func show_items(items: Array[ItemData]) -> void:
	_ensure_cubes()
	for i: int in _cubes.size():
		var cube := _cubes[i]
		cube.visible = i < items.size()
		if cube.visible:
			cube.material_override = _material_for(items[i])


func visible_count() -> int:
	var shown := 0
	for cube: MeshInstance3D in _cubes:
		if cube.visible:
			shown += 1
	return shown


## Palette color for an item; a Deal of the Day is always gold.
static func color_for(item: ItemData) -> Color:
	var category := GameTypes.Category.DEAL if item.is_deal else item.category
	return COLORS[category]


static func _material_for(item: ItemData) -> StandardMaterial3D:
	var color := color_for(item)
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		_materials[color] = material
	return _materials[color]


## 3 across (x) × 2 deep (z) × 4 high (y), filled bottom layer first.
func _ensure_cubes() -> void:
	if not _cubes.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * CUBE_SIZE
	for i: int in MAX_CUBES:
		var layer := floori(i / 6.0)
		var slot := i % 6
		var column := slot % 3
		var row := floori(slot / 3.0)
		var cube := MeshInstance3D.new()
		cube.mesh = mesh
		cube.position = Vector3((column - 1) * SPACING, CUBE_SIZE / 2.0 + layer * SPACING, (row - 0.5) * SPACING)
		cube.visible = false
		add_child(cube)
		_cubes.append(cube)
