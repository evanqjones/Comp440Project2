class_name ChaseCamera
extends Node3D
## Third-person chase camera for the player's cart (docs/features/player/01-controller-camera/FEATURE.md).
## The rig eases toward a pivot above the target and turns with the target's facing. Its SpringArm3D
## (a node that shortens its arm when something blocks it) keeps walls from hiding the cart.
## The arm moves CameraSpot; the top-level Camera3D copies that position and looks ahead of the cart.
## (The camera isn't the arm's child because SpringArm3D rewrites its children's transforms.)

## What to follow (the player's Cart). Set in main.tscn.
@export var target: Node3D
## Meters behind and above the target when nothing blocks the view (GAME_SPEC.md §12).
@export var distance: float = 8.5
@export var height: float = 5.5
## The arm pivots this high above the target.
@export var pivot_height: float = 1.0
## The camera looks at a point this far ahead of the target, 1 m up.
@export var look_ahead: float = 4.0
## How fast position and yaw catch up, per second (15 = about 95% in 0.2 s).
@export var follow_rate: float = 15.0
## Field of view in degrees, normally and while the target cart boosts (GAME_SPEC.md §12).
@export var fov_normal: float = 62.0
@export var fov_boost: float = 72.0
## Degrees per second the FOV moves toward its goal (40 = the 10° change in 0.25 s).
@export var fov_rate: float = 40.0
## Fast cart yaw is a spin-out; hold the view heading until the spin stops.
const SPIN_OUT_CAMERA_LOCK_RATE: float = deg_to_rad(250.0)

var _shake_strength: float = 0.0
var _shake_duration: float = 0.0
var _shake_left: float = 0.0
var _rng := RandomNumberGenerator.new()
var _heading_yaw: float = 0.0
var _last_target_yaw: float = 0.0
var _camera_heading_locked: bool = false

@onready var _arm: SpringArm3D = $Arm
@onready var _spot: Marker3D = $Arm/CameraSpot
@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	var rise := height - pivot_height
	_arm.spring_length = Vector2(distance, rise).length()
	_arm.rotation = Vector3(-atan2(rise, distance), 0.0, 0.0) # arm's +Z points back and up
	_camera.fov = fov_normal
	if target != null:
		global_position = target.global_position + Vector3.UP * pivot_height
		_heading_yaw = target.global_rotation.y
		_last_target_yaw = _heading_yaw
		global_rotation.y = _heading_yaw


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var weight := 1.0 - exp(-follow_rate * delta)
	global_position = global_position.lerp(target.global_position + Vector3.UP * pivot_height, weight)
	var target_yaw := target.global_rotation.y
	var yaw_rate := wrapf(target_yaw - _last_target_yaw, -PI, PI) / maxf(delta, 0.0001)
	_last_target_yaw = target_yaw
	_camera_heading_locked = absf(yaw_rate) >= SPIN_OUT_CAMERA_LOCK_RATE
	if not _camera_heading_locked:
		_heading_yaw = lerp_angle(_heading_yaw, target_yaw, weight)
	global_rotation.y = _heading_yaw


## Jolts the camera by up to `strength` meters, fading out over `duration` seconds (player/04-feel).
## A weaker shake never cuts a stronger one short.
func shake(strength: float, duration: float) -> void:
	if duration <= 0.0 or strength < current_shake():
		return
	_shake_strength = strength
	_shake_duration = duration
	_shake_left = duration


## Meters of jolt right now (0 when still).
func current_shake() -> float:
	if _shake_left <= 0.0:
		return 0.0
	return _shake_strength * _shake_left / _shake_duration


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var cart := target as Cart
	var goal := fov_boost if cart != null and cart.is_boosting() else fov_normal
	_camera.fov = move_toward(_camera.fov, goal, fov_rate * delta)
	_camera.global_position = _spot.global_position
	var view_forward := Vector3.FORWARD.rotated(Vector3.UP, _heading_yaw)
	_camera.look_at(target.global_position + view_forward * look_ahead + Vector3.UP)
	if _shake_left > 0.0:
		_shake_left = maxf(0.0, _shake_left - delta)
		var jolt := Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0))
		_camera.global_position += jolt * current_shake()
