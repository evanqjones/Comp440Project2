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
