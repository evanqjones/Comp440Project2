extends Node
## Integrates Anthony's Store and Rickey's human-player systems for Run Project.

const CAMERA_SCENE: PackedScene = preload("res://systems/player/chase_camera.tscn")

@onready var _player: Cart = $PlayerCart


func _ready() -> void:
	RoundManager.register_cart(_player)
	var controller := PlayerController.new()
	controller.name = "PlayerController"
	_player.add_child(controller)

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
