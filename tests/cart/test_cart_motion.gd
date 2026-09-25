extends GutTest
## CartMotion math (docs/features/cart/01-movement/01-spec.md §3, §7). Pure functions: no physics.

const DT := 1.0 / 60.0
var t: CartTuning


func before_each() -> void:
	t = CartTuning.new()


func test_top_speed_formula() -> void:
	assert_almost_eq(CartMotion.top_speed(t, 0, false), 15.0, 0.001, "empty cart")
	assert_almost_eq(CartMotion.top_speed(t, 24, false), 10.68, 0.001, "full cart is ~29% slower")
	assert_almost_eq(CartMotion.top_speed(t, 0, true), 23.0, 0.001, "boost adds 8 before weight")
	assert_almost_eq(CartMotion.top_speed(t, 24, true), 16.376, 0.001, "boost with a full cart")


func test_reverse_top_speed_below_steal_minimum() -> void:
	var shipped := load("res://systems/cart/cart_tuning.tres") as CartTuning
	assert_not_null(shipped, "cart_tuning.tres loads as CartTuning")
	if shipped == null:
		return
	assert_lt(shipped.reverse_top_speed, 5.0, "reversing can never reach the 5 m/s steal minimum")


func test_turn_rate_180_stopped_90_at_top_and_above() -> void:
	assert_almost_eq(CartMotion.turn_rate(t, 0.0), 180.0, 0.001)
	assert_almost_eq(CartMotion.turn_rate(t, 7.5), 135.0, 0.001)
	assert_almost_eq(CartMotion.turn_rate(t, 15.0), 90.0, 0.001)
	assert_almost_eq(CartMotion.turn_rate(t, 23.0), 90.0, 0.001, "boosting doesn't turn slower than 90")
	assert_almost_eq(CartMotion.turn_rate(t, -4.0), 156.0, 0.001, "reverse speed uses its size")


## Runs next_forward_speed for `seconds` at a fixed DT and returns the final speed.
func _run(speed: float, throttle: float, brake: float, top: float, seconds: float) -> float:
	for _i: int in roundi(seconds / DT):
		speed = CartMotion.next_forward_speed(t, speed, throttle, brake, top, DT)
	return speed


func test_full_throttle_reaches_5_at_half_second_and_15_at_1_5s() -> void:
	assert_almost_eq(_run(0.0, 1.0, 0.0, 15.0, 0.5), 5.0, 0.01)
	assert_almost_eq(_run(0.0, 1.0, 0.0, 15.0, 1.5), 15.0, 0.01)
	var speed := 0.0
	for _i: int in 300:
		speed = CartMotion.next_forward_speed(t, speed, 1.0, 0.0, 15.0, DT)
		assert_true(speed <= 15.0 + 0.0001, "never exceeds top speed")
		if speed > 15.0 + 0.0001:
			break


func test_half_throttle_settles_at_half_top_speed() -> void:
	assert_almost_eq(_run(0.0, 0.5, 0.0, 15.0, 3.0), 7.5, 0.01)


func test_brake_stops_from_15_within_0_6s() -> void:
	var speed := _run(15.0, 0.0, 1.0, 15.0, 0.6)
	assert_true(speed <= 0.3 and speed >= -0.5, "stopped (about to reverse) after 0.6 s, got %s" % speed)


func test_brake_then_reverse_caps_at_4() -> void:
	assert_almost_eq(_run(0.0, 0.0, 1.0, 15.0, 2.0), -4.0, 0.01)


func test_coast_loses_4_per_second() -> void:
	assert_almost_eq(_run(15.0, 0.0, 0.0, 15.0, 1.0), 11.0, 0.01)
	assert_almost_eq(_run(-4.0, 0.0, 0.0, 15.0, 0.5), -2.0, 0.01, "coasting in reverse also eases at 4 m/s²")


func test_brake_beats_throttle() -> void:
	assert_lt(CartMotion.next_forward_speed(t, 10.0, 1.0, 1.0, 15.0, DT), 10.0)


func test_throttle_while_reversing_brakes_first() -> void:
	var speed := _run(-4.0, 1.0, 0.0, 15.0, 10.0 * DT)
	assert_almost_eq(speed, 0.0, 0.001, "25 m/s² brings -4 to 0 in 10 frames without overshooting")
	assert_almost_eq(_run(speed, 1.0, 0.0, 15.0, 0.5), 5.0, 0.01, "then accelerates forward at 10 m/s²")


func test_overspeed_eases_down_to_top() -> void:
	assert_almost_eq(_run(15.0, 1.0, 0.0, 10.68, 0.5), 13.0, 0.01, "eases at 4 m/s², no snap")
	assert_almost_eq(_run(15.0, 1.0, 0.0, 10.68, 5.0), 10.68, 0.01)


func test_steer_right_is_clockwise_forward_and_reverse() -> void:
	var step := deg_to_rad(180.0) * DT
	assert_almost_eq(CartMotion.next_yaw(t, 0.0, 1.0, 0.0, DT), -step, 0.00001, "right lowers yaw (clockwise)")
	assert_lt(CartMotion.next_yaw(t, 0.0, 1.0, -4.0, DT), 0.0, "still clockwise while reversing")
	assert_gt(CartMotion.next_yaw(t, 0.0, -1.0, 10.0, DT), 0.0, "left raises yaw")
	assert_eq(CartMotion.next_yaw(t, 1.0, 0.0, 10.0, DT), 1.0, "no steer, no turn")


func test_sideways_fades_with_grip() -> void:
	var faded := CartMotion.fade_sideways(t, Vector3(1.0, 0.0, 0.0), 0.125)
	assert_almost_eq(faded.x, exp(-1.0), 0.0001, "grip 8/s: ~37% left after 0.125 s")
