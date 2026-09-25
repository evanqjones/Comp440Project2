class_name CartMotion
extends RefCounted
## Pure movement math for Cart: no nodes, no physics, so every rule is unit-testable
## (docs/features/cart/01-movement/01-spec.md §3). Speeds in m/s, times in seconds.


## (base + boost) × (1 − slowdown × items), never below 0.
static func top_speed(t: CartTuning, item_count: int, boosting: bool) -> float:
	var base := t.base_top_speed + (t.boost_bonus if boosting else 0.0)
	return maxf(0.0, base * (1.0 - t.slowdown_per_item * item_count))


## Degrees per second: turn_rate_stopped at 0 m/s, easing to turn_rate_at_top at base_top_speed and above.
static func turn_rate(t: CartTuning, speed: float) -> float:
	var weight := clampf(absf(speed) / t.base_top_speed, 0.0, 1.0)
	return lerpf(t.turn_rate_stopped, t.turn_rate_at_top, weight)


## New signed forward speed (+ forward, − reverse) after one step of dt seconds.
## Brake beats gas. Braking below reverse_threshold reverses. Gas while reversing brakes first.
## Analog gas sets the target (half gas = half top speed).
static func next_forward_speed(t: CartTuning, speed: float, throttle: float, brake: float, top: float, dt: float) -> float:
	if brake > 0.0:
		if speed > t.reverse_threshold:
			return move_toward(speed, 0.0, t.brake_deceleration * brake * dt)
		var reverse_target := -t.reverse_top_speed * brake
		if speed > reverse_target:
			return move_toward(speed, reverse_target, t.reverse_acceleration * dt)
		return move_toward(speed, reverse_target, t.coast_deceleration * dt)
	if throttle > 0.0 and speed < 0.0:
		return move_toward(speed, 0.0, t.brake_deceleration * throttle * dt)
	var target := top * throttle
	if speed >= 0.0 and speed < target:
		return move_toward(speed, target, t.acceleration * dt)
	return move_toward(speed, target, t.coast_deceleration * dt)


## New yaw in radians after steering for dt. steer +1 = right = clockwise from above.
## Godot's +yaw is counterclockwise, so right steering lowers yaw, forward or reverse.
static func next_yaw(t: CartTuning, yaw: float, steer: float, speed: float, dt: float) -> float:
	return yaw - steer * deg_to_rad(turn_rate(t, speed)) * dt


## Sideways velocity after grip fades it for dt seconds (the slide after a turn).
## grip_override >= 0 replaces t.grip (a stunned cart slides with low grip).
static func fade_sideways(t: CartTuning, sideways: Vector3, dt: float, grip_override: float = -1.0) -> Vector3:
	var grip := grip_override if grip_override >= 0.0 else t.grip
	return sideways * exp(-grip * dt)
