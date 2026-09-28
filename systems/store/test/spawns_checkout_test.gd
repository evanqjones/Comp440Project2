extends Node3D
## Visual seam diagnostic: synthesize Cart's post-transfer 20-into-8 result and
## verify Store places the four original overflow items beside the loser.

const STORE_SCENE: PackedScene = preload("res://systems/store/store.tscn")
const CART_SCENE: PackedScene = preload("res://systems/cart/cart.tscn")
const PLAYER_PROFILE: ShopperProfile = preload("res://systems/shared/profiles/player.tres")
const CARL_PROFILE: ShopperProfile = preload("res://systems/shared/profiles/carl.tres")

var _store: Store
var _report: Label


func _ready() -> void:
	_store = STORE_SCENE.instantiate() as Store
	add_child(_store)
	RoundManager.phase = GameTypes.Phase.RUSH
	RoundManager.time_left = 90.0
	var winner := _make_cart(1, PLAYER_PROFILE, Vector3(-4.0, 0.0, 5.0))
	var loser := _make_cart(2, CARL_PROFILE, Vector3(4.0, 0.0, 5.0))
	var original_value := 0
	for item_id: int in 8:
		var item := _make_item(item_id)
		original_value += item.value
		winner.try_add_item(item)
	for item_id: int in 8: # 8-item cart inherits 16 of the loser's 20.
		var item := _make_item(8 + item_id)
		original_value += item.value
		loser.try_add_item(item)
	for item_id: int in 12:
		var item := _make_item(16 + item_id)
		original_value += item.value
		loser.try_add_item(item)

	var loser_items := loser.take_all_items()
	var transferred: Array[ItemData] = []
	var spilled: Array[ItemData] = []
	for index: int in loser_items.size():
		var item := loser_items[index]
		if index < 16 and winner.try_add_item(item):
			transferred.append(item)
		else:
			spilled.append(item)
	loser.cart_robbed.emit(winner, loser, transferred, spilled)
	# Keep the diagnostic's spill pickups visible instead of immediately recollecting them.
	loser.collision_layer = 0
	loser.collision_mask = 0
	loser.set_physics_process(false)
	var spilled_value := 0
	for item: ItemData in spilled:
		spilled_value += item.value
	var conserved_value := winner.get_state().value + spilled_value
	_report = Label.new()
	_report.position = Vector2(18.0, 18.0)
	_report.add_theme_font_size_override("font_size", 20)
	_report.text = "Store spill diagnostic\nSynthetic post-transfer 20 into 8\nWinner: %d items · loser: %d · spills: %d\nValue conserved: $%d / $%d" % [winner.get_state().items.size(), loser.get_state().items.size(), spilled.size(), conserved_value, original_value]
	var canvas := CanvasLayer.new()
	canvas.add_child(_report)
	add_child(canvas)


func _make_cart(cart_id: int, profile: ShopperProfile, spawn_position: Vector3) -> Cart:
	var cart := CART_SCENE.instantiate() as Cart
	cart.cart_id = cart_id
	cart.profile = profile
	cart.position = spawn_position
	add_child(cart)
	RoundManager.register_cart(cart)
	return cart


func _make_item(item_id: int) -> ItemData:
	var item := ItemData.new()
	item.item_id = item_id
	item.category = GameTypes.Category.PRODUCE
	item.value = 5 + item_id
	return item
