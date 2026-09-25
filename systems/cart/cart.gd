class_name Cart
extends CharacterBody3D
## The shopping cart that the player and the bots drive (docs/CONTRACTS.md §2).
##
## Driving: cart/01-movement (arcade handling; rules in CartMotion, numbers in CartTuning).
## Carrying: cart/02-inventory (CartInventory holds items oldest first; CartItemStack shows cubes).
## Ram-steal: cart/04-ram-steal (CartSteal rules; whichever cart detects a contact resolves it
## once per pair; the loser emits cart_robbed). Still a stub: slip (Final).
## Keep the contract signatures: tests/shared/test_contracts.gd fails if one changes.

signal item_collected(cart: Cart, item: ItemData)
## Emitted once per steal, after both inventories are updated. items = moved into winner;
## spilled = overflow for Store to spawn.
signal cart_robbed(winner: Cart, loser: Cart, items: Array[ItemData], spilled: Array[ItemData])
signal cart_full(cart: Cart)

const DEFAULT_TUNING := preload("res://systems/cart/cart_tuning.tres")

## 0 = human, 1..3 = bots; set in main.tscn.
@export var cart_id: int = 0
@export var profile: ShopperProfile
## Shared handling numbers. Empty falls back to cart_tuning.tres.
@export var tuning: CartTuning

var _inventory := CartInventory.new()
var _boost_meter: float = 1.0
var _is_stunned: bool = false
var _is_immune: bool = false

# Latest command, copied in apply_command and consumed by the next physics step.
var _throttle: float = 0.0
var _brake: float = 0.0
var _steer: float = 0.0
var _boost: bool = false
## Planar speed just before the last move_and_slide(); cart/04-ram-steal compares these at contact.
var _speed_before_move: float = 0.0
var _stun_left: float = 0.0
var _immune_left: float = 0.0
## Last physics frame each pair of carts resolved a contact (key "idA:idB", lower id first).
static var _pair_frames: Dictionary = {}

@onready var _stack := get_node_or_null("ItemStackDisplay") as CartItemStack


func _ready() -> void:
	if tuning == null:
		tuning = DEFAULT_TUNING as CartTuning
	_inventory.capacity = tuning.item_cap


## Called by the driver every physics frame. Values are copied; the command object isn't kept.
## A frame with no call counts as neutral.
func apply_command(cmd: DriveCommand) -> void:
	_throttle = clampf(cmd.throttle, 0.0, 1.0)
	_brake = clampf(cmd.brake, 0.0, 1.0)
	_steer = clampf(cmd.steer, -1.0, 1.0)
	_boost = cmd.boost


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	var active := RoundManager.is_gameplay_active() and not _is_stunned
	var throttle := _throttle if active else 0.0
	var brake := _brake if active else 0.0
	var steer := _steer if active else 0.0
	_clear_command()

	var planar := Vector3(velocity.x, 0.0, velocity.z)
	rotation.y = CartMotion.next_yaw(tuning, rotation.y, steer, planar.length(), delta)
	var forward := _forward()
	var speed := planar.dot(forward)
	var sideways := planar - forward * speed
	var top := CartMotion.top_speed(tuning, _inventory.count(), false)
	speed = CartMotion.next_forward_speed(tuning, speed, throttle, brake, top, delta)
	sideways = CartMotion.fade_sideways(tuning, sideways, delta, tuning.stun_grip if _is_stunned else -1.0)
	planar = forward * speed + sideways
	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	_speed_before_move = planar.length()
	move_and_slide()
	_check_cart_contacts()


## False if the round isn't active, the cart is full, the item is null, or it's already here.
## A stunned cart still collects (GAME_SPEC.md §5.5).
func try_add_item(item: ItemData) -> bool:
	if not RoundManager.is_gameplay_active():
		return false
	if not _inventory.try_add(item):
		return false
	_refresh_stack()
	item_collected.emit(self, item)
	if _inventory.is_full():
		cart_full.emit(self)
	return true


## Empties the cart and returns what it held, oldest first. Store's checkout calls this.
## Works in any phase (the deferred checkout can land just after close).
func take_all_items() -> Array[ItemData]:
	var taken := _inventory.take_all()
	_refresh_stack()
	return taken


## Empty cart, full boost, no stun or immunity, placed at spawn.
func reset_for_round(spawn: Transform3D) -> void:
	_inventory.take_all()
	_refresh_stack()
	_boost_meter = 1.0
	_is_stunned = false
	_is_immune = false
	_stun_left = 0.0
	_immune_left = 0.0
	_clear_command()
	_speed_before_move = 0.0
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
	state.items = _inventory.items()
	state.value = _inventory.value()
	state.boost_meter = _boost_meter
	state.is_stunned = _is_stunned
	state.is_immune = _is_immune
	return state


## Wet floor: steering is ignored for duration seconds (Final milestone).
func apply_slip(_duration: float) -> void:
	pass # Stub: implemented with hazards (Final).


## The cart's front on the floor plane (Godot's forward is -Z).
func _forward() -> Vector3:
	var forward := -global_basis.z
	forward.y = 0.0
	return forward.normalized()


func _clear_command() -> void:
	_throttle = 0.0
	_brake = 0.0
	_steer = 0.0
	_boost = false


func _refresh_stack() -> void:
	if _stack != null:
		_stack.show_items(_inventory.items())


func _tick_timers(delta: float) -> void:
	_stun_left = maxf(0.0, _stun_left - delta)
	_immune_left = maxf(0.0, _immune_left - delta)
	_is_stunned = _stun_left > 0.0
	_is_immune = _immune_left > 0.0


func _check_cart_contacts() -> void:
	for i: int in get_slide_collision_count():
		var other := get_slide_collision(i).get_collider() as Cart
		if other != null and other != self:
			_resolve_contact(other)


## Resolves one cart-to-cart contact, at most once per pair per pair_cooldown. Whichever cart
## detects the contact calls this (a parked cart can't detect being hit).
func _resolve_contact(other: Cart) -> void:
	if not RoundManager.is_gameplay_active():
		return
	var key := _pair_key(other)
	var frame := Engine.get_physics_frames()
	var cooldown_frames := ceili(tuning.pair_cooldown * Engine.physics_ticks_per_second)
	if _pair_frames.has(key) and frame - int(_pair_frames[key]) < cooldown_frames:
		return
	_pair_frames[key] = frame
	match CartSteal.outcome(tuning, _contact_state(), other._contact_state()):
		CartSteal.Outcome.A_WINS:
			_steal_from(other)
		CartSteal.Outcome.B_WINS:
			other._steal_from(self)
		_:
			var away := _flat_direction(global_position - other.global_position)
			_push(away)
			other._push(-away)


## This cart inherits from `loser`: both inventories update, then the loser emits cart_robbed.
func _steal_from(loser: Cart) -> void:
	var parts := CartSteal.split(loser._inventory.take_all(), _inventory.capacity - _inventory.count())
	var transferred: Array[ItemData] = parts[0]
	var spilled: Array[ItemData] = parts[1]
	for item: ItemData in transferred:
		_inventory.try_add(item)
	velocity.x *= tuning.winner_keep
	velocity.z *= tuning.winner_keep
	loser._knock_down(_flat_direction(loser.global_position - global_position))
	loser._refresh_stack()
	_refresh_stack()
	loser.cart_robbed.emit(self, loser, transferred, spilled)
	if not transferred.is_empty() and _inventory.is_full():
		cart_full.emit(self)


## Robbed: shoved away, stunned and immune.
func _knock_down(away: Vector3) -> void:
	velocity.x = away.x * tuning.knockback_speed
	velocity.z = away.z * tuning.knockback_speed
	_stun_left = tuning.stun_time
	_immune_left = tuning.immune_time
	_is_stunned = true
	_is_immune = true
	_clear_command()


## Non-steal bump: keep bounce_keep of the speed and add bounce_speed along `direction`.
func _push(direction: Vector3) -> void:
	velocity.x = velocity.x * tuning.bounce_keep + direction.x * tuning.bounce_speed
	velocity.z = velocity.z * tuning.bounce_keep + direction.z * tuning.bounce_speed


## Snapshot for the steal rule, using the speed from just before this contact.
func _contact_state() -> CartState:
	var state := get_state()
	state.speed = _speed_before_move
	return state


func _pair_key(other: Cart) -> String:
	var a := get_instance_id()
	var b := other.get_instance_id()
	return "%d:%d" % [mini(a, b), maxi(a, b)]


## Flattened unit direction; falls back to this cart's forward if the carts overlap exactly.
func _flat_direction(v: Vector3) -> Vector3:
	v.y = 0.0
	return v.normalized() if v.length() > 0.001 else _forward()
