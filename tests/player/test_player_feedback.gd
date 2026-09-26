extends GutTest
## Camera shake and rumble on steals (docs/features/player/04-feel/FEATURE.md).

const CART_SCENE := "res://systems/cart/cart.tscn"
const CAMERA_SCENE := "res://systems/player/chase_camera.tscn"


func _cart(id: int) -> Cart:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	cart.cart_id = id
	cart.position = Vector3(id * 5.0, 0.0, 0.0)
	add_child_autofree(cart)
	return cart


func _rig(target: Node3D) -> ChaseCamera:
	var rig := (load(CAMERA_SCENE) as PackedScene).instantiate() as ChaseCamera
	rig.target = target
	add_child_autofree(rig)
	return rig


func _rob(winner: Cart, loser: Cart) -> void:
	var items: Array[ItemData] = []
	var spilled: Array[ItemData] = []
	loser.cart_robbed.emit(winner, loser, items, spilled)


func test_shake_offsets_the_camera_then_fades() -> void:
	var rig := _rig(_cart(0))
	await wait_process_frames(2)
	var camera := rig.get_node("Camera3D") as Camera3D
	var spot := rig.get_node("Arm/CameraSpot") as Marker3D
	rig.shake(0.3, 0.3)
	assert_almost_eq(rig.current_shake(), 0.3, 0.001, "full strength right away")
	await wait_process_frames(2)
	assert_gt(camera.global_position.distance_to(spot.global_position), 0.001, "camera jolted off its spot")
	await wait_seconds(0.4)
	assert_almost_eq(rig.current_shake(), 0.0, 0.001, "faded out")
	assert_almost_eq(camera.global_position.distance_to(spot.global_position), 0.0, 0.001, "back on its spot")


func test_weaker_shake_does_not_cut_a_stronger_one() -> void:
	var rig := _rig(_cart(0))
	rig.shake(0.35, 0.35)
	rig.shake(0.12, 0.15)
	assert_almost_eq(rig.current_shake(), 0.35, 0.001)


func _feedback(player: Cart, rig: ChaseCamera) -> PlayerFeedback:
	var feedback := PlayerFeedback.new()
	feedback.cart = player
	feedback.camera = rig
	add_child_autofree(feedback)
	return feedback


func test_getting_robbed_shakes_hard() -> void:
	var player := _cart(0)
	var bot := _cart(1)
	var rig := _rig(player)
	var feedback := _feedback(player, rig)
	feedback.watch(bot)
	_rob(bot, player)
	assert_almost_eq(rig.current_shake(), PlayerFeedback.ROBBED_SHAKE, 0.001, "robbed: big shake")


func test_robbing_someone_bumps_a_little() -> void:
	var player := _cart(0)
	var bot := _cart(1)
	var rig := _rig(player)
	var feedback := _feedback(player, rig)
	feedback.watch(bot)
	_rob(player, bot)
	assert_almost_eq(rig.current_shake(), PlayerFeedback.STEAL_SHAKE, 0.001, "you inherited a haul: small bump")
	assert_lt(PlayerFeedback.STEAL_SHAKE, PlayerFeedback.ROBBED_SHAKE)


func test_bot_on_bot_steal_does_nothing() -> void:
	var player := _cart(0)
	var carl := _cart(1)
	var bev := _cart(2)
	var rig := _rig(player)
	var feedback := _feedback(player, rig)
	feedback.watch(carl)
	feedback.watch(bev)
	_rob(carl, bev)
	assert_almost_eq(rig.current_shake(), 0.0, 0.001, "not your fight")


func test_watches_carts_registered_later() -> void:
	var player := _cart(0)
	var rig := _rig(player)
	_feedback(player, rig)
	var late := _cart(4)
	RoundManager.register_cart(late)
	await wait_process_frames(2)
	_rob(player, late)
	assert_almost_eq(rig.current_shake(), PlayerFeedback.STEAL_SHAKE, 0.001, "picked up from RoundManager.get_carts()")
