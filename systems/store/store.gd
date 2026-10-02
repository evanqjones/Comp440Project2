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
const AISLE_X_POSITIONS: Array[float] = [-18.75, -11.25, -3.75, 3.75, 11.25, 18.75]
const FIXTURE_OFFSETS_X: Array[float] = [3.025, 2.975, 3.28, 3.28, 3.26, 3.28]
const FIXTURE_WIDTHS: Array[float] = [1.45, 1.55, 0.94, 1.0, 0.98, 1.02]
const FIXTURE_DEPTH: float = 14.0
const FIXTURE_HEIGHT: float = 2.4
const DOOR_OPEN_OFFSET: float = 4.0
const DOOR_MOVE_DURATION: float = 0.5
const MAP_HALF_WIDTH: float = 30.25
const MAP_BACK_Z: float = -20.5
const MAP_FRONT_Z: float = 40.125
const FENCE_HEIGHT: float = 1.8
const FENCE_MAX_POST_SPACING: float = 2.0
const FENCE_POST_THICKNESS: float = 0.12
const FENCE_RAIL_THICKNESS: float = 0.08
const PICKUP_SCENE: PackedScene = preload("res://systems/store/pickup.tscn")
const PUDDLE_SCENE: PackedScene = preload("res://systems/store/hazards/slippery_puddle.tscn")
const FALLING_PALLET_SCENE: PackedScene = preload("res://systems/store/hazards/falling_pallet.tscn")
const HAZARD_FIRST_DELAY: float = 8.0
const HAZARD_BASE_INTERVAL_MIN: float = 10.0
const HAZARD_BASE_INTERVAL_MAX: float = 16.0
const HAZARD_INTERVAL_ESCALATION: float = 2.0
const HAZARD_MIN_INTERVAL: float = 6.0
const HAZARD_CART_CLEARANCE: float = 3.2
const HAZARD_CLEARANCE: float = 3.8
const HAZARD_SHELF_CLEARANCE: float = 1.6
const HAZARD_CHECKOUT_CLEARANCE: float = 6.0
const HAZARD_SPAWN_POINTS: Array[Vector3] = [
	Vector3(-18.75, 0.0, -5.0), Vector3(-11.25, 0.0, -5.0),
	Vector3(-3.75, 0.0, -5.0), Vector3(3.75, 0.0, -5.0),
	Vector3(11.25, 0.0, -5.0), Vector3(18.75, 0.0, -5.0),
]

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
var _hazard_seconds_until_spawn: float = HAZARD_FIRST_DELAY
var _last_hazard_was_puddle: bool = false
var _has_spawned_hazard: bool = false
var _hazard_rng := RandomNumberGenerator.new()


func _ready() -> void:
	_hazard_rng.randomize()
	if _aisles.get_child_count() == 0:
		_build_world()
	if get_node_or_null("ProductionStoreVisuals") != null:
		_hide_replaced_placeholder_visuals()
	_bake_navigation()
	_configure_doors()
	if RoundManager.is_gameplay_active():
		_on_hazard_phase_changed(RoundManager.phase)


func _physics_process(delta: float) -> void:
	_advance_hazard_schedule(delta)


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


## Environmental drops preserve each carried ItemData instance and ignore the regular floor cap.
func spawn_dropped_items(origin: Vector3, items: Array[ItemData]) -> void:
	if items.is_empty():
		return
	var count := items.size()
	for index: int in count:
		var item := items[index]
		if item == null:
			continue
		var pickup := PICKUP_SCENE.instantiate() as Pickup
		pickup.item = item
		add_child(pickup)
		var angle := TAU * float(index) / float(count)
		var radius := 0.55 + 0.12 * float(index % 3)
		pickup.global_position = origin + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)


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
	_make_box_body(self, "Floor", Vector3(0.0, -0.1, -5.0), Vector3(50.5, 0.2, 30.5), Color("fff6e0"))
	_make_box_body(self, "ParkingLotFloor", Vector3(0.0, -0.1, 20.125), Vector3(60.0, 0.2, 40.0), Color("555b60"))
	_make_box_body(self, "BackWall", Vector3(0.0, 1.5, -20.0), Vector3(50.5, 3.0, 0.4), Color("bdebd3"))
	_make_box_body(self, "LeftWall", Vector3(-25.25, 1.5, -5.0), Vector3(0.4, 3.0, 30.5), Color("bdebd3"))
	_make_box_body(self, "RightWall", Vector3(25.25, 1.5, -5.0), Vector3(0.4, 3.0, 30.5), Color("bdebd3"))
	_make_box_body(self, "FrontWallLeft", Vector3(-14.625, 1.5, 10.25), Vector3(21.25, 3.0, 0.4), Color("bdebd3"))
	_make_box_body(self, "FrontWallRight", Vector3(14.625, 1.5, 10.25), Vector3(21.25, 3.0, 0.4), Color("bdebd3"))
	_build_invisible_boundaries()
	_make_invisible_box_body(
		self,
		"BackFridgeBarrier",
		Vector3(0.0, 1.6, -18.35),
		Vector3(47.0, 3.2, 0.3)
	)


func _build_invisible_boundaries() -> void:
	var bounds := Node3D.new()
	bounds.name = "OutOfBounds"
	add_child(bounds)
	_make_invisible_box_body(
		bounds, "West", Vector3(-MAP_HALF_WIDTH, 1.5, (MAP_BACK_Z + MAP_FRONT_Z) * 0.5),
		Vector3(0.5, 3.0, MAP_FRONT_Z - MAP_BACK_Z)
	)
	_make_invisible_box_body(
		bounds, "East", Vector3(MAP_HALF_WIDTH, 1.5, (MAP_BACK_Z + MAP_FRONT_Z) * 0.5),
		Vector3(0.5, 3.0, MAP_FRONT_Z - MAP_BACK_Z)
	)
	_make_invisible_box_body(bounds, "Back", Vector3(0.0, 1.5, MAP_BACK_Z), Vector3(MAP_HALF_WIDTH * 2.0, 3.0, 0.5))
	_make_invisible_box_body(bounds, "Front", Vector3(0.0, 1.5, MAP_FRONT_Z), Vector3(MAP_HALF_WIDTH * 2.0, 3.0, 0.5))
	_build_perimeter_fence_visual(bounds)
	# Seal the strips between the wider parking lot and the narrower store shell.
	# Otherwise carts can drive beside the building, lose ground, and fall below
	# the outer wall colliders.
	_make_invisible_box_body(bounds, "WestStoreSide", Vector3(-27.625, 1.5, 0.375), Vector3(5.75, 3.0, 0.5))
	_make_invisible_box_body(bounds, "EastStoreSide", Vector3(27.625, 1.5, 0.375), Vector3(5.75, 3.0, 0.5))


## Low-poly metal rails mark the same edges as the invisible cart barriers above.
func _build_perimeter_fence_visual(parent: Node3D) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var post := BoxMesh.new()
	post.size = Vector3(FENCE_POST_THICKNESS, FENCE_HEIGHT, FENCE_POST_THICKNESS)
	_append_fence_side(surface, post, Vector3(-MAP_HALF_WIDTH, 0.0, MAP_BACK_Z), Vector3(MAP_HALF_WIDTH, 0.0, MAP_BACK_Z), true)
	_append_fence_side(surface, post, Vector3(MAP_HALF_WIDTH, 0.0, MAP_BACK_Z), Vector3(MAP_HALF_WIDTH, 0.0, MAP_FRONT_Z), false)
	_append_fence_side(surface, post, Vector3(MAP_HALF_WIDTH, 0.0, MAP_FRONT_Z), Vector3(-MAP_HALF_WIDTH, 0.0, MAP_FRONT_Z), true)
	_append_fence_side(surface, post, Vector3(-MAP_HALF_WIDTH, 0.0, MAP_FRONT_Z), Vector3(-MAP_HALF_WIDTH, 0.0, MAP_BACK_Z), false)
	var fence_mesh := surface.commit()
	if fence_mesh == null:
		push_error("Could not build the Store perimeter fence mesh")
		return
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color("#53666A")
	metal.metallic = 0.35
	metal.roughness = 0.5
	fence_mesh.surface_set_material(0, metal)
	var fence := MeshInstance3D.new()
	fence.name = "PerimeterFenceVisual"
	fence.mesh = fence_mesh
	fence.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(fence)


func _append_fence_side(surface: SurfaceTool, post: BoxMesh, start: Vector3, finish: Vector3, runs_along_x: bool) -> void:
	var length := start.distance_to(finish)
	var section_count := maxi(1, ceili(length / FENCE_MAX_POST_SPACING))
	var section_length := length / float(section_count)
	for index: int in section_count + 1:
		var post_position := start.lerp(finish, float(index) / float(section_count))
		post_position.y = FENCE_HEIGHT * 0.5
		surface.append_from(post, 0, Transform3D(Basis.IDENTITY, post_position))
	var rail := BoxMesh.new()
	rail.size = Vector3(section_length, FENCE_RAIL_THICKNESS, FENCE_RAIL_THICKNESS) if runs_along_x else Vector3(FENCE_RAIL_THICKNESS, FENCE_RAIL_THICKNESS, section_length)
	var rail_heights: Array[float] = [0.55, 1.45]
	for index: int in section_count:
		var midpoint := start.lerp(finish, (float(index) + 0.5) / float(section_count))
		for height: float in rail_heights:
			midpoint.y = height
			surface.append_from(rail, 0, Transform3D(Basis.IDENTITY, midpoint))


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

		var fixture_size := Vector3(FIXTURE_WIDTHS[index], FIXTURE_HEIGHT, FIXTURE_DEPTH)
		var left_shelf := _make_box_body(
			aisle,
			"LeftShelf",
			Vector3(-FIXTURE_OFFSETS_X[index], FIXTURE_HEIGHT * 0.5, -5.0),
			fixture_size,
			CATEGORY_COLORS[index]
		)
		left_shelf.add_to_group("store_shelves")
		var right_shelf := _make_box_body(
			aisle,
			"RightShelf",
			Vector3(FIXTURE_OFFSETS_X[index], FIXTURE_HEIGHT * 0.5, -5.0),
			fixture_size,
			CATEGORY_COLORS[index]
		)
		right_shelf.add_to_group("store_shelves")
		_make_visual_box(aisle, "Sign", Vector3(0.0, 3.2, -12.0), Vector3(3.5, 0.8, 0.3), CATEGORY_COLORS[index])


func _build_doors() -> void:
	var left_door := Node3D.new()
	left_door.name = "LeftDoor"
	left_door.position = Vector3(-2.0, 0.0, 10.25)
	_doors.add_child(left_door)
	_make_box_body(left_door, "Body", Vector3(0.0, 1.5, 0.0), Vector3(4.0, 3.0, 0.3), Color("d32f2f"), false)

	var right_door := Node3D.new()
	right_door.name = "RightDoor"
	right_door.position = Vector3(2.0, 0.0, 10.25)
	_doors.add_child(right_door)
	_make_box_body(right_door, "Body", Vector3(0.0, 1.5, 0.0), Vector3(4.0, 3.0, 0.3), Color("ffd600"), false)


func _build_start_positions() -> void:
	var start_x_positions: Array[float] = [-3.0, -1.0, 1.0, 3.0]
	for index: int in start_x_positions.size():
		var marker := Marker3D.new()
		marker.name = "CartStart%d" % index
		marker.position = Vector3(start_x_positions[index], 0.0, 11.5)
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
	_on_hazard_phase_changed(next_phase)


func _on_hazard_phase_changed(next_phase: GameTypes.Phase) -> void:
	if next_phase == GameTypes.Phase.RUSH:
		_hazard_seconds_until_spawn = HAZARD_FIRST_DELAY
		_has_spawned_hazard = false
		_last_hazard_was_puddle = false
	elif next_phase != GameTypes.Phase.FINAL_CALL:
		_cleanup_hazards()


func _advance_hazard_schedule(active_delta: float) -> void:
	if not RoundManager.is_gameplay_active() or active_delta <= 0.0:
		return
	_hazard_seconds_until_spawn -= active_delta
	if _hazard_seconds_until_spawn > 0.0:
		return
	# Skip safely when all curated floor points are occupied. Never catch up later.
	var spawn_position := _select_hazard_spawn_position()
	if spawn_position != Vector3.INF:
		_spawn_random_hazard(spawn_position)
	_hazard_seconds_until_spawn = _next_hazard_interval()


func _next_hazard_interval() -> float:
	var bounds := _hazard_interval_bounds(RoundManager.round_number)
	return _hazard_rng.randf_range(bounds.x, bounds.y)


func _hazard_interval_bounds(round_index: int) -> Vector2:
	var escalation := float(maxi(round_index - 1, 0)) * HAZARD_INTERVAL_ESCALATION
	var minimum := maxf(HAZARD_MIN_INTERVAL, HAZARD_BASE_INTERVAL_MIN - escalation)
	var maximum := maxf(minimum, HAZARD_BASE_INTERVAL_MAX - escalation)
	return Vector2(minimum, maximum)


func _select_hazard_spawn_position() -> Vector3:
	var available: Array[Vector3] = []
	for local_point: Vector3 in HAZARD_SPAWN_POINTS:
		var point := to_global(local_point)
		var point_blocked := not _is_hazard_point_clear(point)
		for cart: Cart in RoundManager.get_carts():
			if is_instance_valid(cart) and cart.global_position.distance_to(point) < HAZARD_CART_CLEARANCE:
				point_blocked = true
				break
		if point_blocked:
			continue
		for hazard: Node in get_tree().get_nodes_in_group("stage_hazards"):
			if is_instance_valid(hazard) and hazard is Node3D and (hazard as Node3D).global_position.distance_to(point) < HAZARD_CLEARANCE:
				point_blocked = true
				break
		if not point_blocked:
			available.append(local_point)
	if available.is_empty():
		return Vector3.INF
	return available[_hazard_rng.randi_range(0, available.size() - 1)]


func _is_hazard_point_clear(point: Vector3) -> bool:
	var local_point := to_local(point)
	if absf(local_point.x) > 24.0 or local_point.z < -19.0 or local_point.z > 9.0:
		return false
	if point.distance_to(_checkout_zone.global_position) < HAZARD_CHECKOUT_CLEARANCE:
		return false
	for shelf: Node in get_tree().get_nodes_in_group("store_shelves"):
		if not is_instance_valid(shelf) or not shelf is StaticBody3D:
			continue
		var collision := shelf.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if collision == null or not collision.shape is BoxShape3D:
			continue
		var half_size := (collision.shape as BoxShape3D).size * 0.5
		var offset := (shelf as StaticBody3D).to_local(point) - collision.position
		var dx := maxf(absf(offset.x) - half_size.x, 0.0)
		var dz := maxf(absf(offset.z) - half_size.z, 0.0)
		if Vector2(dx, dz).length() < HAZARD_SHELF_CLEARANCE:
			return false
	return true


func _spawn_random_hazard(local_position: Vector3) -> void:
	# Both actor types use the same curated floor points, so avoid repeats by alternating.
	var puddle := _hazard_rng.randf() < 0.5 if not _has_spawned_hazard else not _last_hazard_was_puddle
	var packed_scene := PUDDLE_SCENE if puddle else FALLING_PALLET_SCENE
	var hazard := packed_scene.instantiate() as Node3D
	if hazard == null:
		return
	hazard.add_to_group("stage_hazards")
	add_child(hazard)
	hazard.global_position = to_global(local_position)
	_last_hazard_was_puddle = puddle
	_has_spawned_hazard = true
	RoundManager.hazard_spawned.emit(hazard)


func _cleanup_hazards() -> void:
	for hazard: Node in get_tree().get_nodes_in_group("stage_hazards"):
		if is_instance_valid(hazard):
			hazard.queue_free()


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


func _make_invisible_box_body(parent: Node3D, node_name: String, body_position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = body_position
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_to_group("store_world")
	body.add_to_group("navigation_source")
	parent.add_child(body)

	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	body.add_child(collision)
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
