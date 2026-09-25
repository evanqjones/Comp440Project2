# systems/rivals/bot_controller.gd
class_name BotController
extends Node

@export var cart: Cart
@export var personality: BotPersonality

var decision_timer: Timer
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
	# Stub for future steps
	pass
