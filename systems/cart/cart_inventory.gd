class_name CartInventory
extends RefCounted
## The items one cart carries, in the order they were picked up
## (docs/features/cart/02-inventory/01-spec.md §3). Pure data with no nodes, so the rules are
## unit-testable. Only Cart writes to it (CONTRACTS.md §8, invariant 5).

var capacity: int

var _items: Array[ItemData] = []


func _init(cap: int = 24) -> void:
	capacity = cap


## Adds the item unless it's null, the cart is full, or this exact item is already here.
func try_add(item: ItemData) -> bool:
	if item == null or is_full() or has(item):
		return false
	_items.append(item)
	return true


## Empties the cart and returns everything, oldest first.
func take_all() -> Array[ItemData]:
	var taken: Array[ItemData] = _items.duplicate()
	_items.clear()
	return taken


## A copy, oldest first.
func items() -> Array[ItemData]:
	return _items.duplicate()


func count() -> int:
	return _items.size()


## Total dollars.
func value() -> int:
	var total := 0
	for item: ItemData in _items:
		total += item.value
	return total


func is_full() -> bool:
	return _items.size() >= capacity


## True if this exact item (same instance) is in the cart.
func has(item: ItemData) -> bool:
	return _items.has(item)
