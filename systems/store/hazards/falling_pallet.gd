class_name FallingPallet
extends Node3D
## Warn with a ground shadow, drop a pallet, block the lane, then clear it.

const WARNING_SECONDS: float = 5.0
const FALL_SECONDS: float = 0.35
const BLOCK_SECONDS: float = 5.0
const START_HEIGHT: float = 7.0

enum Phase { WARNING, FALLING, BLOCKING, DONE }

var _phase: Phase = Phase.WARNING
var _phase_elapsed: float = 0.0

@onready var _pallet := $Visual/FallingPalletVisual/Pallet as Node3D
@onready var _shadow := $Visual/FallingPalletVisual/Shadow as MeshInstance3D
@onready var _blocker_shape := $Blocker/CollisionShape3D as CollisionShape3D


func _ready() -> void:
	_pallet.position.y = START_HEIGHT
	_shadow.visible = true
	_blocker_shape.disabled = true


func _physics_process(delta: float) -> void:
	if not RoundManager.is_gameplay_active():
		_blocker_shape.set_deferred("disabled", true)
		queue_free()
		return

	_phase_elapsed += delta
	match _phase:
		Phase.WARNING:
			if _phase_elapsed >= WARNING_SECONDS:
				_phase = Phase.FALLING
				_phase_elapsed = 0.0
		Phase.FALLING:
			var progress := clampf(_phase_elapsed / FALL_SECONDS, 0.0, 1.0)
			_pallet.position.y = lerpf(START_HEIGHT, 0.15, progress)
			_pallet.rotation.z = lerpf(0.0, deg_to_rad(12.0), progress)
			if progress >= 1.0:
				_land()
		Phase.BLOCKING:
			if _phase_elapsed >= BLOCK_SECONDS:
				_phase = Phase.DONE
				_blocker_shape.set_deferred("disabled", true)
				queue_free()


func is_blocking() -> bool:
	return _phase == Phase.BLOCKING


func _land() -> void:
	_phase = Phase.BLOCKING
	_phase_elapsed = 0.0
	_shadow.visible = false
	_blocker_shape.set_deferred("disabled", false)
