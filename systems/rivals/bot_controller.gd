# systems/rivals/bot_controller.gd
class_name BotController
extends Node

enum AIState { STUCK, BANKING, CHASING, COLLECTING }

@export var cart: Cart
@export var personality: BotPersonality

var decision_timer: Timer
var state: AIState = AIState.COLLECTING
var target_position: Vector3 = Vector3.ZERO
var current_aggression: float = 0.5

# Test-only overrides
var test_pickups_override: Array[Pickup] = []
var _randf_override: float = -1.0

var _cmd := DriveCommand.new()


func _ready() -> void:
	decision_timer = Timer.new()
	decision_timer.wait_time = 0.3
	decision_timer.one_shot = false
	add_child(decision_timer)
	decision_timer.timeout.connect(_evaluate_decisions)
	
	if personality != null:
		current_aggression = personality.base_aggression
		
	if RoundManager != null:
		RoundManager.round_started.connect(_on_round_started)
		RoundManager.round_ended.connect(_on_round_ended)


func _physics_process(delta: float) -> void:
	if cart != null:
		cart.apply_command(build_command(delta))


func build_command(_delta: float) -> DriveCommand:
	if not RoundManager.is_gameplay_active():
		_cmd.throttle = 0.0
		_cmd.brake = 0.0
		_cmd.steer = 0.0
		_cmd.boost = false
		return _cmd
	
	# Fallback for future steps (not implemented yet)
	return _cmd


func _on_round_started(round_number: int) -> void:
	decision_timer.start()
	
	var base_agg := 0.5
	if personality != null:
		base_agg = personality.base_aggression
		
	current_aggression = clamp(base_agg + (round_number - 1) * 0.1, 0.0, 1.0)


func _on_round_ended(_results: RoundResults) -> void:
	decision_timer.stop()
	# Neutralize output commands immediately
	_cmd.throttle = 0.0
	_cmd.brake = 0.0
	_cmd.steer = 0.0
	_cmd.boost = false


func _evaluate_decisions() -> void:
	if cart == null:
		return
		
	var cart_state := cart.get_state()
	var item_count := cart_state.items.size()
	
	# 1. Banking check: meets personal greed or time is short (< 20s)
	var greed_limit := 10
	if personality != null:
		greed_limit = personality.greed
		
	if item_count >= greed_limit or RoundManager.time_left <= 20.0:
		state = AIState.BANKING
		target_position = RoundManager.get_checkout_position()
		return
		
	# 2. Chasing check: target qualifying loaded rivals (items >= 10)
	if _evaluate_chasing():
		return
		
	# 3. Collecting state (Default)
	state = AIState.COLLECTING
	
	var pickups := _get_pickups()
	if pickups.is_empty():
		target_position = Vector3.ZERO
		return
		
	var best_pickup: Pickup = null
	var best_utility: float = -1.0
	
	for pickup: Pickup in pickups:
		if not is_instance_valid(pickup) or pickup.item == null:
			continue
			
		var dist := cart.global_position.distance_to(pickup.global_position)
		if dist < 0.01:
			dist = 0.01 # Avoid division by zero
			
		var utility := float(pickup.item.value) / dist
		if utility > best_utility:
			best_utility = utility
			best_pickup = pickup
			
	if best_pickup != null:
		target_position = best_pickup.global_position


func _evaluate_chasing() -> bool:
	var eligible_carts: Array[Cart] = []
	for other_cart: Cart in RoundManager.get_carts():
		if not is_instance_valid(other_cart) or other_cart == cart:
			continue
		var other_state := other_cart.get_state()
		if other_state.items.size() >= 10:
			eligible_carts.append(other_cart)
			
	if eligible_carts.is_empty():
		return false
		
	# Aggression check
	if _randf() > current_aggression:
		return false
		
	# Find target with highest item count; break ties by closest distance
	var best_cart: Cart = null
	var best_count: int = -1
	var best_dist: float = INF
	
	for eligible_cart: Cart in eligible_carts:
		var eligible_state := eligible_cart.get_state()
		var count := eligible_state.items.size()
		var dist := cart.global_position.distance_to(eligible_cart.global_position)
		
		if count > best_count:
			best_count = count
			best_dist = dist
			best_cart = eligible_cart
		elif count == best_count:
			if dist < best_dist:
				best_dist = dist
				best_cart = eligible_cart
				
	if best_cart != null:
		state = AIState.CHASING
		target_position = best_cart.global_position
		return true
		
	return false


func _randf() -> float:
	if _randf_override >= 0.0:
		return _randf_override
	return randf()


func _get_pickups() -> Array[Pickup]:
	if not test_pickups_override.is_empty():
		return test_pickups_override
	return RoundManager.get_pickups()
