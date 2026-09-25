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
