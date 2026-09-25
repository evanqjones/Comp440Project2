extends Node
## TEST-ONLY scripted driver for systems/cart/test/: patrols between two points at ~12 m/s so it
## can ram (and rob) you. Place it as a child of a Cart. John's BotController replaces this in the game.

@export var point_a := Vector3(-20.0, 0.0, -2.0)
@export var point_b := Vector3(20.0, 0.0, -2.0)
@export var throttle := 0.8

var _cart: Cart
var _to_b := true
var _cmd := DriveCommand.new()


func _ready() -> void:
	_cart = get_parent() as Cart


func _physics_process(_delta: float) -> void:
	if _cart == null:
		return
	var target := point_b if _to_b else point_a
	var to_target := target - _cart.global_position
	to_target.y = 0.0
	if to_target.length() < 3.0:
		_to_b = not _to_b
		return
	var forward := -_cart.global_basis.z
	forward.y = 0.0
	# signed_angle_to is + when the target is to the left (counterclockwise); steer +1 is right.
	var angle := forward.signed_angle_to(to_target, Vector3.UP)
	_cmd.steer = clampf(-angle * 2.0, -1.0, 1.0)
	# Ease off for sharp turns so U-turns stay tight in narrow aisles (full gas when lined up).
	_cmd.throttle = throttle * clampf(cos(angle), 0.15, 1.0)
	_cart.apply_command(_cmd)
