extends GutTest
## PlayerController (docs/features/player/01-controller-camera/FEATURE.md §2).

const DT := 1.0 / 60.0
const CART_SCENE := "res://systems/cart/cart.tscn"
const ACTIONS := ["drive_gas", "drive_brake", "steer_left", "steer_right", "boost"]

var _saved_phase: GameTypes.Phase
var _controller: PlayerController


func before_each() -> void:
	_saved_phase = RoundManager.phase
	RoundManager.phase = GameTypes.Phase.RUSH
	_controller = PlayerController.new()
	add_child_autofree(_controller)


func after_each() -> void:
	for action: String in ACTIONS:
		Input.action_release(action)
	RoundManager.phase = _saved_phase


## A static box on layer 1 (world), like the store's floor.
func _add_box(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = center
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child_autofree(body)


func test_gas_brake_and_boost_map_to_command() -> void:
	Input.action_press("drive_gas", 0.6)
	Input.action_press("drive_brake", 0.3)
	Input.action_press("boost")
	var cmd := _controller.build_command(DT)
	assert_almost_eq(cmd.throttle, 0.6, 0.001, "analog gas")
	assert_almost_eq(cmd.brake, 0.3, 0.001, "analog brake")
	assert_true(cmd.boost, "boost passes through")


func test_neutral_when_round_not_active() -> void:
	RoundManager.phase = GameTypes.Phase.COUNTDOWN
	Input.action_press("drive_gas")
	Input.action_press("steer_right")
	var cmd := _controller.build_command(DT)
	assert_eq(cmd.throttle, 0.0, "no gas during countdown")
	assert_eq(cmd.steer, 0.0, "no steer during countdown")


func test_keyboard_steer_ramps_to_full_in_0_15s() -> void:
	Input.action_press("steer_right")
	var cmd := _controller.build_command(DT)
	assert_almost_eq(cmd.steer, DT / 0.15, 0.001, "one frame in: about 0.11")
	for _i: int in 8:
		cmd = _controller.build_command(DT)
	assert_almost_eq(cmd.steer, 1.0, 0.001, "full after 9 frames = 0.15 s")
	Input.action_release("steer_right")
	cmd = _controller.build_command(DT)
	assert_almost_eq(cmd.steer, 1.0 - DT / 0.15, 0.001, "eases back toward 0 on release")


func test_gamepad_steer_is_direct() -> void:
	var stick := InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_LEFT_X
	stick.axis_value = 0.5
	_controller._input(stick)
	Input.action_press("steer_right", 0.5)
	assert_almost_eq(_controller.build_command(DT).steer, 0.5, 0.001, "stick steer is used as-is")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_D
	key.pressed = true
	_controller._input(key)
	Input.action_press("steer_right")
	assert_almost_eq(_controller.build_command(DT).steer, 0.5 + DT / 0.15, 0.001,
		"back on keys: ramps from where the stick left it")


func test_uses_parent_cart_when_none_assigned() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	var controller := PlayerController.new()
	cart.add_child(controller)
	assert_eq(controller.cart, cart, "a controller placed under a Cart drives it")


func test_drives_a_real_cart() -> void:
	_add_box(Vector3(0.0, -0.5, 0.0), Vector3(200.0, 1.0, 200.0))
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	cart.add_child(PlayerController.new())
	Input.action_press("drive_gas")
	await wait_physics_frames(60)
	assert_gt(cart.get_state().speed, 5.0, "holding gas for 1 s drives the cart")
