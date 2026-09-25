extends GutTest
## Cart inventory (docs/features/cart/02-inventory/01-spec.md §3, §7).

var _next_id := 1


func _item(category: GameTypes.Category, value: int) -> ItemData:
	var item := ItemData.new()
	item.item_id = _next_id
	_next_id += 1
	item.category = category
	item.value = value
	item.is_deal = category == GameTypes.Category.DEAL
	return item


func test_inventory_holds_24_then_refuses() -> void:
	var inventory := CartInventory.new(24)
	for i: int in 24:
		assert_true(inventory.try_add(_item(GameTypes.Category.PRODUCE, 5)), "item %d fits" % (i + 1))
	assert_true(inventory.is_full())
	assert_false(inventory.try_add(_item(GameTypes.Category.PRODUCE, 5)), "the 25th is refused")
	assert_eq(inventory.count(), 24)


func test_inventory_refuses_null_and_duplicates() -> void:
	var inventory := CartInventory.new(24)
	var item := _item(GameTypes.Category.DAIRY, 10)
	assert_false(inventory.try_add(null), "null refused")
	assert_true(inventory.try_add(item))
	assert_false(inventory.try_add(item), "the same item twice is refused")
	assert_eq(inventory.count(), 1)


func test_inventory_take_all_is_oldest_first_and_empties() -> void:
	var inventory := CartInventory.new(24)
	var first := _item(GameTypes.Category.PRODUCE, 5)
	var second := _item(GameTypes.Category.SNACKS, 15)
	var third := _item(GameTypes.Category.DEAL, 100)
	for item: ItemData in [first, second, third]:
		inventory.try_add(item)
	var taken := inventory.take_all()
	assert_eq(taken.size(), 3)
	assert_same(taken[0], first, "oldest first")
	assert_same(taken[2], third)
	assert_eq(inventory.count(), 0, "emptied")
	assert_eq(inventory.take_all().size(), 0, "taking from an empty cart is fine")


func test_inventory_value_and_count() -> void:
	var inventory := CartInventory.new(24)
	inventory.try_add(_item(GameTypes.Category.PRODUCE, 5))
	inventory.try_add(_item(GameTypes.Category.ELECTRONICS, 40))
	inventory.try_add(_item(GameTypes.Category.DEAL, 100))
	assert_eq(inventory.count(), 3)
	assert_eq(inventory.value(), 145)
	var copy := inventory.items()
	copy.clear()
	assert_eq(inventory.count(), 3, "items() is a copy")


func test_tuning_item_cap_is_24() -> void:
	assert_eq((load("res://systems/cart/cart_tuning.tres") as CartTuning).item_cap, 24)


func test_stack_shows_one_cube_per_item_in_palette_colors() -> void:
	var stack := CartItemStack.new()
	add_child_autofree(stack)
	var items: Array[ItemData] = [_item(GameTypes.Category.PRODUCE, 5), _item(GameTypes.Category.DEAL, 100)]
	stack.show_items(items)
	assert_eq(stack.visible_count(), 2)
	assert_eq(CartItemStack.color_for(items[0]), Color("#4CAF50"), "produce is green")
	assert_eq(CartItemStack.color_for(items[1]), Color("#E6B422"), "a Deal is gold")
	var none: Array[ItemData] = []
	stack.show_items(none)
	assert_eq(stack.visible_count(), 0)


const CART_SCENE := "res://systems/cart/cart.tscn"


func _make_cart() -> Cart:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	return cart


func _with_phase(phase: GameTypes.Phase) -> GameTypes.Phase:
	var saved: GameTypes.Phase = RoundManager.phase
	RoundManager.phase = phase
	return saved


func test_cart_refuses_when_round_not_active() -> void:
	var saved := _with_phase(GameTypes.Phase.COUNTDOWN)
	var cart := _make_cart()
	watch_signals(cart)
	assert_false(cart.try_add_item(_item(GameTypes.Category.PRODUCE, 5)))
	assert_eq(cart.get_state().items.size(), 0)
	assert_signal_not_emitted(cart, "item_collected")
	RoundManager.phase = saved


func test_cart_collects_while_stunned() -> void:
	var saved := _with_phase(GameTypes.Phase.RUSH)
	var cart := _make_cart()
	cart._is_stunned = true
	assert_true(cart.try_add_item(_item(GameTypes.Category.PRODUCE, 5)), "GAME_SPEC §5.5: stun blocks driving, not collecting")
	RoundManager.phase = saved


func test_item_collected_emitted_with_cart_and_item() -> void:
	var saved := _with_phase(GameTypes.Phase.RUSH)
	var cart := _make_cart()
	watch_signals(cart)
	var item := _item(GameTypes.Category.BAKERY, 10)
	assert_true(cart.try_add_item(item))
	assert_signal_emitted_with_parameters(cart, "item_collected", [cart, item])
	RoundManager.phase = saved


func test_cart_full_emitted_once_at_24_and_again_after_refill() -> void:
	var saved := _with_phase(GameTypes.Phase.FINAL_CALL)
	var cart := _make_cart()
	watch_signals(cart)
	for _i: int in 26:
		cart.try_add_item(_item(GameTypes.Category.PRODUCE, 5))
	assert_signal_emit_count(cart, "cart_full", 1, "once on reaching 24, not on refused extras")
	cart.take_all_items()
	for _i: int in 24:
		cart.try_add_item(_item(GameTypes.Category.PRODUCE, 5))
	assert_signal_emit_count(cart, "cart_full", 2, "again after emptying and refilling")
	RoundManager.phase = saved


func test_take_all_items_returns_same_instances_and_empties() -> void:
	var saved := _with_phase(GameTypes.Phase.RUSH)
	var cart := _make_cart()
	var a := _item(GameTypes.Category.FROZEN, 20)
	var b := _item(GameTypes.Category.DEAL, 100)
	cart.try_add_item(a)
	cart.try_add_item(b)
	RoundManager.phase = GameTypes.Phase.CLOSED
	var taken := cart.take_all_items()
	assert_eq(taken.size(), 2, "works after close (Store's deferred checkout)")
	assert_same(taken[0], a, "same instances, oldest first")
	assert_same(taken[1], b)
	assert_eq(cart.get_state().items.size(), 0)
	RoundManager.phase = saved


func test_state_items_copy_and_value() -> void:
	var saved := _with_phase(GameTypes.Phase.RUSH)
	var cart := _make_cart()
	cart.try_add_item(_item(GameTypes.Category.SNACKS, 15))
	cart.try_add_item(_item(GameTypes.Category.ELECTRONICS, 40))
	var state := cart.get_state()
	assert_eq(state.value, 55)
	state.items.clear()
	assert_eq(cart.get_state().items.size(), 2, "snapshot is a copy")
	RoundManager.phase = saved


func test_reset_for_round_empties() -> void:
	var saved := _with_phase(GameTypes.Phase.RUSH)
	var cart := _make_cart()
	cart.try_add_item(_item(GameTypes.Category.PRODUCE, 5))
	cart.reset_for_round(Transform3D.IDENTITY)
	assert_eq(cart.get_state().items.size(), 0)
	RoundManager.phase = saved


func test_cart_shows_one_cube_per_item() -> void:
	var saved := _with_phase(GameTypes.Phase.RUSH)
	var cart := _make_cart()
	var stack := cart.get_node("ItemStackDisplay") as CartItemStack
	for _i: int in 5:
		cart.try_add_item(_item(GameTypes.Category.DAIRY, 10))
	assert_eq(stack.visible_count(), 5)
	cart.take_all_items()
	assert_eq(stack.visible_count(), 0)
	RoundManager.phase = saved


func test_full_cart_tops_out_near_10_7() -> void:
	var saved := _with_phase(GameTypes.Phase.RUSH)
	var ground := StaticBody3D.new()
	ground.position = Vector3(0.0, -0.5, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400.0, 1.0, 400.0)
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
	var cart := _make_cart()
	for _i: int in 24:
		cart.try_add_item(_item(GameTypes.Category.PRODUCE, 5))
	var cmd := DriveCommand.new()
	cmd.throttle = 1.0
	for _i: int in 150:
		cart.apply_command(cmd)
		await wait_physics_frames(1)
	assert_almost_eq(cart.get_state().speed, 10.68, 0.5, "full cart is ~29% slower than 15 m/s")
	RoundManager.phase = saved
