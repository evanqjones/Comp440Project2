extends GutTest
## Cart movement with real physics frames (docs/features/cart/01-movement/01-spec.md §7).
## Each test builds its own floor; RoundManager.phase is restored afterward.

const CART_SCENE := "res://systems/cart/cart.tscn"


## Test-only driver: sends `cmd` to the cart every physics frame while enabled.
## (Named without the "Test" prefix so GUT doesn't treat it as a test class.)
class ScriptedDriver:
	extends Node

	var cart: Cart
	var cmd := DriveCommand.new()
	var enabled := true

	func _physics_process(_delta: float) -> void:
		if enabled and cart != null:
			cart.apply_command(cmd)


var _saved_phase: GameTypes.Phase
var _cart: Cart
var _driver: ScriptedDriver


func before_each() -> void:
	_saved_phase = RoundManager.phase
	RoundManager.phase = GameTypes.Phase.RUSH
	_add_box(Vector3(0.0, -0.5, 0.0), Vector3(200.0, 1.0, 200.0))
	_cart = (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(_cart)
	_driver = ScriptedDriver.new()
	_driver.cart = _cart
	add_child_autofree(_driver)


func after_each() -> void:
	RoundManager.phase = _saved_phase


## A static box on layer 1 (world), like the store's floor and walls.
func _add_box(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = center
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child_autofree(body)


func _speed() -> float:
	return _cart.get_state().speed


func test_full_throttle_drives_forward_to_top_speed() -> void:
	_driver.cmd.throttle = 1.0
	await wait_physics_frames(95)
	assert_almost_eq(_speed(), 15.0, 0.5, "reaches ~15 m/s after ~1.5 s")
	assert_lt(_cart.position.z, -5.0, "drove toward -Z, the cart's front")


func test_ignores_input_when_round_not_active() -> void:
	RoundManager.phase = GameTypes.Phase.IDLE
	_driver.cmd.throttle = 1.0
	await wait_physics_frames(30)
	assert_almost_eq(_speed(), 0.0, 0.01, "no driving outside RUSH / FINAL_CALL")


func test_coasts_when_commands_stop() -> void:
	_driver.cmd.throttle = 1.0
	await wait_physics_frames(60)
	var before := _speed()
	_driver.enabled = false
	await wait_physics_frames(30)
	assert_almost_eq(_speed(), before - 2.0, 0.5, "no commands = neutral: coasts at ~4 m/s²")


func test_wall_stops_cart_without_stored_speed() -> void:
	_add_box(Vector3(0.0, 1.0, -6.0), Vector3(10.0, 2.0, 1.0))
	_driver.cmd.throttle = 1.0
	await wait_physics_frames(90)
	assert_lt(_speed(), 0.5, "head-on into the wall stops the cart")
	var pinned_z := _cart.position.z
	_driver.cmd.throttle = 0.0
	_driver.cmd.brake = 1.0
	await wait_physics_frames(30)
	assert_gt(_cart.position.z, pinned_z + 0.5, "brake reverses away from the wall right away")
