class_name Cart
extends CharacterBody3D
## The shopping cart that the player and the bots drive (docs/CONTRACTS.md §2).
##
## Driving: cart/01-movement (arcade handling; rules in CartMotion, numbers in CartTuning).
## Still stubs: inventory (cart/02-inventory), ram-steal (cart/03-ram-steal), slip (Final).
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

var _items: Array[ItemData] = []
var _boost_meter: float = 1.0
var _is_stunned: bool = false
var _is_immune: bool = false

# Latest command, copied in apply_command and consumed by the next physics step.
var _throttle: float = 0.0
var _brake: float = 0.0
var _steer: float = 0.0
var _boost: bool = false
## Planar speed just before the last move_and_slide(); cart/03 compares these at contact.
var _speed_before_move: float = 0.0


func _ready() -> void:
	if tuning == null:
		tuning = DEFAULT_TUNING as CartTuning


## Called by the driver every physics frame. Values are copied; the command object isn't kept.
## A frame with no call counts as neutral.
func apply_command(cmd: DriveCommand) -> void:
	_throttle = clampf(cmd.throttle, 0.0, 1.0)
	_brake = clampf(cmd.brake, 0.0, 1.0)
	_steer = clampf(cmd.steer, -1.0, 1.0)
	_boost = cmd.boost


func _physics_process(delta: float) -> void:
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
	var top := CartMotion.top_speed(tuning, _items.size(), false)
	speed = CartMotion.next_forward_speed(tuning, speed, throttle, brake, top, delta)
	sideways = CartMotion.fade_sideways(tuning, sideways, delta)
	planar = forward * speed + sideways
	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	_speed_before_move = planar.length()
	move_and_slide()


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
