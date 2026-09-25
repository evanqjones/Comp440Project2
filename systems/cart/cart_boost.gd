class_name CartBoost
## Boost meter rules (docs/features/cart/06-boost/FEATURE.md). The meter runs from 0.0 (empty) to
## 1.0 (full): it drains while boosting and refills only while the button is up. Running dry while
## the button is held locks boost until it's released.


## True when the cart boosts this step: held, meter left, not locked, and not braking.
static func is_boosting(meter: float, held: bool, locked: bool, braking: bool) -> bool:
	return held and not locked and not braking and meter > 0.0


## The meter after dt seconds. Holding the button without boosting neither drains nor refills.
static func next_meter(t: CartTuning, meter: float, boosting: bool, held: bool, dt: float) -> float:
	if boosting:
		return maxf(0.0, meter - dt / t.boost_drain_time)
	if not held:
		return minf(1.0, meter + dt / t.boost_refill_time)
	return meter


## Locked once the meter hits empty while held; releasing the button unlocks.
static func next_locked(locked: bool, meter: float, held: bool) -> bool:
	if not held:
		return false
	return locked or meter <= 0.0
