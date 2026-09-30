extends Node3D
## Store-owned Final hazard gameplay. Visual assets replace these colored meshes later.

signal cleared(hazard: Node3D)

enum Kind { WET_FLOOR, PALLET_JACK, FALLING_DISPLAY }

const WET_FLOOR_DURATION: float = 8.0
const PALLET_JACK_DURATION: float = 6.0
const DISPLAY_WARNING_DURATION: float = 1.0
const DISPLAY_BLOCK_DURATION: float = 5.0

@export var hazard_kind: Kind = Kind.WET_FLOOR

var is_blocking: bool = false
var _elapsed: float = 0.0
var _cleared: bool = false
var _body: CollisionObject3D
var _collision: CollisionShape3D


func _ready() -> void:
	match hazard_kind:
		Kind.WET_FLOOR:
			_build_wet_floor()
		Kind.PALLET_JACK:
			_build_pallet_jack()
		Kind.FALLING_DISPLAY:
			_build_falling_display()


func _physics_process(delta: float) -> void:
	if _cleared:
		return
	_elapsed += maxf(delta, 0.0)
	match hazard_kind:
		Kind.WET_FLOOR:
			if _elapsed >= WET_FLOOR_DURATION:
				clear_hazard()
		Kind.PALLET_JACK:
			if _body != null:
				_body.position.x = lerpf(-3.0, 3.0, clampf(_elapsed / PALLET_JACK_DURATION, 0.0, 1.0))
			if _elapsed >= PALLET_JACK_DURATION:
				clear_hazard()
		Kind.FALLING_DISPLAY:
			if _body != null and not is_blocking:
				_body.rotation.z = sin(_elapsed * TAU * 4.0) * 0.12
			if not is_blocking and _elapsed >= DISPLAY_WARNING_DURATION:
				is_blocking = true
				_body.rotation.z = 0.5
				_collision.set_deferred("disabled", false)
			if _elapsed >= DISPLAY_WARNING_DURATION + DISPLAY_BLOCK_DURATION:
				clear_hazard()


func clear_hazard() -> void:
	if _cleared:
		return
	_cleared = true
	cleared.emit(self)
	queue_free()


func _on_wet_floor_entered(body: Node3D) -> void:
	var cart := body as Cart
	if cart != null:
		cart.apply_slip(1.0)


func _build_wet_floor() -> void:
	var area := Area3D.new()
	area.name = "WetFloorArea"
	area.collision_layer = 0
	area.collision_mask = 0
	area.set_collision_mask_value(2, true)
	add_child(area)
	_body = area
	_collision = _add_box_collision(area, Vector3(4.0, 1.0, 3.0))
	_add_box_visual(area, Vector3(4.0, 0.08, 3.0), Color("4fc3f7"), Vector3(0.0, 0.04, 0.0))
	area.body_entered.connect(_on_wet_floor_entered)


func _build_pallet_jack() -> void:
	var body := AnimatableBody3D.new()
	body.name = "PalletJack"
	body.collision_layer = 0
	body.collision_mask = 0
	body.set_collision_layer_value(1, true)
	body.set_collision_mask_value(2, true)
	add_child(body)
	_body = body
	_collision = _add_box_collision(body, Vector3(2.4, 1.4, 0.8))
	_add_box_visual(body, Vector3(2.4, 1.4, 0.8), Color("ffb300"), Vector3(0.0, 0.7, 0.0))
	body.position.x = -3.0


func _build_falling_display() -> void:
	var body := StaticBody3D.new()
	body.name = "FallingDisplay"
	body.collision_layer = 0
	body.collision_mask = 0
	body.set_collision_layer_value(1, true)
	body.set_collision_mask_value(2, true)
	add_child(body)
	_body = body
	_collision = _add_box_collision(body, Vector3(2.0, 2.0, 2.0))
	_collision.disabled = true
	_add_box_visual(body, Vector3(2.0, 2.0, 2.0), Color("e53935"), Vector3(0.0, 1.0, 0.0))


func _add_box_collision(parent: CollisionObject3D, size: Vector3) -> CollisionShape3D:
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	parent.add_child(collision)
	return collision


func _add_box_visual(parent: Node3D, size: Vector3, color: Color, visual_position: Vector3) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.name = "PlaceholderVisual"
	visual.mesh = mesh
	visual.position = visual_position
	parent.add_child(visual)
