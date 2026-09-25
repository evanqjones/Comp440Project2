extends Node3D
## TEST-ONLY scene for cart/01-movement hand checks. Builds a floor, walls and pillars,
## unlocks driving by setting the round phase to RUSH (allowed in test code only),
## and shows a live speed readout.

@onready var _cart: Cart = $Cart
@onready var _driver: Node = $DebugKeyboardDriver
@onready var _camera: Camera3D = $DebugFollowCamera

var _readout: Label


func _ready() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	_driver.set("cart", _cart)
	_camera.set("target", _cart)
	_build_arena()
	_build_readout()


func _build_arena() -> void:
	var floor_color := Color("#BDEBD3")
	var wall_color := Color("#FFF6E0")
	var pillar_color := Color("#8E24AA")
	_add_box(Vector3(0.0, -0.5, 0.0), Vector3(60.0, 1.0, 60.0), floor_color)
	_add_box(Vector3(0.0, 1.0, -30.5), Vector3(62.0, 2.0, 1.0), wall_color)
	_add_box(Vector3(0.0, 1.0, 30.5), Vector3(62.0, 2.0, 1.0), wall_color)
	_add_box(Vector3(-30.5, 1.0, 0.0), Vector3(1.0, 2.0, 62.0), wall_color)
	_add_box(Vector3(30.5, 1.0, 0.0), Vector3(1.0, 2.0, 62.0), wall_color)
	# A 3.5 m-wide "aisle" between two shelves, plus pillars to weave around.
	_add_box(Vector3(-2.25, 1.0, -15.0), Vector3(1.0, 2.0, 12.0), wall_color)
	_add_box(Vector3(2.25, 1.0, -15.0), Vector3(1.0, 2.0, 12.0), wall_color)
	for x: float in [-12.0, -6.0, 6.0, 12.0]:
		_add_box(Vector3(x, 1.0, 8.0), Vector3(1.0, 2.0, 1.0), pillar_color)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	add_child(sun)


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
	var planar := Vector3(_cart.velocity.x, 0.0, _cart.velocity.z)
	var forward := -_cart.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var forward_speed := planar.dot(forward)
	var sideways_speed := (planar - forward * forward_speed).length()
	var top := CartMotion.top_speed(_cart.tuning, 0, false)
	_readout.text = "speed %.1f m/s   forward %.1f   sideways %.1f   top %.1f\nW/Up gas · S/Down brake (hold when stopped to reverse) · A/D steer" % [
		_cart.get_state().speed, forward_speed, sideways_speed, top]
