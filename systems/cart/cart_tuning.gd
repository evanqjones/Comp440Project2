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
## Steal rule (GAME_SPEC.md §5.1): the faster cart needs at least this speed (m/s)...
@export var steal_min_speed: float = 5.0
## ...and at least this much more speed than the other cart (m/s).
@export var steal_margin: float = 1.5
## Seconds the robbed cart has no control.
@export var stun_time: float = 0.7
## Seconds the robbed cart can't be robbed again (from the moment of the steal).
@export var immune_time: float = 1.6
## Fraction of speed the winner keeps after a steal (GDD example: 14 → 10.5 m/s).
@export var winner_keep: float = 0.75
## m/s the loser is shoved away. Keep below steal_min_speed so it can't chain-steal.
@export var knockback_speed: float = 4.0
## Grip while stunned (low, so the knocked-back cart slides).
@export var stun_grip: float = 1.0
## Non-steal bump: m/s each cart is pushed apart, and the fraction of speed kept.
@export var bounce_speed: float = 2.0
@export var bounce_keep: float = 0.7
## Seconds before the same pair of carts can resolve another contact.
@export var pair_cooldown: float = 0.2
## Tip-over: seconds to fall onto the side (and again to pop back up).
@export var tip_time: float = 0.15
## Inherited-item flight: seconds per cube, delay between cubes, arc height (m).
@export var flight_time: float = 0.4
@export var flight_stagger: float = 0.03
@export var flight_height: float = 1.0
