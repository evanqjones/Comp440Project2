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

@onready var _arm: SpringArm3D = $Arm
@onready var _spot: Marker3D = $Arm/CameraSpot
@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	var rise := height - pivot_height
	_arm.spring_length = Vector2(distance, rise).length()
	_arm.rotation = Vector3(-atan2(rise, distance), 0.0, 0.0) # arm's +Z points back and up
	if target != null:
		global_position = target.global_position + Vector3.UP * pivot_height
		global_rotation.y = target.global_rotation.y


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var weight := 1.0 - exp(-follow_rate * delta)
	global_position = global_position.lerp(target.global_position + Vector3.UP * pivot_height, weight)
	global_rotation.y = lerp_angle(global_rotation.y, target.global_rotation.y, weight)


func _process(_delta: float) -> void:
	if not is_instance_valid(target):
		return
	_camera.global_position = _spot.global_position
	var forward := -target.global_basis.z
	forward.y = 0.0
	_camera.look_at(target.global_position + forward.normalized() * look_ahead + Vector3.UP)
