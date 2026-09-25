extends Node
## TEST-ONLY driver for systems/cart/test/. Replaced by the real PlayerController in player/01.
## Reads the input actions into a DriveCommand and sends it to the cart every physics frame.

@export var cart: Cart

var _cmd := DriveCommand.new()


func _physics_process(_delta: float) -> void:
	if cart == null:
		return
	_cmd.throttle = Input.get_action_strength("drive_gas")
	_cmd.brake = Input.get_action_strength("drive_brake")
	_cmd.steer = Input.get_axis("steer_left", "steer_right")
	_cmd.boost = Input.is_action_pressed("boost")
	cart.apply_command(_cmd)
