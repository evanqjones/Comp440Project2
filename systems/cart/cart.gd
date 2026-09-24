class_name Cart
extends CharacterBody3D
## The shopping cart that the player and the bots drive (docs/CONTRACTS.md §2).
##
## STUB from integration/00-foundation. Every contract signal and method exists with its
## final signature, but there is no gameplay yet. Rickey replaces the bodies in
## cart/01-movement, cart/02-inventory, and cart/03-ram-steal. Keep the signatures:
## tests/shared/test_contracts.gd fails if one changes.

signal item_collected(cart: Cart, item: ItemData)
## Emitted once per steal, after both inventories are updated. items = moved into winner;
## spilled = overflow for Store to spawn.
signal cart_robbed(winner: Cart, loser: Cart, items: Array[ItemData], spilled: Array[ItemData])
signal cart_full(cart: Cart)

## 0 = human, 1..3 = bots; set in main.tscn.
@export var cart_id: int = 0
@export var profile: ShopperProfile

var _items: Array[ItemData] = []
var _boost_meter: float = 1.0
var _is_stunned: bool = false
var _is_immune: bool = false


## Called by the driver every physics frame. Read the values now; don't keep a reference.
func apply_command(_cmd: DriveCommand) -> void:
	pass # Stub: implemented in cart/01-movement.


## Returns false if the cart is full or gameplay is not active.
func try_add_item(_item: ItemData) -> bool:
	return false # Stub: implemented in cart/02-inventory.


## Empties the cart and returns what it held. Store's checkout calls this.
func take_all_items() -> Array[ItemData]:
	var taken: Array[ItemData] = _items.duplicate()
	_items.clear()
	return taken


## Empty cart, full boost, no stun or immunity, placed at spawn.
func reset_for_round(spawn: Transform3D) -> void:
	_items.clear()
	_boost_meter = 1.0
	_is_stunned = false
	_is_immune = false
	velocity = Vector3.ZERO
	if is_inside_tree():
		global_transform = spawn
	else:
		transform = spawn


## A fresh read-only snapshot. Changing it changes nothing on the cart.
func get_state() -> CartState:
	var state := CartState.new()
	state.cart_id = cart_id
	if profile != null:
		state.display_name = profile.display_name
		state.color = profile.color
	state.position = global_position if is_inside_tree() else position
	state.speed = Vector2(velocity.x, velocity.z).length()
	state.items = _items.duplicate()
	for item: ItemData in _items:
		state.value += item.value
	state.boost_meter = _boost_meter
	state.is_stunned = _is_stunned
	state.is_immune = _is_immune
	return state


## Wet floor: steering is ignored for duration seconds (Final milestone).
func apply_slip(_duration: float) -> void:
	pass # Stub: implemented with hazards (Final).
