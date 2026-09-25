extends Node3D
## TEST-ONLY scene for player/01-controller-camera hand checks: the real PlayerController and
## ChaseCamera driving a real cart. Sets the round phase to RUSH (allowed in test code only).
## Drive with the tall purple wall behind you to see the spring arm pull the camera in.

@onready var _cart: Cart = $PlayerCart
@onready var _rig: ChaseCamera = $ChaseCamera

var _readout: Label


func _ready() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	_build_arena()
	_build_readout()


func _build_arena() -> void:
	var floor_color := Color("#BDEBD3")
	var wall_color := Color("#FFF6E0")
	var tall_color := Color("#8E24AA")
	_add_box(Vector3(0.0, -0.5, 0.0), Vector3(60.0, 1.0, 60.0), floor_color)
	_add_box(Vector3(0.0, 1.0, -30.5), Vector3(62.0, 2.0, 1.0), wall_color)
	_add_box(Vector3(0.0, 1.0, 30.5), Vector3(62.0, 2.0, 1.0), wall_color)
	_add_box(Vector3(-30.5, 1.0, 0.0), Vector3(1.0, 2.0, 62.0), wall_color)
	_add_box(Vector3(30.5, 1.0, 0.0), Vector3(1.0, 2.0, 62.0), wall_color)
	# A 3.5 m-wide aisle between 2 m shelves.
	_add_box(Vector3(-2.25, 1.0, -15.0), Vector3(1.0, 2.0, 12.0), wall_color)
	_add_box(Vector3(2.25, 1.0, -15.0), Vector3(1.0, 2.0, 12.0), wall_color)
	# An 8 m-tall wall: back up to it (or drive away from it) to see the camera pull in.
	_add_box(Vector3(15.0, 4.0, 0.0), Vector3(1.0, 8.0, 20.0), tall_color)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	add_child(sun)
	# Dim, shadowless fill from the opposite side so faces the sun misses aren't pitch black.
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-35.0, 210.0, 0.0)
	fill.light_energy = 0.35
	fill.light_specular = 0.0
	add_child(fill)


## A static box on layer 1 (world) with a flat-colored mesh.
func _add_box(center: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = center
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	box_mesh.material = material
	mesh.mesh = box_mesh
	body.add_child(mesh)
	add_child(body)


func _build_readout() -> void:
	var layer := CanvasLayer.new()
	_readout = Label.new()
	_readout.position = Vector2(16.0, 16.0)
	layer.add_child(_readout)
	add_child(layer)


func _process(_delta: float) -> void:
	var camera := _rig.get_node("Camera3D") as Camera3D
	var arm_length := camera.global_position.distance_to(_rig.global_position)
	_readout.text = "speed %.1f m/s   camera arm %.1f m (9.6 = unblocked)\nW/Up gas · S/Down brake (hold when stopped to reverse) · A/D steer (keys ease in) · gamepad works too" % [
		_cart.get_state().speed, arm_length]
