extends Node
## The referee: round phases, timer, doors, pickups, checkout, and scoring (docs/CONTRACTS.md §3).
## Registered as the autoload "RoundManager". No class_name: it would clash with the autoload name.
##
## Every contract signal, variable, and method keeps its frozen signature. Tests in
## tests/shared/test_contracts.gd check the cross-system API.

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
const REGULAR_SPAWN_INTERVAL: float = 0.5
const REGULAR_PICKUP_CAP: int = 46
const CATEGORY_WEIGHTS: Array[float] = [30.0, 25.0, 25.0, 12.0, 6.0, 2.0]
const CATEGORY_VALUES: Array[int] = [5, 10, 10, 15, 20, 40]

## Read-only for other systems. (Tests may set phase directly; game code must not.)
var phase: GameTypes.Phase = GameTypes.Phase.IDLE
## 1..3; 0 before the first round. Never name this `round`: it shadows the built-in round().
var round_number: int = 0
## Seconds left in the current round.
var time_left: float = 0.0
var doors_open: bool = false

var _carts: Array[Cart] = []
var _pickups: Array[Pickup] = []
var _phase_time_left: float = 0.0
var _close_pending: bool = false
var _match_running: bool = false
var _match_generation: int = 0
var _last_results: RoundResults
var _regular_spawn_time_left: float = REGULAR_SPAWN_INTERVAL
var _next_item_id: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


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
					_advance_regular_spawns(remaining)
					time_left -= remaining
					return
				_advance_regular_spawns(minf(remaining, until_final_call))
				remaining -= until_final_call
				time_left = FINAL_CALL_DURATION
				_set_phase(GameTypes.Phase.FINAL_CALL)
			GameTypes.Phase.FINAL_CALL:
				if remaining < time_left:
					_advance_regular_spawns(remaining)
					time_left -= remaining
					return
				_advance_regular_spawns(time_left)
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
	_pickups.assign(_pickups.filter(func(pickup: Pickup) -> bool:
		return is_instance_valid(pickup) and not pickup.is_taken()
	))
	return _pickups.duplicate()


func _register_pickup(pickup: Pickup) -> void:
	if is_instance_valid(pickup) and not _pickups.has(pickup):
		_pickups.append(pickup)


func _unregister_pickup(pickup: Pickup) -> void:
	_pickups.erase(pickup)


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
	_clear_pickups()
	_regular_spawn_time_left = REGULAR_SPAWN_INTERVAL
	_next_item_id = 0
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


func _advance_regular_spawns(active_seconds: float) -> void:
	if active_seconds <= 0.0:
		return
	if get_pickups().size() >= REGULAR_PICKUP_CAP:
		_regular_spawn_time_left = REGULAR_SPAWN_INTERVAL
		return
	_regular_spawn_time_left -= active_seconds
	while _regular_spawn_time_left <= 0.0 and get_pickups().size() < REGULAR_PICKUP_CAP:
		if _spawn_regular_pickup() == null:
			_regular_spawn_time_left = REGULAR_SPAWN_INTERVAL
			return
		_regular_spawn_time_left += REGULAR_SPAWN_INTERVAL
		if get_pickups().size() >= REGULAR_PICKUP_CAP:
			_regular_spawn_time_left = REGULAR_SPAWN_INTERVAL


func _spawn_regular_pickup() -> Pickup:
	var store := get_tree().get_first_node_in_group("store_level") as Store
	if store == null:
		return null
	var category := _category_for_roll(_rng.randf_range(0.0, 100.0))
	var item := ItemData.new()
	item.item_id = _next_item_id
	item.category = category
	item.value = _item_value_for_category(category)
	var pickup := store.spawn_pickup(item)
	if pickup != null:
		_next_item_id += 1
	return pickup


func _category_for_roll(roll: float) -> GameTypes.Category:
	var bounded_roll := clampf(roll, 0.0, 99.999999)
	var boundary: float = 0.0
	for index: int in CATEGORY_WEIGHTS.size():
		boundary += CATEGORY_WEIGHTS[index]
		if bounded_roll < boundary:
			return index as GameTypes.Category
	return GameTypes.Category.ELECTRONICS


func _item_value_for_category(category: GameTypes.Category) -> int:
	var index := int(category)
	if index < 0 or index >= CATEGORY_VALUES.size():
		return 0
	return CATEGORY_VALUES[index]


func _clear_pickups() -> void:
	for pickup: Pickup in _pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()
	_pickups.clear()


func _set_phase(next_phase: GameTypes.Phase) -> void:
	if phase == next_phase:
		return
	phase = next_phase
	phase_changed.emit(phase)
