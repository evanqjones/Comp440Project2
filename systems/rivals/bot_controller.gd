# systems/rivals/bot_controller.gd
class_name BotController
extends Node

enum AIState { STUCK, BANKING, CHASING, COLLECTING }

@export var cart: Cart
@export var personality: BotPersonality

var decision_timer: Timer
var state: AIState = AIState.COLLECTING
var target_position: Vector3 = Vector3.ZERO

# Test-only overrides
var test_pickups_override: Array[Pickup] = []

var _cmd := DriveCommand.new()


func _ready() -> void:
	decision_timer = Timer.new()
	decision_timer.wait_time = 0.3
	decision_timer.one_shot = false
	add_child(decision_timer)
	decision_timer.timeout.connect(_evaluate_decisions)
	
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


func _on_round_started(_round_number: int) -> void:
	decision_timer.start()


func _on_round_ended(_results: RoundResults) -> void:
	decision_timer.stop()
	# Neutralize output commands immediately
	_cmd.throttle = 0.0
	_cmd.brake = 0.0
	_cmd.steer = 0.0
	_cmd.boost = false


func _evaluate_decisions() -> void:
	# Default state is COLLECTING
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


func _get_pickups() -> Array[Pickup]:
	if not test_pickups_override.is_empty():
		return test_pickups_override
	return RoundManager.get_pickups()
