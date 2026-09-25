extends GutTest
## ChaseCamera (docs/features/player/01-controller-camera/FEATURE.md §2).
## The target is a plain Node3D standing in for a cart at the origin, facing -Z.

const CAMERA_SCENE := "res://systems/player/chase_camera.tscn"

var _target: Node3D
var _rig: ChaseCamera


func before_each() -> void:
	_target = Node3D.new()
	add_child_autofree(_target)
	_rig = (load(CAMERA_SCENE) as PackedScene).instantiate() as ChaseCamera
	_rig.target = _target
	add_child_autofree(_rig)


func _camera() -> Camera3D:
	return _rig.get_node("Camera3D") as Camera3D


func test_rests_8_5_behind_and_5_5_above_looking_ahead() -> void:
	await wait_physics_frames(10)
	var pos := _camera().global_position
	assert_almost_eq(pos.x, 0.0, 0.3, "centered behind the cart")
	assert_almost_eq(pos.y, 5.5, 0.3, "5.5 m up")
	assert_almost_eq(pos.z, 8.5, 0.3, "8.5 m behind (the cart faces -Z)")
	var to_focus := (Vector3(0.0, 1.0, -4.0) - pos).normalized()
	var looking := -_camera().global_basis.z
	assert_almost_eq(looking.dot(to_focus), 1.0, 0.01, "looks at a point 4 m ahead of the cart")


func test_fov_is_62() -> void:
	assert_almost_eq(_camera().fov, 62.0, 0.01)


func test_swings_behind_when_cart_turns() -> void:
	_target.rotation.y = -PI / 2.0 # turned right: now faces +X, so "behind" is -X
	await wait_physics_frames(30)
	var pos := _camera().global_position
	assert_almost_eq(pos.x, -8.5, 0.5, "moved behind the new heading")
	assert_almost_eq(pos.z, 0.0, 0.5)


func test_spring_arm_pulls_in_when_a_wall_blocks() -> void:
	var wall := StaticBody3D.new()
	wall.position = Vector3(0.0, 5.0, 4.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 10.0, 1.0)
	shape.shape = box
	wall.add_child(shape)
	add_child_autofree(wall)
	await wait_physics_frames(10)
	assert_lt(_camera().global_position.z, 3.5, "camera pulled in front of the wall (its face is at z = 3.5)")
