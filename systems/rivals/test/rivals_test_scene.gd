extends Node3D
## TEST-ONLY scene for rivals hand checks (rivals/01-foundation & 03-hazard_detection).
## Spawns floor, obstacles, dummy pickups, checkout zone, and configures two bots (Carl and Rita).
## Shows live FSM readouts. Press R to reset, SPACE to spawn pickups, H to spawn hazard, C to toggle checkout hazard, F to enter FINAL_CALL.

const CART_SCENE := preload("res://systems/cart/cart.tscn")

var _carl: Cart
var _rita: Cart
var _carl_controller: BotController
var _rita_controller: BotController

var _readout: Label
var _checkout_hazard: Node3D = null


func _ready() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	RoundManager.time_left = 60.0
	
	_build_arena()
	_spawn_bots()
	_spawn_initial_pickups()
	_build_readout()


func _process(delta: float) -> void:
	_update_readout()
	
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		_spawn_random_pickup()
		
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()
		
	if Input.is_key_pressed(KEY_F):
		RoundManager.phase = GameTypes.Phase.FINAL_CALL
		RoundManager.time_left = 4.0 # Forces checkout desperation rush
		
	if Input.is_key_pressed(KEY_H):
		_spawn_hazard_near_carl()
		
	if Input.is_key_pressed(KEY_C):
		_toggle_checkout_hazard()


func _build_arena() -> void:
	# Add floor
	_add_box(Vector3(0.0, -0.5, 0.0), Vector3(50.0, 1.0, 50.0), Color("#E0F7FA"))
	# Add boundaries
	_add_box(Vector3(0.0, 1.0, -25.5), Vector3(52.0, 2.0, 1.0), Color("#CFD8DC"))
	_add_box(Vector3(0.0, 1.0, 25.5), Vector3(52.0, 2.0, 1.0), Color("#CFD8DC"))
	_add_box(Vector3(-25.5, 1.0, 0.0), Vector3(1.0, 2.0, 52.0), Color("#CFD8DC"))
	_add_box(Vector3(25.5, 1.0, 0.0), Vector3(1.0, 2.0, 52.0), Color("#CFD8DC"))
	
	# Add some central pillars for stuck-recovery checks
	_add_box(Vector3(-5.0, 1.0, -5.0), Vector3(2.0, 2.0, 2.0), Color("#78909C"))
	_add_box(Vector3(5.0, 1.0, 5.0), Vector3(2.0, 2.0, 2.0), Color("#78909C"))
	
	# Add checkout zone
	_build_checkout_pad(Vector3(0.0, 0.1, 20.0))


func _build_checkout_pad(pos: Vector3) -> void:
	var checkout := Area3D.new()
	checkout.name = "CheckoutZone"
	checkout.add_to_group("checkout_zone")
	checkout.global_position = pos
	
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6.0, 1.0, 4.0)
	col.shape = box
	checkout.add_child(col)
	
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(6.0, 0.05, 4.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.8, 0.2, 0.8) # Bright green pad
	mesh.material = mat
	mesh_inst.mesh = mesh
	checkout.add_child(mesh_inst)
	
	add_child(checkout)


func _spawn_hazard_at(pos: Vector3) -> Node3D:
	var hazard := Node3D.new()
	hazard.global_position = pos
	hazard.add_to_group("stage_hazards")
	
	var mesh_inst := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 2.5
	cylinder.bottom_radius = 2.5
	cylinder.height = 0.1
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.8, 0.0, 0.6) # Translucent amber hazard puddle
	cylinder.material = mat
	mesh_inst.mesh = cylinder
	hazard.add_child(mesh_inst)
	
	add_child(hazard)
	RoundManager.hazard_spawned.emit(hazard)
	return hazard


func _spawn_hazard_near_carl() -> void:
	if not is_instance_valid(_carl):
		return
	var forward := -_carl.global_transform.basis.z.normalized()
	var spawn_pos := _carl.global_position + forward * 4.0
	spawn_pos.y = 0.05
	_spawn_hazard_at(spawn_pos)


func _toggle_checkout_hazard() -> void:
	if is_instance_valid(_checkout_hazard):
		_checkout_hazard.queue_free()
		_checkout_hazard = null
	else:
		_checkout_hazard = _spawn_hazard_at(Vector3(0.0, 0.05, 17.5))


func _spawn_bots() -> void:
	# Spawn Coupon Carl
	_carl = CART_SCENE.instantiate() as Cart
	_carl.cart_id = 0
	_carl.global_position = Vector3(-10.0, 0.1, 0.0)
	add_child(_carl)
	RoundManager.register_cart(_carl)
	
	_carl_controller = BotController.new()
	var p_carl := BotPersonality.new()
	p_carl.greed = 12
	p_carl.base_aggression = 0.8
	p_carl.boost_habit = 0.4
	_carl_controller.personality = p_carl
	_carl_controller.cart = _carl
	_carl.add_child(_carl_controller)
	_carl_controller._round_active = true
	
	# Spawn Rolling Rita
	_rita = CART_SCENE.instantiate() as Cart
	_rita.cart_id = 1
	_rita.global_position = Vector3(10.0, 0.1, 0.0)
	add_child(_rita)
	RoundManager.register_cart(_rita)
	
	_rita_controller = BotController.new()
	var p_rita := BotPersonality.new()
	p_rita.greed = 20
	p_rita.base_aggression = 0.4
	p_rita.boost_habit = 0.9
	_rita_controller.personality = p_rita
	_rita_controller.cart = _rita
	_rita.add_child(_rita_controller)
	_rita_controller._round_active = true


func _spawn_initial_pickups() -> void:
	for i in range(10):
		_spawn_random_pickup()


func _spawn_random_pickup() -> void:
	var pickup := Pickup.new()
	var item := ItemData.new()
	item.item_id = randi()
	item.value = randi_range(10, 100)
	pickup.item = item
	
	# Spawn at a random position inside bounds
	var rx := randf_range(-20.0, 20.0)
	var rz := randf_range(-20.0, 20.0)
	pickup.global_position = Vector3(rx, 0.5, rz)
	
	add_child(pickup)


func _add_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.global_position = pos
	
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	col.shape = box
	body.add_child(col)
	
	var mesh_inst := MeshInstance3D.new()
	var cube_mesh := BoxMesh.new()
	cube_mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	cube_mesh.material = mat
	mesh_inst.mesh = cube_mesh
	body.add_child(mesh_inst)
	
	add_child(body)


func _build_readout() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	
	_readout = Label.new()
	_readout.position = Vector2(20, 20)
	_readout.theme_type_variation = "HeaderLabel"
	
	# Simple backing panel
	var panel := ColorRect.new()
	panel.color = Color(0, 0, 0, 0.6)
	panel.size = Vector2(500, 300)
	panel.position = Vector2(10, 10)
	canvas.add_child(panel)
	canvas.add_child(_readout)


func _update_readout() -> void:
	var phase_str := "RUSH" if RoundManager.time_left > 20.0 else "FINAL_CALL"
	var text := "RIVALS HAZARD DETECTION PLAYGROUND\n"
	text += "--------------------------------------\n"
	text += "Phase: %s | Time Left: %.1fs | Hazards: %d\n" % [phase_str, RoundManager.time_left, get_tree().get_nodes_in_group("stage_hazards").size()]
	text += "Controls: [H] Spawn Hazard at Carl | [C] Toggle Checkout Hazard\n"
	text += "          [F] Final Call (<=5s) | [SPACE] Spawn Pickup | [R] Reset\n\n"
	
	if _carl_controller != null and is_instance_valid(_carl):
		text += "COUPON CARL (Bot 0):\n"
		text += " - FSM State: %s\n" % _state_name(_carl_controller.state)
		text += " - Speed: %.1f m/s\n" % _carl.get_state().speed
		text += " - Target Pos: %s\n" % str(_carl_controller.target_position)
		text += " - Tracked Hazards: %d\n" % _carl_controller.get_active_hazards().size()
		text += " - Blacklist Size: %d\n\n" % _carl_controller.unreachable_blacklist.size()
		
	if _rita_controller != null and is_instance_valid(_rita):
		text += "ROLLING RITA (Bot 1):\n"
		text += " - FSM State: %s\n" % _state_name(_rita_controller.state)
		text += " - Speed: %.1f m/s\n" % _rita.get_state().speed
		text += " - Target Pos: %s\n" % str(_rita_controller.target_position)
		text += " - Tracked Hazards: %d\n" % _rita_controller.get_active_hazards().size()
		text += " - Blacklist Size: %d\n" % _rita_controller.unreachable_blacklist.size()
		
	_readout.text = text


func _state_name(state: int) -> String:
	match state:
		0: return "STUCK"
		1: return "BANKING"
		2: return "CHASING"
		3: return "COLLECTING"
	return "UNKNOWN"
