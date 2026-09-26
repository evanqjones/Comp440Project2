class_name PlayerFeedback
extends Node
## Camera shake and controller rumble when the player's cart is in a steal
## (docs/features/player/04-feel/FEATURE.md). Every cart's cart_robbed is watched because the
## LOSER emits it: the player's own cart says "you were robbed", another cart naming the player as
## winner says "you inherited a haul". Bot-on-bot steals and plain bounces do nothing.

## Meters of camera jolt and seconds it lasts (GAME_SPEC.md §12).
const ROBBED_SHAKE := 0.35
const ROBBED_TIME := 0.35
const STEAL_SHAKE := 0.12
const STEAL_TIME := 0.15

## The human's cart.
@export var cart: Cart
@export var camera: ChaseCamera


func _ready() -> void:
	_watch_registered()


func _process(_delta: float) -> void:
	_watch_registered() # carts can register after this node is ready


## Listen for steals involving `other` (safe to call more than once).
func watch(other: Cart) -> void:
	if other != null and not other.cart_robbed.is_connected(_on_cart_robbed):
		other.cart_robbed.connect(_on_cart_robbed)


func _watch_registered() -> void:
	watch(cart)
	for other: Cart in RoundManager.get_carts():
		watch(other)


func _on_cart_robbed(winner: Cart, loser: Cart, _items: Array[ItemData], _spilled: Array[ItemData]) -> void:
	if cart == null:
		return
	if loser == cart:
		_feel(ROBBED_SHAKE, ROBBED_TIME, 0.5, 1.0)
	elif winner == cart:
		_feel(STEAL_SHAKE, STEAL_TIME, 0.4, 0.0)


func _feel(strength: float, seconds: float, weak_motor: float, strong_motor: float) -> void:
	if camera != null:
		camera.shake(strength, seconds)
	for pad: int in Input.get_connected_joypads():
		Input.start_joy_vibration(pad, weak_motor, strong_motor, seconds)
