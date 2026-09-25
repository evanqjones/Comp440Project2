class_name PlayerController
extends Node
## Turns the human's input into a DriveCommand for their cart every physics frame
## (docs/features/player/01-controller-camera/FEATURE.md). Place it as a child of the
## player's Cart in main.tscn, or set `cart`.

## The cart this controller drives. Empty = use the parent if it's a Cart.
@export var cart: Cart
## Seconds for keyboard steering to go from 0 to full. The gamepad stick is direct.
@export var steer_ramp_time: float = 0.15

var _cmd := DriveCommand.new()
var _steer: float = 0.0
var _keyboard_steering: bool = true


func _ready() -> void:
	if cart == null and get_parent() is Cart:
		cart = get_parent() as Cart


## Remembers which device steered last, so keys ramp and the stick stays direct.
func _input(event: InputEvent) -> void:
	if event.is_action("steer_left") or event.is_action("steer_right"):
		_keyboard_steering = event is InputEventKey


func _physics_process(delta: float) -> void:
	if cart != null:
		cart.apply_command(build_command(delta))


## This frame's command (the same object is reused every frame). Neutral outside RUSH / FINAL_CALL.
func build_command(delta: float) -> DriveCommand:
	if not RoundManager.is_gameplay_active():
		_steer = 0.0
		_cmd.throttle = 0.0
		_cmd.brake = 0.0
		_cmd.steer = 0.0
		_cmd.boost = false
		return _cmd
	_cmd.throttle = Input.get_action_strength("drive_gas")
	_cmd.brake = Input.get_action_strength("drive_brake")
	var wanted := Input.get_axis("steer_left", "steer_right")
	if _keyboard_steering:
		_steer = move_toward(_steer, wanted, delta / steer_ramp_time)
	else:
		_steer = wanted
	_cmd.steer = _steer
	_cmd.boost = Input.is_action_pressed("boost")
	return _cmd
