extends GutTest
## Deal of the Day (docs/features/store/06-deal-of-the-day/FEATURE.md, GAME_SPEC.md §6): a gold $100
## item with a beam, one on the floor at a time, 14–22 s after the last one left the floor.

const STORE_SCENE := preload("res://systems/store/store.tscn")
const PICKUP_SCENE := preload("res://systems/store/pickup.tscn")
const CART_SCENE := "res://systems/cart/cart.tscn"

var _saved_physics_processing: bool


func before_each() -> void:
	_saved_physics_processing = RoundManager.is_physics_processing()
	RoundManager.set_physics_process(false)
	RoundManager.phase = GameTypes.Phase.IDLE
	RoundManager.round_number = 0
	RoundManager._phase_time_left = 0.0
	RoundManager._close_pending = false
	RoundManager._match_running = false


func after_each() -> void:
	RoundManager._clear_pickups()
	RoundManager.phase = GameTypes.Phase.IDLE
	RoundManager.round_number = 0
	RoundManager._phase_time_left = 0.0
	RoundManager._close_pending = false
	RoundManager._match_running = false
	RoundManager.set_physics_process(_saved_physics_processing)


func _deals() -> Array[Pickup]:
	var deals: Array[Pickup] = []
	for pickup: Pickup in RoundManager.get_pickups():
		if is_instance_valid(pickup) and pickup.item != null and pickup.item.is_deal:
			deals.append(pickup)
	return deals


func _start_round() -> void:
	add_child_autofree(STORE_SCENE.instantiate())
	RoundManager.start_match()
	RoundManager._physics_process(RoundManager.COUNTDOWN_DURATION)
	assert_eq(RoundManager.phase, GameTypes.Phase.RUSH)


func _deal_item() -> ItemData:
	var item := ItemData.new()
	item.item_id = 99000
	item.category = GameTypes.Category.DEAL
	item.value = 100
	item.is_deal = true
	return item


func test_first_deal_arrives_14_to_22_seconds_into_the_round() -> void:
	_start_round()
	watch_signals(RoundManager)
	RoundManager._physics_process(RoundManager.DEAL_DELAY_MIN - 0.1)
	assert_eq(_deals().size(), 0, "not before 14 s")
	RoundManager._physics_process(RoundManager.DEAL_DELAY_MAX - RoundManager.DEAL_DELAY_MIN + 0.2)
	var deals := _deals()
	assert_eq(deals.size(), 1, "one deal by 22 s")
	if deals.size() == 1:
		var item := deals[0].item
		assert_eq(item.value, 100)
		assert_eq(item.category, GameTypes.Category.DEAL)
		assert_signal_emitted_with_parameters(RoundManager, "deal_spawned", [deals[0]])


func test_only_one_deal_on_the_floor_at_a_time() -> void:
	_start_round()
	RoundManager._physics_process(RoundManager.DEAL_DELAY_MAX + 0.1)
	RoundManager._physics_process(60.0)
	assert_eq(_deals().size(), 1, "still one after a minute on the floor")


func test_next_deal_comes_14_to_22_seconds_after_one_is_collected() -> void:
	_start_round()
	RoundManager._physics_process(RoundManager.DEAL_DELAY_MAX + 0.1)
	var first := _deals()[0]
	RoundManager._unregister_pickup(first) # a cart took it
	first.queue_free()
	RoundManager._physics_process(RoundManager.DEAL_DELAY_MIN - 0.1)
	assert_eq(_deals().size(), 0, "not before 14 s")
	RoundManager._physics_process(RoundManager.DEAL_DELAY_MAX - RoundManager.DEAL_DELAY_MIN + 0.2)
	assert_eq(_deals().size(), 1, "the next deal")


func test_a_deal_is_gold_with_a_light_beam() -> void:
	var pickup := PICKUP_SCENE.instantiate() as Pickup
	pickup.item = _deal_item()
	add_child_autofree(pickup)
	var beam := pickup.find_child("Beam", true, false) as MeshInstance3D
	assert_not_null(beam, "a beam")
	if beam != null:
		assert_eq(beam.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		assert_eq((beam.material_override as StandardMaterial3D).shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED, "a mesh, not a light")
	assert_eq(pickup.find_children("*", "Light3D", true, false).size(), 0, "no real light (web)")
	RoundManager._unregister_pickup(pickup)


func test_bots_take_the_contract_argument() -> void:
	var pickup := PICKUP_SCENE.instantiate() as Pickup
	pickup.item = _deal_item()
	var bot := BotController.new()
	bot._on_deal_spawned(pickup) # a type mismatch here would be a script error
	bot.free()
	pickup.free()
	assert_true(true, "no error")


func test_hud_announces_the_deal_and_the_minimap_marks_it() -> void:
	var player := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	player.profile = load("res://systems/shared/profiles/player.tres")
	add_child_autofree(player)
	var hud := PlayerHud.new()
	hud.cart = player
	add_child_autofree(hud)
	var pickup := PICKUP_SCENE.instantiate() as Pickup
	pickup.item = _deal_item()
	pickup.position = Vector3(4.0, 0.0, -6.0)
	RoundManager.deal_spawned.emit(pickup)
	assert_has(hud.popup_texts(), "DEAL OF THE DAY! $100")
	assert_has(hud.feed_lines(), "Deal of the Day: $100 on the floor")
	var regular := PICKUP_SCENE.instantiate() as Pickup
	regular.item = ItemData.new()
	var points := HudMinimap.deal_positions([pickup, regular] as Array[Pickup])
	assert_eq(points, [Vector3(4.0, 0.0, -6.0)] as Array[Vector3], "only the deal")
	pickup.free()
	regular.free()
