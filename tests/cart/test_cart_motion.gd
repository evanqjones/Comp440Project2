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
