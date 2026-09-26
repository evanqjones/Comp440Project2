class_name CartNameTag
extends Label3D
## Floating name over a bot's cart, in the shopper's color (docs/features/cart/07-name-tags/FEATURE.md).
## Hidden on the human's cart (cart_id 0) and on carts without a profile. Visual only.

var _cart: Cart
var _shown_for: ShopperProfile
var _shown_id: int = -1


func _ready() -> void:
	_cart = _find_cart()
	_refresh()


func _process(_delta: float) -> void:
	if _cart != null and (_cart.profile != _shown_for or _cart.cart_id != _shown_id):
		_refresh()


func _refresh() -> void:
	if _cart == null:
		visible = false
		return
	_shown_for = _cart.profile
	_shown_id = _cart.cart_id
	visible = _shown_for != null and _shown_id != 0
	if _shown_for != null:
		text = _shown_for.display_name
		modulate = _shown_for.color


func _find_cart() -> Cart:
	var node := get_parent()
	while node != null and not node is Cart:
		node = node.get_parent()
	return node as Cart
