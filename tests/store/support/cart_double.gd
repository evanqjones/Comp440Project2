class_name StoreCartDouble
extends Cart
## Controlled collection seam for Store tests. Does not change Cart production behavior.

var accept_items: bool = true
var collected: Array[ItemData] = []


func try_add_item(item: ItemData) -> bool:
	if not accept_items or not RoundManager.is_gameplay_active():
		return false
	if collected.has(item):
		return false
	collected.append(item)
	return true
