extends GutTest
## Floating name tags over bot carts (docs/features/cart/07-name-tags/FEATURE.md).

const CART_SCENE := "res://systems/cart/cart.tscn"


func _make_cart(id: int, profile_name: String) -> Cart:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	cart.cart_id = id
	if profile_name != "":
		cart.profile = load("res://systems/shared/profiles/%s.tres" % profile_name)
	add_child_autofree(cart)
	return cart


func _tag(cart: Cart) -> Label3D:
	return cart.get_node_or_null("Visual/NameTag") as Label3D


func test_bot_shows_its_name_in_its_color() -> void:
	var cart := _make_cart(1, "carl")
	var tag := _tag(cart)
	assert_not_null(tag, "cart.tscn has Visual/NameTag")
	if tag == null:
		return
	assert_true(tag.visible, "bots show a tag")
	assert_eq(tag.text, "Coupon Carl")
	assert_eq(tag.modulate, cart.profile.color, "in Carl's teal")
	assert_eq(tag.billboard, BaseMaterial3D.BILLBOARD_ENABLED, "always faces the camera")


func test_player_cart_has_no_tag() -> void:
	var tag := _tag(_make_cart(0, "player"))
	assert_not_null(tag)
	if tag != null:
		assert_false(tag.visible, "your own tag would block the chase view")


func test_cart_without_profile_has_no_tag() -> void:
	var tag := _tag(_make_cart(2, ""))
	assert_not_null(tag)
	if tag != null:
		assert_false(tag.visible)


func test_tag_follows_a_later_profile_change() -> void:
	var cart := _make_cart(3, "")
	cart.profile = load("res://systems/shared/profiles/rita.tres")
	await wait_process_frames(2)
	var tag := _tag(cart)
	assert_true(tag.visible)
	assert_eq(tag.text, "Rolling Rita")
