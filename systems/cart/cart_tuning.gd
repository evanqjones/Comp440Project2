class_name CartTuning
extends Resource
## Handling numbers shared by every cart (docs/features/cart/01-movement/01-spec.md §3).
## cart_tuning.tres holds the values all four carts use. Keep GAME_SPEC.md §12 in sync.

## m/s, before weight and boost.
@export var base_top_speed: float = 15.0
## Fraction of top speed lost per carried item (0.012 = 1.2%).
@export var slowdown_per_item: float = 0.012
## Most items a cart can carry.
@export var item_cap: int = 24
## m/s added to top speed while boosting (the boost meter comes in a later feature).
@export var boost_bonus: float = 8.0
## m/s² when speeding up forward.
@export var acceleration: float = 10.0
## m/s² when braking forward motion (also gas while reversing).
@export var brake_deceleration: float = 25.0
## m/s² when easing off: no input, or above the target speed.
@export var coast_deceleration: float = 4.0
## m/s. Must stay below 5.0 (the steal minimum) so reversing can never steal.
@export var reverse_top_speed: float = 4.0
## m/s² when speeding up in reverse.
@export var reverse_acceleration: float = 8.0
## m/s. Holding brake below this forward speed starts reversing.
@export var reverse_threshold: float = 0.3
## Degrees per second when stopped (the cart pivots in place).
@export var turn_rate_stopped: float = 180.0
## Degrees per second at base_top_speed and above.
@export var turn_rate_at_top: float = 90.0
## Per second. Higher means sideways slide fades faster.
@export var grip: float = 8.0
