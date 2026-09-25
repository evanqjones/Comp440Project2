extends Node3D
## FALLBACK demo round (docs/features/player/02-demo-round/FEATURE.md): a greybox store, a 2:00
## round, the real player cart + PlayerController + ChaseCamera, John's three bots
## (player/03-demo-bots), a checkout pad, spills and a plain HUD. STAND-IN ONLY: Store's store
## scene and RoundManager (Anthony) and the real HUD replace it in main.tscn. Press R to restart.

const CART_SCENE := preload("res://systems/cart/cart.tscn")
const CAMERA_SCENE := preload("res://systems/player/chase_camera.tscn")
const TestPickup := preload("res://systems/cart/test/test_pickup.gd")
const TestCheckoutPad := preload("res://systems/cart/test/test_checkout_pad.gd")
const PAD_POSITION := Vector3(0.0, 0.0, 15.0)
## Bot personalities from GAME_SPEC.md §12: greed (items), aggression, boost habit.
const BOT_PERSONALITIES := {
	"carl": [12, 0.8, 0.4],
	"bev": [6, 0.2, 0.2],
	"rita": [20, 0.4, 0.9],
}
## Navmesh clearance and agent size: covers the 0.8 × 1.2 m cart (3 navmesh cells).
const BOT_AGENT_RADIUS := 0.75

## Six 6.5 m lanes between seven shelves; lane colors follow GAME_SPEC.md §6 (produce … electronics).
const LANE_X := [-18.75, -11.25, -3.75, 3.75, 11.25, 18.75]
const SHELF_X := [-22.5, -15.0, -7.5, 0.0, 7.5, 15.0, 22.5]
const LANE_COLORS := [
	Color("#4CAF50"), Color("#FF9800"), Color("#F5F5F5"),
	Color("#E53935"), Color("#1E88E5"), Color("#8E24AA"),
]

var _elapsed := 0.0
var _player: Cart
var _carts: Array[Cart] = []
var _pad: Area3D
var _status: Label
var _scores: Label
var _banner: Label
var _results_shown := false
var _rng := RandomNumberGenerator.new()
var _nav_region: NavigationRegion3D
## cart_id -> John's BotController, for the HUD.
var _bots: Dictionary = {}
## Anthony's RoundManager script, put back when the demo exits.
var _stub_script: Script


func _ready() -> void:
	_rng.seed = 440
	_use_stand_in_round_manager()
	RoundManager.phase = GameTypes.Phase.COUNTDOWN
	RoundManager.round_number = 1
	_build_store()
	_build_carts()
	_build_hud()


func _physics_process(delta: float) -> void:
	if _results_shown:
		return
	_elapsed += delta
	RoundManager.time_left = DemoRoundClock.time_left(_elapsed)
	var phase := DemoRoundClock.phase_at(_elapsed)
	if phase == GameTypes.Phase.CLOSED:
		_set_phase(GameTypes.Phase.RESULTS)
		_results_shown = true
		RoundManager.round_ended.emit(_round_results())
	elif phase != RoundManager.phase:
		_set_phase(phase)
		if phase == GameTypes.Phase.RUSH:
			RoundManager.round_started.emit(RoundManager.round_number)


func _exit_tree() -> void:
	if _stub_script != null:
		RoundManager.set_script(_stub_script)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_R:
		get_tree().reload_current_scene()


# --- Round (stand-in for Store's RoundManager) ---------------------------------

## Anthony's RoundManager is still a stub (no pickups, checkout at the origin), so while the demo
## runs, DemoRoundManager answers John's bots. _exit_tree restores the stub.
func _use_stand_in_round_manager() -> void:
	_stub_script = RoundManager.get_script()
	RoundManager.set_script(DemoRoundManager)
	var stand_in := RoundManager as DemoRoundManager
	stand_in.demo_pickup_parent = self
	stand_in.demo_checkout_position = PAD_POSITION


func _set_phase(phase: GameTypes.Phase) -> void:
	RoundManager.phase = phase
	RoundManager.phase_changed.emit(phase)


func _round_results() -> RoundResults:
	var results := RoundResults.new()
	results.round_number = RoundManager.round_number
	for cart: Cart in _carts:
		results.banked[cart.cart_id] = _banked(cart.cart_id)
	return results


# --- Store -------------------------------------------------------------------

func _build_store() -> void:
	_nav_region = NavigationRegion3D.new()
	add_child(_nav_region)
	var wall := Color("#FFF6E0")
	_add_box(Vector3(0.0, -0.5, 0.0), Vector3(60.0, 1.0, 60.0), Color("#BDEBD3"))
	_add_box(Vector3(0.0, 1.25, -20.5), Vector3(52.0, 2.5, 1.0), wall)
	_add_box(Vector3(-25.5, 1.25, -5.0), Vector3(1.0, 2.5, 31.0), wall)
	_add_box(Vector3(25.5, 1.25, -5.0), Vector3(1.0, 2.5, 31.0), wall)
	# Front wall with an 8 m door gap (x -4 … 4).
	_add_box(Vector3(-14.75, 1.25, 10.5), Vector3(21.5, 2.5, 1.0), wall)
	_add_box(Vector3(14.75, 1.25, 10.5), Vector3(21.5, 2.5, 1.0), wall)
	for x: float in SHELF_X:
		_add_box(Vector3(x, 1.0, -9.0), Vector3(1.0, 2.0, 14.0), wall)
	for lane: int in LANE_X.size():
		_add_stripe(Vector3(LANE_X[lane], 0.01, -9.0), Vector3(4.0, 0.02, 14.0), LANE_COLORS[lane])
		for k: int in 5:
			var pickup := TestPickup.new()
			pickup.aisle_category = lane
			pickup.position = Vector3(LANE_X[lane] + _rng.randf_range(-1.8, 1.8), 0.0, -14.0 + k * 3.0)
			add_child(pickup)
	_pad = TestCheckoutPad.new()
	_pad.position = PAD_POSITION
	add_child(_pad)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-35.0, 210.0, 0.0)
	fill.light_energy = 0.35
	fill.light_specular = 0.0
	add_child(fill)
	_bake_navmesh()


## Bots path around the shelves on a navmesh baked from the store's static colliders (layer 1).
## Baked on this thread: the web build has no threads.
func _bake_navmesh() -> void:
	var nav_mesh := NavigationMesh.new()
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.geometry_collision_mask = 1
	nav_mesh.agent_radius = BOT_AGENT_RADIUS
	nav_mesh.agent_height = 2.0
	_nav_region.navigation_mesh = nav_mesh
	_nav_region.bake_navigation_mesh(false)


## A static box on layer 1 (world) with a flat-colored mesh, under the navmesh region.
func _add_box(center: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = center
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	body.add_child(_mesh(size, color))
	_nav_region.add_child(body)


## A flat colored strip on the floor (no collision).
func _add_stripe(center: Vector3, size: Vector3, color: Color) -> void:
	var stripe := _mesh(size, color)
	stripe.position = center
	add_child(stripe)


func _mesh(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	box_mesh.material = material
	mesh.mesh = box_mesh
	return mesh


# --- Carts -------------------------------------------------------------------

func _build_carts() -> void:
	_player = _spawn_cart(Vector3(0.0, 0.0, 20.0), 0.0, 0, "player")
	_player.add_child(PlayerController.new())
	var camera := CAMERA_SCENE.instantiate() as ChaseCamera
	camera.target = _player
	add_child(camera)
	# Everyone starts in a row outside the door, facing the store.
	_spawn_bot(Vector3(-4.5, 0.0, 20.0), 1, "carl")
	_spawn_bot(Vector3(4.5, 0.0, 20.0), 2, "bev")
	_spawn_bot(Vector3(-9.0, 0.0, 20.0), 3, "rita")
	for cart: Cart in _carts:
		RoundManager.register_cart(cart)
		cart.cart_robbed.connect(_on_cart_robbed)


## Positioned before add_child: carts added at one spot get shoved apart by physics.
func _spawn_cart(at: Vector3, yaw: float, id: int, profile_name: String) -> Cart:
	var cart := CART_SCENE.instantiate() as Cart
	cart.position = at
	cart.rotation.y = yaw
	cart.cart_id = id
	cart.profile = load("res://systems/shared/profiles/%s.tres" % profile_name)
	add_child(cart)
	_carts.append(cart)
	return cart


## John's BotController drives the cart, steering with the cart's NavigationAgent3D.
func _spawn_bot(at: Vector3, id: int, profile_name: String) -> void:
	var cart := _spawn_cart(at, 0.0, id, profile_name)
	var agent := NavigationAgent3D.new()
	agent.name = "NavigationAgent3D"
	agent.radius = BOT_AGENT_RADIUS
	agent.path_desired_distance = 1.0
	agent.target_desired_distance = 1.0
	cart.add_child(agent)
	var values: Array = BOT_PERSONALITIES[profile_name]
	var personality := BotPersonality.new()
	personality.greed = values[0]
	personality.base_aggression = values[1]
	personality.boost_habit = values[2]
	var controller := BotController.new()
	controller.personality = personality
	controller.cart = cart
	controller.nav_agent = agent
	cart.add_child(controller)
	_bots[id] = controller


## Stand-in for Store's spill spawner: each spilled item drops near the loser as a one-off pickup.
func _on_cart_robbed(_winner: Cart, loser: Cart, _items: Array[ItemData], spilled: Array[ItemData]) -> void:
	for item: ItemData in spilled:
		var pickup := TestPickup.new()
		pickup.fixed_item = item
		pickup.position = Vector3(
			loser.global_position.x + _rng.randf_range(-1.5, 1.5), 0.0,
			loser.global_position.z + _rng.randf_range(-1.5, 1.5))
		add_child.call_deferred(pickup)


# --- HUD ---------------------------------------------------------------------

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_status = _label(layer, Vector2(16.0, 12.0), 22)
	_scores = _label(layer, Vector2(0.0, 12.0), 18)
	_scores.anchor_left = 1.0
	_scores.anchor_right = 1.0
	_scores.offset_left = -480.0
	_scores.offset_right = -16.0
	_scores.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_banner = _label(layer, Vector2.ZERO, 44)
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.offset_left = -400.0
	_banner.offset_right = 400.0
	_banner.offset_top = -160.0
	_banner.offset_bottom = 160.0
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var help := _label(layer, Vector2(16.0, 0.0), 16)
	help.anchor_top = 1.0
	help.anchor_bottom = 1.0
	help.offset_top = -34.0
	help.text = "W/S gas/brake · A/D steer · Shift/Space boost · ram loaded carts to inherit their haul · green pad = check out · R restart"


func _label(parent: Node, at: Vector2, size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	parent.add_child(label)
	return label


func _process(_delta: float) -> void:
	var phase := RoundManager.phase
	var seconds := ceili(RoundManager.time_left)
	var clock := "%d:%02d" % [seconds / 60, seconds % 60]
	var you := _player.get_state()
	var phase_name: String = "FINAL CALL" if phase == GameTypes.Phase.FINAL_CALL else str(GameTypes.Phase.keys()[phase])
	_status.text = "%s   %s\nYour cart: %d/24 items · $%d   Banked: $%d\nBoost [%s]" % [
		phase_name, clock, you.items.size(), you.value, _banked(0), _boost_bar(you.boost_meter)]
	_status.add_theme_color_override("font_color", Color("#FF5252") if phase == GameTypes.Phase.FINAL_CALL else Color.WHITE)
	var lines: PackedStringArray = []
	for cart: Cart in _carts:
		var state := cart.get_state()
		var line := "%s   banked $%d · cart $%d" % [state.display_name, _banked(cart.cart_id), state.value]
		if _bots.has(cart.cart_id):
			var bot := _bots[cart.cart_id] as BotController
			line += " · %s" % str(BotController.AIState.keys()[bot.state]).to_lower()
		lines.append(line)
	_scores.text = "\n".join(lines)
	if phase == GameTypes.Phase.COUNTDOWN:
		_banner.text = str(ceili(DemoRoundClock.COUNTDOWN - _elapsed))
	elif _elapsed < DemoRoundClock.COUNTDOWN + 0.8:
		_banner.text = "GO!"
	elif _results_shown:
		_banner.text = _results_text()
	else:
		_banner.text = ""


## Ten-step text meter for the fallback HUD (the real %BoostBar comes with the HUD feature).
func _boost_bar(meter: float) -> String:
	var filled := roundi(clampf(meter, 0.0, 1.0) * 10.0)
	return "#".repeat(filled) + "-".repeat(10 - filled)


func _banked(cart_id: int) -> int:
	return int(_pad.get("banked_by_cart").get(cart_id, 0))


func _results_text() -> String:
	var ranked := _carts.duplicate()
	ranked.sort_custom(func(a: Cart, b: Cart) -> bool: return _banked(a.cart_id) > _banked(b.cart_id))
	var lines: PackedStringArray = ["STORE CLOSED"]
	for cart: Cart in ranked:
		lines.append("%s  $%d" % [cart.get_state().display_name, _banked(cart.cart_id)])
	var top: Cart = ranked[0]
	lines.append("WINNER: %s" % top.get_state().display_name if _banked(top.cart_id) > 0 else "Nobody checked out!")
	lines.append("(press R to play again)")
	return "\n".join(lines)
