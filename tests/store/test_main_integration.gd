extends GutTest
## Startup-scene integration for Anthony's greybox Store.

const MAIN_SCENE := preload("res://systems/core/main.tscn")


func test_main_starts_with_real_store_and_player_cart() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child_autofree(main)
	await wait_process_frames(1)

	assert_null(main.get_node_or_null("DemoRound"), "the fallback demo is no longer the startup gameplay scene")
	assert_not_null(main.get_node_or_null("Store"), "the Store scene is instanced in the startup scene")
	var player := main.get_node_or_null("PlayerCart") as Cart
	assert_not_null(player, "the human cart is present")
	if player != null:
		assert_eq(player.cart_id, 0)
		assert_eq(player.profile.display_name, "You")
		assert_not_null(player.get_node_or_null("PlayerController"), "the human cart receives keyboard/gamepad input")
		assert_true(RoundManager.get_carts().has(player), "the human cart is registered with the round manager")
	assert_not_null(main.get_node_or_null("ChaseCamera"), "the human player has a chase camera")
	assert_not_null(main.get_node_or_null("PlayerHud"), "the real player HUD is connected")
	assert_eq(RoundManager.get_checkout_position(), Vector3(0.0, 1.0, 13.0))
