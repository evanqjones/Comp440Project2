extends GutTest
## Ram-steal (docs/features/cart/04-ram-steal/01-spec.md §3, §7; GAME_SPEC.md §5, §11.2).

var t: CartTuning
var _next_id := 1


func before_each() -> void:
	t = CartTuning.new()


func _item(value: int) -> ItemData:
	var item := ItemData.new()
	item.item_id = _next_id
	_next_id += 1
	item.value = value
	return item


func _state(speed: float, item_count: int, stunned := false, immune := false) -> CartState:
	var s := CartState.new()
	s.speed = speed
	for _i: int in item_count:
		s.items.append(_item(10))
	s.is_stunned = stunned
	s.is_immune = immune
	return s


func test_outcome_steal_when_fast_enough_and_margin() -> void:
	assert_eq(CartSteal.outcome(t, _state(14.0, 20), _state(6.0, 8)), CartSteal.Outcome.A_WINS)
	assert_eq(CartSteal.outcome(t, _state(6.0, 8), _state(14.0, 20)), CartSteal.Outcome.B_WINS)


func test_outcome_thresholds_inclusive() -> void:
	assert_eq(CartSteal.outcome(t, _state(5.0, 0), _state(3.5, 3)), CartSteal.Outcome.A_WINS, "exactly 5 and exactly 1.5 faster")
	assert_eq(CartSteal.outcome(t, _state(4.99, 0), _state(0.0, 3)), CartSteal.Outcome.BOUNCE, "under 5 m/s")
	assert_eq(CartSteal.outcome(t, _state(6.0, 0), _state(4.6, 3)), CartSteal.Outcome.BOUNCE, "only 1.4 faster")


func test_outcome_bounce_on_tie_stunned_immune_or_empty() -> void:
	assert_eq(CartSteal.outcome(t, _state(10.0, 3), _state(10.0, 3)), CartSteal.Outcome.BOUNCE, "tie")
	assert_eq(CartSteal.outcome(t, _state(14.0, 0, true), _state(0.0, 3)), CartSteal.Outcome.BOUNCE, "stunned can't win")
	assert_eq(CartSteal.outcome(t, _state(14.0, 0), _state(0.0, 3, false, true)), CartSteal.Outcome.BOUNCE, "immune can't be robbed")
	assert_eq(CartSteal.outcome(t, _state(14.0, 0), _state(0.0, 0)), CartSteal.Outcome.BOUNCE, "empty can't be robbed")
	assert_eq(CartSteal.outcome(t, _state(14.0, 0, false, true), _state(0.0, 3)), CartSteal.Outcome.A_WINS, "immune carts can still rob")


func test_split_oldest_first() -> void:
	var loot: Array[ItemData] = []
	for v: int in [10, 10, 15, 15, 15, 15, 15, 15]:
		loot.append(_item(v))
	var parts := CartSteal.split(loot, 4)
	var transferred: Array[ItemData] = parts[0]
	var spilled: Array[ItemData] = parts[1]
	assert_eq(transferred.size(), 4)
	assert_same(transferred[0], loot[0], "oldest transfers first")
	assert_eq(spilled.size(), 4)
	assert_same(spilled[0], loot[4])
	assert_eq((CartSteal.split(loot, 0)[1] as Array).size(), 8, "winner full: all spill")
	assert_eq((CartSteal.split(loot, 24)[0] as Array).size(), 8, "plenty of room: all transfer")
	assert_eq((CartSteal.split(loot, -3)[1] as Array).size(), 8, "negative room is treated as 0")


const CART_SCENE := "res://systems/cart/cart.tscn"
var _saved_phase: GameTypes.Phase


func before_all() -> void:
	_saved_phase = RoundManager.phase


func after_each() -> void:
	RoundManager.phase = _saved_phase


## Positions the cart BEFORE adding it: two carts added at the same spot (even for an instant)
## get shoved apart by the physics engine.
func _cart_at(position: Vector3) -> Cart:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	cart.position = position
	add_child_autofree(cart)
	return cart


func _fill(cart: Cart, values: Array) -> Array[ItemData]:
	var added: Array[ItemData] = []
	for v: int in values:
		var item := _item(v)
		assert_true(cart.try_add_item(item), "filled item $%d" % v)
		added.append(item)
	return added


func _sum(items: Array) -> int:
	var total := 0
	for item: ItemData in items:
		total += item.value
	return total


func _ids(items: Array) -> Array:
	var ids := []
	for item: ItemData in items:
		ids.append(item.item_id)
	ids.sort()
	return ids


func test_gdd_20_into_8_conserves_items_and_value() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var rita := _cart_at(Vector3.ZERO)
	var you := _cart_at(Vector3(0.0, 0.0, -1.5))
	var rita_items := _fill(rita, [13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13])
	var you_items := _fill(you, [10, 10, 15, 15, 15, 15, 15, 15])
	rita._speed_before_move = 14.0
	you._speed_before_move = 6.0
	rita.velocity = Vector3(0.0, 0.0, -14.0)
	watch_signals(you)
	watch_signals(rita)
	rita._resolve_contact(you)
	assert_eq(rita.get_state().items.size(), 24, "winner full at 24")
	assert_eq(you.get_state().items.size(), 0, "loser empty")
	assert_signal_emit_count(you, "cart_robbed", 1, "loser emits once")
	assert_signal_not_emitted(rita, "cart_robbed")
	var params: Array = get_signal_parameters(you, "cart_robbed")
	assert_same(params[0], rita, "winner")
	assert_same(params[1], you, "loser")
	var transferred: Array = params[2]
	var spilled: Array = params[3]
	assert_eq(transferred.size(), 4)
	assert_eq(spilled.size(), 4)
	assert_eq(_sum(transferred), 50, "oldest four ($50) transfer")
	assert_eq(_sum(spilled), 60, "newest four ($60) spill")
	var before := _ids(rita_items + you_items)
	var after := _ids(rita.get_state().items + spilled)
	assert_eq(after, before, "all 28 item IDs accounted for")
	assert_eq(rita.get_state().value + _sum(spilled), 370, "$370 conserved")
	assert_signal_emitted(rita, "cart_full", "steal filled the winner")


func test_winner_keeps_75_percent_and_loser_knocked_away() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var rita := _cart_at(Vector3.ZERO)
	var you := _cart_at(Vector3(0.0, 0.0, -1.5))
	_fill(you, [10])
	rita._speed_before_move = 14.0
	rita.velocity = Vector3(0.0, 0.0, -14.0)
	rita._resolve_contact(you)
	assert_almost_eq(rita.velocity.length(), 10.5, 0.01, "GDD: 14 → 10.5")
	assert_almost_eq(you.velocity.x, 0.0, 0.01)
	assert_almost_eq(you.velocity.z, -4.0, 0.01, "shoved 4 m/s away from the winner")


func test_repeat_contact_during_immunity_does_nothing() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var rita := _cart_at(Vector3.ZERO)
	var you := _cart_at(Vector3(0.0, 0.0, -1.5))
	_fill(you, [10, 10])
	rita._speed_before_move = 14.0
	watch_signals(you)
	rita._resolve_contact(you)
	_fill(you, [15, 15])
	await wait_physics_frames(15)
	rita._speed_before_move = 14.0
	you._speed_before_move = 0.0
	rita._resolve_contact(you)
	assert_signal_emit_count(you, "cart_robbed", 1, "no second steal while immune")
	assert_eq(you.get_state().items.size(), 2, "the loser keeps what it picked up after")


func test_same_frame_double_detection_resolves_once() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var rita := _cart_at(Vector3.ZERO)
	var you := _cart_at(Vector3(0.0, 0.0, -1.5))
	_fill(you, [10, 10])
	rita._speed_before_move = 14.0
	watch_signals(you)
	rita._resolve_contact(you)
	you._resolve_contact(rita)
	assert_signal_emit_count(you, "cart_robbed", 1, "pair lock: both carts detecting the same crash resolve it once")


func test_stun_and_immunity_timers() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var rita := _cart_at(Vector3.ZERO)
	var you := _cart_at(Vector3(0.0, 0.0, -1.5))
	_fill(you, [10])
	rita._speed_before_move = 14.0
	rita._resolve_contact(you)
	assert_true(you.get_state().is_stunned)
	assert_true(you.get_state().is_immune)
	await wait_seconds(0.9)
	assert_false(you.get_state().is_stunned, "stun over after 0.7 s")
	assert_true(you.get_state().is_immune, "still immune until 1.6 s")
	await wait_seconds(0.9)
	assert_false(you.get_state().is_immune, "immunity over after 1.6 s")


func test_bounce_pushes_apart_without_items_or_signal() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var a := _cart_at(Vector3.ZERO)
	var b := _cart_at(Vector3(0.0, 0.0, -1.5))
	_fill(b, [10, 10])
	a._speed_before_move = 6.0
	b._speed_before_move = 5.0
	watch_signals(b)
	a._resolve_contact(b)
	assert_eq(b.get_state().items.size(), 2, "nothing changes hands")
	assert_signal_not_emitted(b, "cart_robbed")
	assert_almost_eq(a.velocity.z, 2.0, 0.01, "a pushed back (+Z, away from b)")
	assert_almost_eq(b.velocity.z, -2.0, 0.01, "b pushed forward (-Z, away from a)")


func test_no_steal_when_round_not_active() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var rita := _cart_at(Vector3.ZERO)
	var you := _cart_at(Vector3(0.0, 0.0, -1.5))
	_fill(you, [10])
	RoundManager.phase = GameTypes.Phase.CLOSED
	rita._speed_before_move = 14.0
	watch_signals(you)
	rita._resolve_contact(you)
	assert_signal_not_emitted(you, "cart_robbed")
	assert_eq(you.get_state().items.size(), 1)


func test_winner_full_everything_spills() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var rita := _cart_at(Vector3.ZERO)
	var you := _cart_at(Vector3(0.0, 0.0, -1.5))
	var full: Array = []
	full.resize(24)
	full.fill(5)
	_fill(rita, full)
	_fill(you, [10, 10, 10])
	rita._speed_before_move = 14.0
	watch_signals(you)
	rita._resolve_contact(you)
	var params: Array = get_signal_parameters(you, "cart_robbed")
	assert_eq((params[2] as Array).size(), 0, "nothing fits")
	assert_eq((params[3] as Array).size(), 3, "all three spill")
	assert_eq(you.get_state().items.size(), 0)


func test_real_ram_steals_once() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var ground := StaticBody3D.new()
	ground.position = Vector3(0.0, -0.5, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
	var driver := _cart_at(Vector3.ZERO)
	var parked := _cart_at(Vector3(0.0, 0.0, -10.0))
	_fill(parked, [10, 10, 10, 10, 10, 10, 10, 10])
	watch_signals(parked)
	var cmd := DriveCommand.new()
	cmd.throttle = 1.0
	for _i: int in 120:
		driver.apply_command(cmd)
		await wait_physics_frames(1)
	assert_signal_emit_count(parked, "cart_robbed", 1, "one real ram, one steal")
	assert_eq(driver.get_state().items.size(), 8, "driver inherited the haul")
