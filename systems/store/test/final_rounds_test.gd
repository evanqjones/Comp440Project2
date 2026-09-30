extends Node3D
## Visual inspection scene for the Store Final match Deal presentation.

const PICKUP_SCENE: PackedScene = preload("res://systems/store/pickup.tscn")

@onready var _store: Store = $Store
@onready var _readout: Label = $CanvasLayer/Readout


func _ready() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	_spawn_deal()
	_readout.text = "Final Store diagnostic\nGold Deal: $100\nFloating marker: DEAL OF THE DAY!\nThe Deal beam and label identify it from every aisle."


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
