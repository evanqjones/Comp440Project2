extends Node3D
## TEST-ONLY scene for rivals hand checks (rivals/01-foundation).
## Spawns floor, obstacles, dummy pickups, and configures two bots (Carl and Rita).
## Shows live FSM readouts. Press R to reset, SPACE to spawn pickups, F to enter FINAL_CALL.

const CART_SCENE := preload("res://systems/cart/cart.tscn")

var _carl: Cart
var _rita: Cart
var _carl_controller: BotController
var _rita_controller: BotController

var _readout: Label


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
		RoundManager.time_left = 19.0 # Forces banking


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
	var text := "RIVALS FOUNDATION PLAYGROUND\n"
	text += "--------------------------------------\n"
	text += "Round Phase: %s | Time Left: %.1fs\n" % [phase_str, RoundManager.time_left]
	text += "Controls: [R] Reset | [SPACE] Spawn Pickup | [F] Final Call\n\n"
	
	if _carl_controller != null and is_instance_valid(_carl):
		text += "COUPON CARL (Bot 0):\n"
		text += " - FSM State: %s\n" % _state_name(_carl_controller.state)
		text += " - Speed: %.1f m/s\n" % _carl.get_state().speed
		text += " - Target Pos: %s\n" % str(_carl_controller.target_position)
		text += " - Blacklist Size: %d\n\n" % _carl_controller.unreachable_blacklist.size()
		
	if _rita_controller != null and is_instance_valid(_rita):
		text += "ROLLING RITA (Bot 1):\n"
		text += " - FSM State: %s\n" % _state_name(_rita_controller.state)
		text += " - Speed: %.1f m/s\n" % _rita.get_state().speed
		text += " - Target Pos: %s\n" % str(_rita_controller.target_position)
		text += " - Blacklist Size: %d\n" % _rita_controller.unreachable_blacklist.size()
		
	_readout.text = text


func _state_name(state: int) -> String:
	match state:
		0: return "STUCK"
		1: return "BANKING"
		2: return "CHASING"
		3: return "COLLECTING"
	return "UNKNOWN"
