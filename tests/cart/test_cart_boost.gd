extends GutTest
## Boost meter (docs/features/cart/06-boost/FEATURE.md): rules, real driving, camera FOV, shopper clip.

const CART_SCENE := "res://systems/cart/cart.tscn"
const CAMERA_SCENE := "res://systems/player/chase_camera.tscn"


## Sends `cmd` to the cart every physics frame while enabled.
class ScriptedDriver:
	extends Node

	var cart: Cart
	var cmd := DriveCommand.new()
	var enabled := true

	func _physics_process(_delta: float) -> void:
		if enabled and cart != null:
			cart.apply_command(cmd)


var _t: CartTuning
var _saved_phase: GameTypes.Phase


func before_each() -> void:
	_t = load("res://systems/cart/cart_tuning.tres") as CartTuning
	_saved_phase = RoundManager.phase


func after_each() -> void:
	RoundManager.phase = _saved_phase


# --- Rules ---------------------------------------------------------------------

func test_tuning_matches_game_spec() -> void:
	assert_almost_eq(_t.boost_bonus, 8.0, 0.001, "+8 m/s")
	assert_almost_eq(_t.boost_drain_time, 2.0, 0.001, "full meter drains in 2 s")
	assert_almost_eq(_t.boost_refill_time, 8.0, 0.001, "empty meter refills in 8 s")
	assert_almost_eq(_t.boost_acceleration, 20.0, 0.001, "boost kick: 20 m/s²")


func test_boosting_needs_held_meter_unlocked_and_no_brake() -> void:
	assert_true(CartBoost.is_boosting(1.0, true, false, false))
	assert_false(CartBoost.is_boosting(1.0, false, false, false), "button up")
	assert_false(CartBoost.is_boosting(0.0, true, false, false), "empty")
	assert_false(CartBoost.is_boosting(0.5, true, true, false), "locked after running dry")
	assert_false(CartBoost.is_boosting(1.0, true, false, true), "brake cancels boost")


func test_meter_drains_in_two_seconds_and_refills_in_eight() -> void:
	assert_almost_eq(CartBoost.next_meter(_t, 1.0, true, true, 1.0), 0.5, 0.001, "half a meter per second of boost")
	assert_almost_eq(CartBoost.next_meter(_t, 0.2, true, true, 1.0), 0.0, 0.001, "never below empty")
	assert_almost_eq(CartBoost.next_meter(_t, 0.0, false, false, 4.0), 0.5, 0.001, "an eighth per second while the button is up")
	assert_almost_eq(CartBoost.next_meter(_t, 0.9, false, false, 4.0), 1.0, 0.001, "never above full")
	assert_almost_eq(CartBoost.next_meter(_t, 0.3, false, true, 4.0), 0.3, 0.001, "held but not boosting: no refill")


func test_locks_at_empty_until_released() -> void:
	assert_true(CartBoost.next_locked(false, 0.0, true), "ran dry while held: locked")
	assert_true(CartBoost.next_locked(true, 0.4, true), "stays locked while still held")
	assert_false(CartBoost.next_locked(true, 0.0, false), "releasing unlocks")
	assert_false(CartBoost.next_locked(false, 0.5, true), "held with meter left: not locked")


func test_boost_accelerates_twice_as_hard() -> void:
	var top := CartMotion.top_speed(_t, 0, true)
	var boosted := CartMotion.next_forward_speed(_t, 15.0, 1.0, 0.0, top, 0.1, true)
	var normal := CartMotion.next_forward_speed(_t, 10.0, 1.0, 0.0, 23.0, 0.1)
	assert_almost_eq(boosted, 17.0, 0.001, "20 m/s² while boosting")
	assert_almost_eq(normal, 11.0, 0.001, "10 m/s² otherwise")


func test_shopper_plays_boost_clip() -> void:
	assert_eq(CartShopperAnimator.pick_clip(18.0, 0.0, false, true), "boost")
	assert_eq(CartShopperAnimator.pick_clip(18.0, 1.5, false, true), "boost", "boost beats turn (Evan's order)")
	assert_eq(CartShopperAnimator.pick_clip(-2.0, 0.0, false, true), "backwards", "reverse beats boost")
	assert_eq(CartShopperAnimator.pick_clip(18.0, 0.0, true, true), "stunned", "stunned beats everything")
	assert_eq(CartShopperAnimator.pick_clip(5.0, 0.0, false), "walk", "old 3-argument calls still work")


# --- Real driving ---------------------------------------------------------------

func _drive_scene() -> Array:
	RoundManager.phase = GameTypes.Phase.RUSH
	var body := StaticBody3D.new()
	body.position = Vector3(0.0, -0.5, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400.0, 1.0, 400.0)
	shape.shape = box
	body.add_child(shape)
	add_child_autofree(body)
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	var driver := ScriptedDriver.new()
	driver.cart = cart
	add_child_autofree(driver)
	return [cart, driver]


func test_boost_without_gas_passes_normal_top_speed() -> void:
	var parts := _drive_scene()
	var cart: Cart = parts[0]
	var driver: ScriptedDriver = parts[1]
	driver.cmd.boost = true
	await wait_physics_frames(66) # 1.1 s
	assert_true(cart.is_boosting(), "boosting while held with meter left")
	assert_gt(cart.get_state().speed, 17.0, "boost alone drives the cart past 15 m/s toward 23")
	assert_lt(cart.get_state().boost_meter, 0.5, "about half the meter used in ~1.1 s")


func test_boost_stops_when_the_meter_runs_dry() -> void:
	var parts := _drive_scene()
	var cart: Cart = parts[0]
	var driver: ScriptedDriver = parts[1]
	driver.cmd.boost = true
	await wait_physics_frames(150) # 2.5 s, longer than the 2 s meter
	assert_almost_eq(cart.get_state().boost_meter, 0.0, 0.001, "meter empty")
	assert_false(cart.is_boosting(), "locked until the button is released")
	driver.cmd.boost = false
	await wait_physics_frames(60)
	assert_gt(cart.get_state().boost_meter, 0.1, "refills once released")


func test_camera_widens_while_its_target_boosts() -> void:
	var parts := _drive_scene()
	var cart: Cart = parts[0]
	var driver: ScriptedDriver = parts[1]
	var rig := (load(CAMERA_SCENE) as PackedScene).instantiate() as ChaseCamera
	rig.target = cart
	add_child_autofree(rig)
	var camera := rig.get_node("Camera3D") as Camera3D
	assert_almost_eq(camera.fov, 62.0, 0.01, "normal FOV")
	driver.cmd.boost = true
	await wait_physics_frames(40)
	assert_almost_eq(camera.fov, 72.0, 0.5, "widens to 72° while boosting")
	driver.cmd.boost = false
	await wait_physics_frames(40)
	assert_almost_eq(camera.fov, 62.0, 0.5, "back to 62° after")
