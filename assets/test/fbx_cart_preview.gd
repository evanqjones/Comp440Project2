extends Node3D
## Standalone FBX preview that reuses the game's Cart and PlayerController.

const WORLD_LAYER: int = 1
## Crossfade shared-rig poses when the driving state changes.
const ANIMATION_BLEND_SECONDS: float = 0.2
## 100% faster means twice the previous playback rate.
const ANIMATION_SPEED_MULTIPLIER: float = 2.0
const SQUASH_STRETCH_AMOUNT: float = 0.045
const BOUNCE_LIFT_AMOUNT: float = 0.035

@onready var _cart: Cart = $Cart
@onready var _model: Node3D = $Cart/Visual/FBXCart
@onready var _readout: Label = $UI/Readout

var _animation_player: AnimationPlayer
var _animation_names: Dictionary[String, StringName] = {}
var _current_animation: StringName = &""
var _model_base_position: Vector3
var _model_base_scale: Vector3
var _bounce_phase: float = 0.0
var _bounce_intensity: float = 0.0
var _mirror_left_turn: bool = false


func _ready() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	$Cart/Visual/PlaceholderMesh.visible = false
	$Cart/Visual/Nose.visible = false
	$Cart/Visual/Shopper.visible = false
	_build_arena()

	# The imported FBX spans y=-0.415..0.415. Lift its root so the cart's wheels
	# meet the floor while keeping the actual Cart origin at floor level.
	_model.position = Vector3(0.0, 0.415, 0.0)
	_model_base_position = _model.position
	_model_base_scale = _model.scale
	_setup_animations()
	_build_readout()


func _build_arena() -> void:
	_add_box(Vector3(0.0, -0.25, 0.0), Vector3(60.0, 0.5, 60.0), Color("#BDEBD3"))
	_add_box(Vector3(-3.0, 1.0, -12.0), Vector3(0.6, 2.0, 24.0), Color("#FFF6E0"))
	_add_box(Vector3(3.0, 1.0, -12.0), Vector3(0.6, 2.0, 24.0), Color("#FFF6E0"))
	_add_box(Vector3(-7.0, 0.75, 4.0), Vector3(1.0, 1.5, 1.0), Color("#8E24AA"))
	_add_box(Vector3(7.0, 0.75, -3.0), Vector3(1.0, 1.5, 1.0), Color("#FF9800"))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	add_child(sun)


func _add_box(center: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = center
	body.collision_layer = WORLD_LAYER
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	box_mesh.material = material
	mesh_instance.mesh = box_mesh
	body.add_child(mesh_instance)
	add_child(body)


func _build_readout() -> void:
	var speed := Vector2(_cart.velocity.x, _cart.velocity.z).length()
	_readout.text = "FBX cart preview  ·  %.1f m/s\nW / ↑ gas     S / ↓ brake and reverse     A/D or ←/→ steer\nSpace: boost pose     Animation: %s" % [speed, _current_animation]


func _process(delta: float) -> void:
	if _readout != null and _cart != null:
		_update_animation()
		_update_bounce(delta)
		var speed := Vector2(_cart.velocity.x, _cart.velocity.z).length()
		var label := String(_current_animation) if not _current_animation.is_empty() else "none"
		_readout.text = "FBX cart preview  ·  %.1f m/s\nW / ↑ gas     S / ↓ brake and reverse     A/D or ←/→ steer\nSpace: boost pose     Animation: %s" % [speed, label]


func _setup_animations() -> void:
	_animation_player = _find_animation_player(_model)
	if _animation_player == null:
		return
	for animation_name: StringName in _animation_player.get_animation_list():
		var full_name := String(animation_name)
		var clip_name := full_name.substr(full_name.rfind("|") + 1).to_lower()
		_animation_names[clip_name] = animation_name
		if clip_name in ["walk", "backwards", "idle", "turn", "boost"]:
			var clip := _animation_player.get_animation(animation_name)
			clip.loop_mode = Animation.LOOP_LINEAR
	_animation_player.animation_finished.connect(_on_animation_finished)


func _find_animation_player(root_node: Node) -> AnimationPlayer:
	var pending: Array[Node] = [root_node]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is AnimationPlayer:
			return node as AnimationPlayer
		for child: Node in node.get_children():
			pending.append(child)
	return null


func _update_animation() -> void:
	if _animation_player == null:
		return
	var forward := -_cart.global_basis.z
	var forward_speed := _cart.velocity.dot(forward)
	var steering := Input.get_axis("steer_left", "steer_right")
	var wanted := "idle"
	if absf(forward_speed) > 0.2:
		if forward_speed < 0.0:
			wanted = "backwards"
		elif Input.is_action_pressed("boost") and _animation_names.has("boost"):
			wanted = "boost"
		elif absf(steering) > 0.2 and _animation_names.has("turn"):
			wanted = "turn"
		else:
			wanted = "walk"
	_mirror_left_turn = wanted == "turn" and steering < 0.0
	if not _animation_names.has(wanted):
		return
	var clip_name: StringName = _animation_names[wanted]
	if _current_animation != clip_name:
		_current_animation = clip_name
		_animation_player.play(clip_name, ANIMATION_BLEND_SECONDS)
	var movement_speed_scale := clampf(absf(forward_speed) / 3.0, 0.55, 1.5) if wanted != "idle" else 1.0
	_animation_player.speed_scale = movement_speed_scale * ANIMATION_SPEED_MULTIPLIER


func _update_bounce(delta: float) -> void:
	var speed := Vector2(_cart.velocity.x, _cart.velocity.z).length()
	var target_intensity := clampf(speed / 4.0, 0.0, 1.0)
	_bounce_intensity = move_toward(_bounce_intensity, target_intensity, delta * 3.0)
	_bounce_phase += delta * TAU * lerpf(1.5, 3.0, target_intensity)
	var pulse := sin(_bounce_phase) * SQUASH_STRETCH_AMOUNT * _bounce_intensity
	var vertical_scale := 1.0 + pulse
	var side_scale := 1.0 - pulse * 0.5
	var mirror_sign := -1.0 if _mirror_left_turn else 1.0
	_model.scale = Vector3(
		absf(_model_base_scale.x) * side_scale * mirror_sign,
		_model_base_scale.y * vertical_scale,
		_model_base_scale.z * side_scale
	)
	_model.position = _model_base_position + Vector3(
		0.0,
		_model_base_position.y * pulse + sin(_bounce_phase * 0.5) * BOUNCE_LIFT_AMOUNT * _bounce_intensity,
		0.0
	)


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == _current_animation and _animation_player != null:
		_animation_player.play(_current_animation)
