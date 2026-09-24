extends Node
## The referee: round phases, timer, doors, pickups, checkout, and scoring (docs/CONTRACTS.md §3).
## Registered as the autoload "RoundManager". No class_name: it would clash with the autoload name.
##
## STUB from integration/00-foundation. Every contract signal, variable, and method exists
## with its final signature. Anthony replaces the bodies in store/02-round-flow and
## store/03-spawns-checkout. Keep the signatures: tests/shared/test_contracts.gd checks them.

signal phase_changed(phase: GameTypes.Phase)
signal round_started(round_number: int)
signal round_ended(results: RoundResults)
signal checked_out(cart: Cart, value: int)
signal hazard_spawned(hazard: Node3D)
signal deal_spawned(pickup: Pickup)

## Read-only for other systems. (Tests may set phase directly; game code must not.)
var phase: GameTypes.Phase = GameTypes.Phase.IDLE
## 1..3; 0 before the first round. Never name this `round`: it shadows the built-in round().
var round_number: int = 0
## Seconds left in the current round.
var time_left: float = 0.0
var doors_open: bool = false

var _carts: Array[Cart] = []


## main.tscn wiring calls this for all 4 carts.
func register_cart(cart: Cart) -> void:
	if not _carts.has(cart):
		_carts.append(cart)


func get_carts() -> Array[Cart]:
	_carts.assign(_carts.filter(func(cart) -> bool: return is_instance_valid(cart)))
	return _carts.duplicate()


## Items currently on the floor.
func get_pickups() -> Array[Pickup]:
	var pickups: Array[Pickup] = []
	return pickups # Stub: implemented in store/03-spawns-checkout.


## Where bots drive to bank.
func get_checkout_position() -> Vector3:
	return Vector3.ZERO # Stub: implemented in store/01-greybox-store.


## True only in RUSH and FINAL_CALL.
func is_gameplay_active() -> bool:
	return phase == GameTypes.Phase.RUSH or phase == GameTypes.Phase.FINAL_CALL


func get_round_banked(_cart_id: int) -> int:
	return 0 # Stub: implemented in store/03-spawns-checkout.


func get_match_banked(_cart_id: int) -> int:
	return 0 # Stub: implemented with best of 3 (Final).


func get_stamps(_cart_id: int) -> int:
	return 0 # Stub: implemented with best of 3 (Final).


## Items this cart checked out this round (receipt + conservation tests).
func get_banked_items(_cart_id: int) -> Array[ItemData]:
	var items: Array[ItemData] = []
	return items # Stub: implemented in store/03-spawns-checkout.


## Called by Player's title/intro flow (Final); for the Demo, Store calls it when main.tscn loads.
func start_match() -> void:
	pass # Stub: implemented in store/02-round-flow.
