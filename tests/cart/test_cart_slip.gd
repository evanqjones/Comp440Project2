extends GutTest
## Environmental puddle slip behavior (docs/features/integration/04-stage-hazards/01-spec.md).

const CART_SCENE := "res://systems/cart/cart.tscn"


class ScriptedDriver:
	extends Node

	var cart: Cart
	var cmd := DriveCommand.new()

	func _physics_process(_delta: float) -> void:
		if cart != null:
			cart.apply_command(cmd)


var _saved_phase: GameTypes.Phase
var _cart: Cart
var _driver: ScriptedDriver


func before_each() -> void:
	_saved_phase = RoundManager.phase
	RoundManager.phase = GameTypes.Phase.RUSH
	_add_floor()
	_cart = (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(_cart)
	_driver = ScriptedDriver.new()
	_driver.cart = _cart
	add_child_autofree(_driver)


func after_each() -> void:
	RoundManager.phase = _saved_phase


func _add_floor() -> void:
	var floor := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(200.0, 1.0, 200.0)
	collision.shape = shape
	floor.add_child(collision)
	floor.position.y = -0.5
	add_child_autofree(floor)


func test_three_second_slip_spins_ignores_steering_then_restores_it() -> void:
	var start_yaw := _cart.rotation.y
	_cart.apply_slip(3.0)
	_driver.cmd.steer = 1.0
	await wait_physics_frames(30)
	assert_gt(_cart.rotation.y, start_yaw + 2.0, "spins clockwise despite the right-steer command")

	await wait_physics_frames(114)
	var before_late_slip_yaw := _cart.rotation.y
	await wait_physics_frames(6)
	assert_gt(angle_difference(before_late_slip_yaw, _cart.rotation.y), 0.3, "spin-out continues at 2.5 seconds")

	await wait_physics_frames(20)
	await wait_physics_frames(20)
	var after_expiry_yaw := _cart.rotation.y
	await wait_physics_frames(12)
	assert_lt(_cart.rotation.y, after_expiry_yaw - 0.05, "right steering works after the 3-second effect")
