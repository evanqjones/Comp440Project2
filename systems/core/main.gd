extends Node
## Integrates Anthony's Store and Rickey's human-player systems for Run Project.

const CAMERA_SCENE: PackedScene = preload("res://systems/player/chase_camera.tscn")
const CART_SCENE: PackedScene = preload("res://systems/cart/cart.tscn")
const BOT_AGENT_RADIUS: float = 0.75

@onready var _store: Store = $Store
@onready var _carts: Node3D = $Carts
@onready var _player: Cart = $Carts/PlayerCart


func _ready() -> void:
	var starts := _store.get_start_transforms()
	if not starts.is_empty():
		_player.global_transform = starts[0]
	RoundManager.register_cart(_player)
	var controller := PlayerController.new()
	controller.name = "PlayerController"
	_player.add_child(controller)
	_spawn_rival("CarlCart", 1, "carl", 12, 0.8, 0.4, starts)
	_spawn_rival("BevCart", 2, "bev", 6, 0.2, 0.2, starts)
	_spawn_rival("RitaCart", 3, "rita", 20, 0.4, 0.9, starts)

	var camera := CAMERA_SCENE.instantiate() as ChaseCamera
	camera.target = _player
	add_child(camera)

	var feedback := PlayerFeedback.new()
	feedback.cart = _player
	feedback.camera = camera
	add_child(feedback)

	var hud := PlayerHud.new()
	hud.name = "PlayerHud"
	hud.cart = _player
	add_child(hud)

	var receipt := RoundReceipt.new()
	receipt.name = "RoundReceipt"
	receipt.cart = _player
	add_child(receipt)
	var pause_menu := PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)


func _spawn_rival(cart_name: String, cart_id: int, profile_name: String, greed: int, aggression: float, boost_habit: float, starts: Array[Transform3D]) -> void:
	if cart_id >= starts.size():
		push_error("Store is missing start transform for %s" % cart_name)
		return
	var cart := CART_SCENE.instantiate() as Cart
	cart.name = cart_name
	cart.cart_id = cart_id
	cart.profile = load("res://systems/shared/profiles/%s.tres" % profile_name) as ShopperProfile
	cart.global_transform = starts[cart_id]
	var agent := NavigationAgent3D.new()
	agent.name = "NavigationAgent3D"
	agent.radius = BOT_AGENT_RADIUS
	agent.path_desired_distance = 1.0
	agent.target_desired_distance = 1.0
	cart.add_child(agent)
	var personality := BotPersonality.new()
	personality.greed = greed
	personality.base_aggression = aggression
	personality.boost_habit = boost_habit
	var controller := BotController.new()
	controller.name = "BotController"
	controller.personality = personality
	controller.cart = cart
	controller.nav_agent = agent
	cart.add_child(controller)
	RoundManager.register_cart(cart)
	_carts.add_child(cart)
