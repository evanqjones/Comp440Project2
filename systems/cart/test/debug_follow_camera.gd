extends Camera3D
## TEST-ONLY follow camera for systems/cart/test/. The real chase camera comes in player/01.

@export var target: Node3D
@export var distance: float = 8.5
@export var height: float = 5.5
@export var smoothing: float = 6.0


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var behind := target.global_basis.z # +Z is behind the cart (its front is -Z)
	behind.y = 0.0
	var wanted := target.global_position + behind.normalized() * distance + Vector3.UP * height
	global_position = global_position.lerp(wanted, 1.0 - exp(-smoothing * delta))
	look_at(target.global_position + Vector3.UP)
