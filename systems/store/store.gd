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
const DOOR_OPEN_OFFSET: float = 4.0
const DOOR_MOVE_DURATION: float = 0.5
const PICKUP_SCENE: PackedScene = preload("res://systems/store/pickup.tscn")

@onready var _aisles: Node3D = $Aisles
@onready var _doors: Node3D = $Doors
@onready var _start_positions: Node3D = $StartPositions
@onready var _checkout_zone: Area3D = $CheckoutZone
@onready var _navigation_region: NavigationRegion3D = $NavigationRegion3D

var _left_door: Node3D
var _right_door: Node3D
var _left_closed_position := Vector3.ZERO
var _right_closed_position := Vector3.ZERO
var _door_tween: Tween


func _ready() -> void:
	if _aisles.get_child_count() == 0:
		_build_world()
	if get_node_or_null("ProductionStoreVisuals") != null:
		_hide_replaced_placeholder_visuals()
	_bake_navigation()
	_configure_doors()


func _exit_tree() -> void:
	if RoundManager.phase_changed.is_connected(_on_phase_changed):
		RoundManager.phase_changed.disconnect(_on_phase_changed)
	if _door_tween != null and _door_tween.is_valid():
		_door_tween.kill()


func get_start_transforms() -> Array[Transform3D]:
	var starts: Array[Transform3D] = []
	for child: Node in _start_positions.get_children():
		if child is Marker3D:
			starts.append((child as Marker3D).global_transform)
	return starts


func get_checkout_position() -> Vector3:
	return _checkout_zone.global_position


func spawn_pickup(item: ItemData) -> Pickup:
	if item == null or int(item.category) < 0 or int(item.category) >= CATEGORY_NAMES.size():
		return null
	var aisle := _aisles.get_child(int(item.category)) as Node3D
	if aisle == null:
		return null
	var pickup := PICKUP_SCENE.instantiate() as Pickup
	pickup.item = item
	pickup.position = Vector3(
		randf_range(-1.6, 1.6),
		0.0,
		randf_range(float(aisle.get_meta("spawn_min_z")), float(aisle.get_meta("spawn_max_z")))
	)
	aisle.add_child(pickup)
	return pickup


func _build_world() -> void:
	_build_floor_and_walls()
	_build_aisles()
	_build_doors()
	_build_start_positions()
	_build_checkout()


func _hide_replaced_placeholder_visuals() -> void:
	# Keep the greybox physics and navigation, but let the authored art provide
	# the visible floor, walls, shelves, and aisle signs.
	for child: Node in get_children():
		var body := child as StaticBody3D
		if body == null or not body.is_in_group("store_world"):
			continue
		var visual := body.get_node_or_null("Visual") as MeshInstance3D
		if visual != null:
			visual.visible = false

	for node: Node in _aisles.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh != null:
			mesh.visible = false


func _build_floor_and_walls() -> void:
	_make_box_body(self, "Floor", Vector3(0.0, -0.1, -2.0), Vector3(32.0, 0.2, 34.0), Color("fff6e0"))
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

		var left_shelf := _make_box_body(aisle, "LeftShelf", Vector3(-SHELF_OFFSET_X, 1.0, -5.0), SHELF_SIZE, CATEGORY_COLORS[index])
		left_shelf.add_to_group("store_shelves")
		var right_shelf := _make_box_body(aisle, "RightShelf", Vector3(SHELF_OFFSET_X, 1.0, -5.0), SHELF_SIZE, CATEGORY_COLORS[index])
		right_shelf.add_to_group("store_shelves")
		_make_visual_box(aisle, "Sign", Vector3(0.0, 3.2, -12.0), Vector3(3.5, 0.8, 0.3), CATEGORY_COLORS[index])


func _build_doors() -> void:
	var left_door := Node3D.new()
	left_door.name = "LeftDoor"
	left_door.position = Vector3(-2.0, 0.0, 8.8)
	_doors.add_child(left_door)
	_make_box_body(left_door, "Body", Vector3(0.0, 1.5, 0.0), Vector3(4.0, 3.0, 0.3), Color("d32f2f"), false)

	var right_door := Node3D.new()
	right_door.name = "RightDoor"
	right_door.position = Vector3(2.0, 0.0, 8.8)
	_doors.add_child(right_door)
	_make_box_body(right_door, "Body", Vector3(0.0, 1.5, 0.0), Vector3(4.0, 3.0, 0.3), Color("ffd600"), false)


func _build_start_positions() -> void:
	var start_x_positions: Array[float] = [-3.0, -1.0, 1.0, 3.0]
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


func _bake_navigation() -> void:
	var navigation_mesh := NavigationMesh.new()
	navigation_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	navigation_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	navigation_mesh.geometry_source_group_name = &"navigation_source"
	navigation_mesh.geometry_collision_mask = 1
	navigation_mesh.agent_radius = 0.75
	navigation_mesh.agent_height = 2.0
	navigation_mesh.agent_max_climb = 0.25
	_navigation_region.navigation_mesh = navigation_mesh
	# Synchronous baking works on the web target, where project threads are disabled.
	_navigation_region.bake_navigation_mesh(false)


func _configure_doors() -> void:
	_left_door = _doors.get_node("LeftDoor") as Node3D
	_right_door = _doors.get_node("RightDoor") as Node3D
	_left_closed_position = _left_door.position
	_right_closed_position = _right_door.position
	if not RoundManager.phase_changed.is_connected(_on_phase_changed):
		RoundManager.phase_changed.connect(_on_phase_changed)
	_apply_door_state(RoundManager.is_gameplay_active(), false)


func _on_phase_changed(next_phase: GameTypes.Phase) -> void:
	var open := next_phase == GameTypes.Phase.RUSH or next_phase == GameTypes.Phase.FINAL_CALL
	_apply_door_state(open, true)


func _apply_door_state(open: bool, animate: bool) -> void:
	RoundManager.doors_open = open
	_set_door_collision(_left_door, not open)
	_set_door_collision(_right_door, not open)
	var left_target := _left_closed_position + Vector3.LEFT * DOOR_OPEN_OFFSET if open else _left_closed_position
	var right_target := _right_closed_position + Vector3.RIGHT * DOOR_OPEN_OFFSET if open else _right_closed_position
	if _door_tween != null and _door_tween.is_valid():
		_door_tween.kill()
	if not animate:
		_left_door.position = left_target
		_right_door.position = right_target
		return
	_door_tween = create_tween().set_parallel(true)
	_door_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_door_tween.tween_property(_left_door, "position", left_target, DOOR_MOVE_DURATION)
	_door_tween.tween_property(_right_door, "position", right_target, DOOR_MOVE_DURATION)


func _set_door_collision(door: Node3D, enabled: bool) -> void:
	var collision := door.get_node("Body/CollisionShape3D") as CollisionShape3D
	collision.set_deferred("disabled", not enabled)


func _make_box_body(parent: Node3D, node_name: String, body_position: Vector3, size: Vector3, color: Color, navigation_source: bool = true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = body_position
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_to_group("store_world")
	if navigation_source:
		body.add_to_group("navigation_source")
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
