# systems/rivals/bot_controller.gd
class_name BotController
extends Node

enum AIState { STUCK, BANKING, CHASING, COLLECTING }

const DEFAULT_HAZARD_RADIUS: float = 2.5

@export var cart: Cart:
	set(value):
		cart = value
		if is_inside_tree() and cart != null:
			_connect_cart_signals()

@export var personality: BotPersonality
@export var nav_agent: NavigationAgent3D

var decision_timer: Timer
var state: AIState = AIState.COLLECTING
var target_position: Vector3 = Vector3.ZERO
var current_aggression: float = 0.5
var active_target: Node3D = null

# Test-only overrides
var test_pickups_override: Array[Pickup] = []
var test_hazards_override: Array[Node3D] = []
var test_nav_path_override: PackedVector3Array = []
var test_is_target_reachable_override: bool = true
var _randf_override: float = -1.0
var test_decision_ticks_count: int = 0

# Active stage hazards tracked in the scene
var active_hazards: Array[Node3D] = []

# Stuck recovery state properties
var _stuck_reverse_steer: float = 0.0
var _stuck_accumulated_time: float = 0.0
var _stuck_recovery_timer: float = 0.0

# Blacklisted unreachable targets
var unreachable_blacklist: Array[Node3D] = []

# Periodic straightaway boost check timers
var _boost_evaluation_accumulator: float = 0.0
var _boost_active_timer: float = 0.0

var _round_active: bool = false
var _cmd := DriveCommand.new()


func _ready() -> void:
	decision_timer = Timer.new()
	decision_timer.wait_time = 0.3
	decision_timer.one_shot = false
	add_child(decision_timer)
	decision_timer.timeout.connect(_evaluate_decisions)
	
	if nav_agent == null and cart != null:
		nav_agent = cart.get_node_or_null("NavigationAgent3D") as NavigationAgent3D
	if nav_agent == null:
		nav_agent = get_node_or_null("NavigationAgent3D") as NavigationAgent3D
		
	_connect_cart_signals()
	
	if personality != null:
		current_aggression = personality.base_aggression
		
	if RoundManager != null:
		RoundManager.round_started.connect(_on_round_started)
		RoundManager.round_ended.connect(_on_round_ended)
		RoundManager.deal_spawned.connect(_on_deal_spawned)
		RoundManager.hazard_spawned.connect(_on_hazard_spawned)


func get_active_hazards() -> Array[Node3D]:
	if not test_hazards_override.is_empty():
		return test_hazards_override
	var valid: Array[Node3D] = []
	for h in active_hazards:
		if is_instance_valid(h):
			valid.append(h)
	return valid


func get_hazard_radius(hazard: Node3D) -> float:
	if not is_instance_valid(hazard):
		return DEFAULT_HAZARD_RADIUS
	var radius_prop = hazard.get("danger_radius")
	if radius_prop is float and radius_prop > 0.0:
		return radius_prop
	if hazard.has_meta("danger_radius"):
		var meta_val = hazard.get_meta("danger_radius")
		if meta_val is float and meta_val > 0.0:
			return meta_val
	return DEFAULT_HAZARD_RADIUS


func is_position_safe_from_hazards(pos: Vector3) -> bool:
	var hazards := get_active_hazards()
	for h in hazards:
		if not is_instance_valid(h):
			continue
		var h_pos := h.global_position
		var r := get_hazard_radius(h)
		var dist_sq := (pos.x - h_pos.x) * (pos.x - h_pos.x) + (pos.z - h_pos.z) * (pos.z - h_pos.z)
		if dist_sq < r * r:
			return false
	return true


func _distance_to_segment_xz(point: Vector3, seg_a: Vector3, seg_b: Vector3) -> float:
	var pax := point.x - seg_a.x
	var paz := point.z - seg_a.z
	var bax := seg_b.x - seg_a.x
	var baz := seg_b.z - seg_a.z
	var seg_len_sq := bax * bax + baz * baz
	if seg_len_sq <= 0.0001:
		return sqrt(pax * pax + paz * paz)
	var t := clampf((pax * bax + paz * baz) / seg_len_sq, 0.0, 1.0)
	var proj_x := seg_a.x + t * bax
	var proj_z := seg_a.z + t * baz
	var dx := point.x - proj_x
	var dz := point.z - proj_z
	return sqrt(dx * dx + dz * dz)


func is_path_safe_from_hazards(path: PackedVector3Array) -> bool:
	if path.is_empty():
		return true
	var hazards := get_active_hazards()
	if hazards.is_empty():
		return true
	
	if path.size() == 1:
		return is_position_safe_from_hazards(path[0])
	
	for h in hazards:
		if not is_instance_valid(h):
			continue
		var h_pos := h.global_position
		var r := get_hazard_radius(h)
		for i in range(path.size() - 1):
			var dist := _distance_to_segment_xz(h_pos, path[i], path[i + 1])
			if dist < r:
				return false
	return true


func is_target_path_safe(destination: Vector3) -> bool:
	if not is_position_safe_from_hazards(destination):
		return false
	if not test_nav_path_override.is_empty():
		return is_path_safe_from_hazards(test_nav_path_override)
	if nav_agent != null and nav_agent.is_inside_tree():
		var nav_path := nav_agent.get_current_navigation_path()
		if not nav_path.is_empty():
			return is_path_safe_from_hazards(nav_path)
	if cart != null:
		var direct_path: PackedVector3Array = [cart.global_position, destination]
		return is_path_safe_from_hazards(direct_path)
	return true


func _physics_process(delta: float) -> void:
	if cart == null:
		return
		
	# Stuck Recovery and Accumulator logic
	if _round_active and RoundManager != null and RoundManager.is_gameplay_active():
		if state == AIState.STUCK:
			_stuck_recovery_timer += delta
			_boost_active_timer = 0.0
			_boost_evaluation_accumulator = 0.0
			_cmd.boost = false
			if _stuck_recovery_timer >= 1.0:
				# Stuck recovery complete; return to default COLLECTING and force a decision tick
				state = AIState.COLLECTING
				_stuck_accumulated_time = 0.0
				_evaluate_decisions()
		else:
			# Verify active path reachability
			if active_target != null and not _is_target_reachable():
				unreachable_blacklist.append(active_target)
				active_target = null
				_evaluate_decisions()
				
			var speed := cart.get_state().speed
			if speed < 0.5:
				_stuck_accumulated_time += delta
				if _stuck_accumulated_time >= 1.0:
					state = AIState.STUCK
					_stuck_recovery_timer = 0.0
					_stuck_reverse_steer = 1.0 if randf() > 0.5 else -1.0
			else:
				_stuck_accumulated_time = 0.0
				
			# Periodic straightway boost logic
			_tick_boosting(delta)
	else:
		_stuck_accumulated_time = 0.0
		_boost_active_timer = 0.0
		_boost_evaluation_accumulator = 0.0
		_cmd.boost = false
		
	cart.apply_command(build_command(delta))


func build_command(_delta: float) -> DriveCommand:
	if not _round_active or not RoundManager.is_gameplay_active():
		_cmd.throttle = 0.0
		_cmd.brake = 0.0
		_cmd.steer = 0.0
		_cmd.boost = false
		return _cmd
		
	if state == AIState.STUCK:
		_cmd.throttle = 0.0
		_cmd.brake = 1.0 # Backwards reverse
		_cmd.steer = _stuck_reverse_steer
		_cmd.boost = false
		return _cmd
		
	if target_position == Vector3.ZERO:
		_cmd.throttle = 0.0
		_cmd.brake = 0.0
		_cmd.steer = 0.0
		_cmd.boost = false
		return _cmd
		
	# Update NavigationAgent3D target coordinate
	if nav_agent != null and target_position != Vector3.ZERO:
		nav_agent.target_position = target_position
		
	var next_pos := target_position
	if nav_agent != null and nav_agent.is_inside_tree():
		next_pos = nav_agent.get_next_path_position()
		
	var target_dir := (next_pos - cart.global_position).normalized()
	target_dir.y = 0.0
	target_dir = target_dir.normalized()
	
	var forward := -cart.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	
	# Proportional steering
	var angle_diff := forward.signed_angle_to(target_dir, Vector3.UP)
	_cmd.steer = clamp(-angle_diff / (PI / 4.0), -1.0, 1.0) # Cart: steer +1 = right; signed_angle_to is + to the left
	
	# Slow down slightly during sharp turns
	if absf(angle_diff) > PI / 6.0: # > 30 degrees
		_cmd.throttle = 0.4
	else:
		_cmd.throttle = 1.0
		
	_cmd.brake = 0.0
	return _cmd


func _on_round_started(round_number: int) -> void:
	_round_active = true
	active_hazards.clear()
	decision_timer.start()
	
	var base_agg := 0.5
	if personality != null:
		base_agg = personality.base_aggression
		
	current_aggression = clamp(base_agg + (round_number - 1) * 0.1, 0.0, 1.0)


func _on_round_ended(_results: RoundResults) -> void:
	_round_active = false
	decision_timer.stop()
	unreachable_blacklist.clear()
	active_hazards.clear()
	active_target = null
	
	_stuck_accumulated_time = 0.0
	_stuck_recovery_timer = 0.0
	_boost_active_timer = 0.0
	_boost_evaluation_accumulator = 0.0
	
	# Neutralize output commands immediately
	_cmd.throttle = 0.0
	_cmd.brake = 0.0
	_cmd.steer = 0.0
	_cmd.boost = false


func _evaluate_decisions() -> void:
	if cart == null:
		return
		
	test_decision_ticks_count += 1
	
	# Lock out decision timer evaluations during STUCK recovery
	if state == AIState.STUCK:
		active_target = null
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
		active_target = null
		return
		
	# 2. Chasing check: target qualifying loaded rivals (items >= 10)
	if _evaluate_chasing():
		return
		
	# 3. Collecting state (Default)
	state = AIState.COLLECTING
	
	var pickups := _get_pickups()
	if pickups.is_empty():
		target_position = Vector3.ZERO
		active_target = null
		return
		
	var best_pickup: Pickup = null
	var best_utility: float = -1.0
	
	for pickup: Pickup in pickups:
		if not is_instance_valid(pickup) or pickup.item == null:
			continue
		if not is_target_path_safe(pickup.global_position):
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
		active_target = best_pickup
	else:
		target_position = Vector3.ZERO
		active_target = null


func _evaluate_chasing() -> bool:
	var eligible_carts: Array[Cart] = []
	for other_cart: Cart in RoundManager.get_carts():
		if not is_instance_valid(other_cart) or other_cart == cart or unreachable_blacklist.has(other_cart):
			continue
		if not is_target_path_safe(other_cart.global_position):
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
		active_target = best_cart
		return true
		
	return false


func _tick_boosting(delta: float) -> void:
	if _boost_active_timer > 0.0:
		_boost_active_timer -= delta
		_cmd.boost = _boost_active_timer > 0.0
	else:
		_cmd.boost = false
		if active_target != null:
			_boost_evaluation_accumulator += delta
			if _boost_evaluation_accumulator >= 1.0:
				_boost_evaluation_accumulator = 0.0
				
				var habit := 0.5
				if personality != null:
					habit = personality.boost_habit
					
				if _randf() <= habit:
					# Check steering straightness: deviation < 30 degrees
					var forward := -cart.global_transform.basis.z
					forward.y = 0.0
					forward = forward.normalized()
					
					var target_dir := (target_position - cart.global_position).normalized()
					target_dir.y = 0.0
					target_dir = target_dir.normalized()
					
					var angle_deg := rad_to_deg(forward.angle_to(target_dir))
					if absf(angle_deg) < 30.0:
						_boost_active_timer = 1.0 # Boost continuously for 1.0s
						_cmd.boost = true


func _is_target_reachable() -> bool:
	if not test_is_target_reachable_override:
		return false
	if nav_agent != null and nav_agent.is_inside_tree():
		return nav_agent.is_target_reachable()
	return true


func _randf() -> float:
	if _randf_override >= 0.0:
		return _randf_override
	return randf()


func _get_pickups() -> Array[Pickup]:
	var raw_pickups := []
	if not test_pickups_override.is_empty():
		raw_pickups = test_pickups_override
	elif RoundManager != null:
		raw_pickups = RoundManager.get_pickups()
		
	var filtered: Array[Pickup] = []
	for p: Pickup in raw_pickups:
		if is_instance_valid(p) and not unreachable_blacklist.has(p) and is_position_safe_from_hazards(p.global_position):
			filtered.append(p)
	return filtered


func _connect_cart_signals() -> void:
	if cart != null and not cart.cart_robbed.is_connected(_on_cart_robbed):
		cart.cart_robbed.connect(_on_cart_robbed)


func _on_cart_robbed(_winner: Cart, _loser: Cart, _stolen: Array[ItemData], _spilled: Array[ItemData]) -> void:
	if RoundManager != null and RoundManager.is_gameplay_active():
		_evaluate_decisions()
		if decision_timer != null:
			decision_timer.start()


func _on_deal_spawned(_deal: Pickup) -> void: # the contract passes the Pickup (store/06-deal-of-the-day)
	if RoundManager != null and RoundManager.is_gameplay_active():
		_evaluate_decisions()
		if decision_timer != null:
			decision_timer.start()


func _on_hazard_spawned(hazard: Node3D) -> void:
	if not is_instance_valid(hazard) or active_hazards.has(hazard):
		return
	active_hazards.append(hazard)
	if not hazard.tree_exited.is_connected(_on_hazard_tree_exited):
		hazard.tree_exited.connect(_on_hazard_tree_exited.bind(hazard), CONNECT_ONE_SHOT)


func _on_hazard_tree_exited(hazard: Node3D) -> void:
	active_hazards.erase(hazard)
