class_name Store
extends Node3D
## Store-owned Demo greybox. Evan's fixed visual scenes can replace these cube
## placeholders later without moving Store collision, zones, or spawn markers.

const CATEGORY_NAMES: Array[String] = [
	"Produce",
	"Bakery",
	"Dairy",
	"Snacks",
	"Frozen",
	"Electronics",
]
const CATEGORY_COLORS: Array[Color] = [
	Color("4caf50"),
	Color("ff9800"),
	Color("f5f5f5"),
	Color("e53935"),
	Color("1e88e5"),
	Color("8e24aa"),
]
const AISLE_X_POSITIONS: Array[float] = [-12.5, -7.5, -2.5, 2.5, 7.5, 12.5]
const SHELF_SIZE := Vector3(0.7, 2.0, 14.0)
const SHELF_OFFSET_X: float = 2.1

@onready var _aisles: Node3D = $Aisles
@onready var _doors: Node3D = $Doors
@onready var _start_positions: Node3D = $StartPositions
@onready var _checkout_zone: Area3D = $CheckoutZone


func _ready() -> void:
	if _aisles.get_child_count() == 0:
		_build_world()


func get_start_transforms() -> Array[Transform3D]:
	var starts: Array[Transform3D] = []
	for child: Node in _start_positions.get_children():
		if child is Marker3D:
			starts.append((child as Marker3D).global_transform)
	return starts


func get_checkout_position() -> Vector3:
	return _checkout_zone.global_position


func _build_world() -> void:
	_build_floor_and_walls()
	_build_aisles()
	_build_doors()
	_build_start_positions()
	_build_checkout()


func _build_floor_and_walls() -> void:
	_make_box_body(self, "Floor", Vector3(0.0, -0.1, -5.0), Vector3(32.0, 0.2, 28.0), Color("fff6e0"))
	_make_box_body(self, "BackWall", Vector3(0.0, 1.5, -19.0), Vector3(32.0, 3.0, 0.4), Color("bdebd3"))
	_make_box_body(self, "LeftWall", Vector3(-16.0, 1.5, -5.0), Vector3(0.4, 3.0, 28.0), Color("bdebd3"))
	_make_box_body(self, "RightWall", Vector3(16.0, 1.5, -5.0), Vector3(0.4, 3.0, 28.0), Color("bdebd3"))
	_make_box_body(self, "FrontWallLeft", Vector3(-10.0, 1.5, 9.0), Vector3(12.0, 3.0, 0.4), Color("bdebd3"))
	_make_box_body(self, "FrontWallRight", Vector3(10.0, 1.5, 9.0), Vector3(12.0, 3.0, 0.4), Color("bdebd3"))


func _build_aisles() -> void:
	for index: int in CATEGORY_NAMES.size():
		var aisle := Node3D.new()
		aisle.name = CATEGORY_NAMES[index]
		aisle.position = Vector3(AISLE_X_POSITIONS[index], 0.0, 0.0)
		aisle.add_to_group("item_spawn_regions")
		aisle.set_meta("category", index)
		aisle.set_meta("spawn_min_z", -11.0)
		aisle.set_meta("spawn_max_z", 1.0)
		_aisles.add_child(aisle)

		_make_box_body(aisle, "LeftShelf", Vector3(-SHELF_OFFSET_X, 1.0, -5.0), SHELF_SIZE, CATEGORY_COLORS[index])
		_make_box_body(aisle, "RightShelf", Vector3(SHELF_OFFSET_X, 1.0, -5.0), SHELF_SIZE, CATEGORY_COLORS[index])
		_make_visual_box(aisle, "Sign", Vector3(0.0, 3.2, -12.0), Vector3(3.5, 0.8, 0.3), CATEGORY_COLORS[index])


func _build_doors() -> void:
	var left_door := Node3D.new()
	left_door.name = "LeftDoor"
	left_door.position = Vector3(-2.0, 0.0, 8.8)
	_doors.add_child(left_door)
	_make_box_body(left_door, "Body", Vector3(0.0, 1.5, 0.0), Vector3(4.0, 3.0, 0.3), Color("d32f2f"))

	var right_door := Node3D.new()
	right_door.name = "RightDoor"
	right_door.position = Vector3(2.0, 0.0, 8.8)
	_doors.add_child(right_door)
	_make_box_body(right_door, "Body", Vector3(0.0, 1.5, 0.0), Vector3(4.0, 3.0, 0.3), Color("ffd600"))


func _build_start_positions() -> void:
	var start_x_positions: Array[float] = [-4.5, -1.5, 1.5, 4.5]
	for index: int in start_x_positions.size():
		var marker := Marker3D.new()
		marker.name = "CartStart%d" % index
		marker.position = Vector3(start_x_positions[index], 0.0, 10.0)
		_start_positions.add_child(marker)


func _build_checkout() -> void:
	_checkout_zone.position = Vector3(0.0, 1.0, 13.0)
	var shape := BoxShape3D.new()
	shape.size = Vector3(10.0, 2.0, 4.0)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	_checkout_zone.add_child(collision)
	_make_visual_box(_checkout_zone, "Visual", Vector3.ZERO, shape.size, Color(0.15, 0.8, 0.25, 0.28), true)


func _make_box_body(parent: Node3D, node_name: String, body_position: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = body_position
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_to_group("store_world")
	parent.add_child(body)

	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	body.add_child(collision)
	_make_visual_box(body, "Visual", Vector3.ZERO, size, color)
	return body


func _make_visual_box(parent: Node3D, node_name: String, mesh_position: Vector3, size: Vector3, color: Color, transparent: bool = false) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var box := BoxMesh.new()
	box.size = size
	box.material = material
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	mesh.position = mesh_position
	mesh.mesh = box
	parent.add_child(mesh)
	return mesh
