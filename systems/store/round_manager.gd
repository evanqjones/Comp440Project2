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

const COUNTDOWN_DURATION: float = 3.0
const ROUND_DURATION: float = 120.0
const FINAL_CALL_DURATION: float = 20.0
const RESULTS_DURATION: float = 10.0

## Read-only for other systems. (Tests may set phase directly; game code must not.)
var phase: GameTypes.Phase = GameTypes.Phase.IDLE
## 1..3; 0 before the first round. Never name this `round`: it shadows the built-in round().
var round_number: int = 0
## Seconds left in the current round.
var time_left: float = 0.0
var doors_open: bool = false

var _carts: Array[Cart] = []
var _phase_time_left: float = 0.0
var _close_pending: bool = false
var _match_running: bool = false
var _match_generation: int = 0
var _last_results: RoundResults


func _physics_process(delta: float) -> void:
	if not _match_running:
		return
	var remaining := maxf(delta, 0.0)
	while remaining > 0.0:
		match phase:
			GameTypes.Phase.COUNTDOWN:
				if remaining < _phase_time_left:
					_phase_time_left -= remaining
					return
				remaining -= _phase_time_left
				_phase_time_left = 0.0
				_enter_rush()
			GameTypes.Phase.RUSH:
				var until_final_call := maxf(0.0, time_left - FINAL_CALL_DURATION)
				if remaining < until_final_call:
					time_left -= remaining
					return
				remaining -= until_final_call
				time_left = FINAL_CALL_DURATION
				_set_phase(GameTypes.Phase.FINAL_CALL)
			GameTypes.Phase.FINAL_CALL:
				if remaining < time_left:
					time_left -= remaining
					return
				time_left = 0.0
				_enter_closed()
				return
			GameTypes.Phase.RESULTS:
				if remaining < _phase_time_left:
					_phase_time_left -= remaining
					return
				_phase_time_left = 0.0
				_match_running = false
				_set_phase(GameTypes.Phase.IDLE)
				return
			_:
				return


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
	if not is_inside_tree():
		return Vector3.ZERO
	var checkout: Node = get_tree().get_first_node_in_group("checkout_zone")
	if checkout is Node3D:
		return (checkout as Node3D).global_position
	return Vector3.ZERO


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
	if phase != GameTypes.Phase.IDLE:
		return
	_match_generation += 1
	_close_pending = false
	_match_running = true
	_last_results = null
	round_number = 1
	time_left = ROUND_DURATION
	_phase_time_left = COUNTDOWN_DURATION
	_reset_registered_carts()
	_set_phase(GameTypes.Phase.COUNTDOWN)


func _enter_rush() -> void:
	time_left = ROUND_DURATION
	_set_phase(GameTypes.Phase.RUSH)
	round_started.emit(round_number)


func _enter_closed() -> void:
	if phase == GameTypes.Phase.CLOSED:
		return
	time_left = 0.0
	_set_phase(GameTypes.Phase.CLOSED)
	if not _close_pending:
		_close_pending = true
		call_deferred("_finalize_round", _match_generation)


func _finalize_round(generation: int) -> void:
	if generation != _match_generation or not _close_pending or phase != GameTypes.Phase.CLOSED:
		return
	_close_pending = false
	_last_results = _build_round_results()
	_phase_time_left = RESULTS_DURATION
	_set_phase(GameTypes.Phase.RESULTS)
	round_ended.emit(_last_results)


func _build_round_results() -> RoundResults:
	var results := RoundResults.new()
	results.round_number = round_number
	for cart: Cart in get_carts():
		var cart_id := cart.cart_id
		results.banked[cart_id] = get_round_banked(cart_id)
	return results


func _reset_registered_carts() -> void:
	if not is_inside_tree():
		return
	var store := get_tree().get_first_node_in_group("store_level") as Store
	if store == null:
		return
	var starts := store.get_start_transforms()
	for cart: Cart in get_carts():
		if cart.cart_id >= 0 and cart.cart_id < starts.size():
			cart.reset_for_round(starts[cart.cart_id])


func _set_phase(next_phase: GameTypes.Phase) -> void:
	if phase == next_phase:
		return
	phase = next_phase
	phase_changed.emit(phase)
