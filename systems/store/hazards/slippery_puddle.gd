class_name SlipperyPuddle
extends Area3D
## A puddle hazard: each cart spins and spills once on contact.

const SLIP_DURATION: float = 3.0
const LIFETIME_SECONDS: float = 12.0

var _age: float = 0.0
var _affected_carts: Dictionary[int, bool] = {}


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if not RoundManager.is_gameplay_active():
		queue_free()
		return
	_age += delta
	if _age >= LIFETIME_SECONDS:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	var cart := body as Cart
	if cart == null or not RoundManager.is_gameplay_active():
		return
	var cart_instance_id := cart.get_instance_id()
	if _affected_carts.has(cart_instance_id):
		return
	var store := get_tree().get_first_node_in_group("store_level") as Store
	if store == null:
		return

	_affected_carts[cart_instance_id] = true
	cart.apply_slip(SLIP_DURATION)
	store.spawn_dropped_items(cart.global_position, cart.take_all_items())
	_remove_if_all_carts_affected()


func _remove_if_all_carts_affected() -> void:
	var carts := RoundManager.get_carts()
	if carts.is_empty():
		return
	for cart: Cart in carts:
		if is_instance_valid(cart) and not _affected_carts.has(cart.get_instance_id()):
			return
	queue_free()
