extends Node3D
## Visual inspection scene for the Store Final match Deal and all hazard lifecycles.

const PICKUP_SCENE: PackedScene = preload("res://systems/store/pickup.tscn")

@onready var _store: Store = $Store
@onready var _readout: Label = $CanvasLayer/Readout


func _ready() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	_spawn_deal()
	_readout.text = "Final Store diagnostic\nGold Deal: $100\nBlue wet floor: 8 s slip zone\nOrange pallet jack: 6 s crossing\nRed display: 1 s warning, then 5 s block\nReload this scene to restart the lifecycles."


func _spawn_deal() -> void:
	var item := ItemData.new()
	item.item_id = -100
	item.category = GameTypes.Category.DEAL
	item.value = RoundManager.DEAL_VALUE
	var pickup := PICKUP_SCENE.instantiate() as Pickup
	pickup.name = "Deal"
	pickup.item = item
	_store.add_child(pickup)
	pickup.global_position = Vector3(0.0, 0.0, -10.0)
