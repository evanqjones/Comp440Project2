extends GutTest
## Sound effects (docs/features/player/14-sound-effects/FEATURE.md): synthesized stand-ins that Evan's
## files replace, played for the player's own events and the round's phases.

const CART_SCENE := "res://systems/cart/cart.tscn"

var _saved_phase: GameTypes.Phase


func before_each() -> void:
	_saved_phase = RoundManager.phase
	RoundManager.phase = GameTypes.Phase.RUSH


func after_each() -> void:
	RoundManager.phase = _saved_phase


func _cart(id: int, profile_name: String) -> Cart:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	cart.cart_id = id
	cart.profile = load("res://systems/shared/profiles/%s.tres" % profile_name)
	cart.position = Vector3(id * 5.0, 0.0, 0.0)
	add_child_autofree(cart)
	return cart


func _audio(player: Cart, watch: Array[Cart] = []) -> PlayerAudio:
	var audio := PlayerAudio.new()
	audio.cart = player
	add_child_autofree(audio)
	for other: Cart in watch:
		audio.watch(other)
	return audio


func _item(id: int) -> ItemData:
	var item := ItemData.new()
	item.item_id = id
	item.value = 10
	return item


func test_every_sound_renders_audible_audio() -> void:
	for sound: String in PlayerAudio.SOUNDS:
		var stream := PlayerAudio.stream_for(sound)
		assert_not_null(stream, sound)
		if stream is AudioStreamWAV:
			var data := (stream as AudioStreamWAV).data
			var loudest := 0
			for i: int in range(0, data.size(), 2):
				loudest = maxi(loudest, absi(data.decode_s16(i)))
			assert_gt(loudest, 300, "%s is audible" % sound)


func test_wheel_sound_loops() -> void:
	var wheel := PlayerAudio.stream_for("wheel") as AudioStreamWAV
	assert_not_null(wheel)
	if wheel != null:
		assert_eq(wheel.loop_mode, AudioStreamWAV.LOOP_FORWARD)
		assert_gt(wheel.loop_end, 0)


func test_evans_file_wins_when_it_exists() -> void:
	var tones: Array = PlayerAudio.SOUNDS["pickup"]["tones"]
	assert_true(PlayerAudio.resolve("res://assets/audio/music/store_muzak.ogg", tones) is AudioStreamOggVorbis, "an existing file is used")
	assert_true(PlayerAudio.resolve("res://assets/audio/sfx/does_not_exist.wav", tones) is AudioStreamWAV, "else the synthesized stand-in")


func test_player_only_pickup_checkout_and_full_sounds() -> void:
	var player := _cart(0, "player")
	var carl := _cart(1, "carl")
	var audio := _audio(player)
	player.try_add_item(_item(9800))
	assert_eq(audio.last_played(), "pickup")
	carl.try_add_item(_item(9801))
	assert_eq(audio.played.size(), 1, "a bot's pickup is silent")
	RoundManager.checked_out.emit(carl, 50)
	assert_eq(audio.played.size(), 1, "a bot's checkout is silent")
	RoundManager.checked_out.emit(player, 50)
	assert_eq(audio.last_played(), "checkout")
	player.cart_full.emit(player)
	assert_eq(audio.last_played(), "cart_full")


func test_steal_sounds_depend_on_which_side_you_are() -> void:
	var player := _cart(0, "player")
	var carl := _cart(1, "carl")
	var bev := _cart(2, "bev")
	var audio := _audio(player, [carl, bev] as Array[Cart])
	var items: Array[ItemData] = [_item(9810)]
	var spilled: Array[ItemData] = []
	carl.cart_robbed.emit(player, carl, items, spilled)
	assert_eq(audio.played.slice(-2), PackedStringArray(["crash", "steal"]), "you inherited")
	player.cart_robbed.emit(carl, player, items, spilled)
	assert_eq(audio.played.slice(-2), PackedStringArray(["crash", "robbed"]), "you were robbed")
	var count := audio.played.size()
	bev.cart_robbed.emit(carl, bev, items, spilled)
	assert_eq(audio.played.size(), count, "bot-on-bot is silent")


func test_countdown_beeps_and_round_chimes() -> void:
	var audio := _audio(_cart(0, "player"))
	RoundManager.phase = GameTypes.Phase.COUNTDOWN
	RoundManager.phase_changed.emit(GameTypes.Phase.COUNTDOWN)
	assert_eq(audio.last_played(), "beep", "3")
	simulate(audio, 1, 1.0)
	simulate(audio, 1, 1.0)
	assert_eq(audio.played.count("beep"), 3, "3, 2, 1")
	simulate(audio, 1, 1.0)
	assert_eq(audio.played.count("beep"), 3, "no fourth beep")
	RoundManager.phase = GameTypes.Phase.RUSH
	RoundManager.phase_changed.emit(GameTypes.Phase.RUSH)
	assert_eq(audio.played.slice(-2), PackedStringArray(["go", "doors_open"]))
	RoundManager.phase_changed.emit(GameTypes.Phase.FINAL_CALL)
	assert_eq(audio.last_played(), "final_call")
	RoundManager.phase_changed.emit(GameTypes.Phase.CLOSED)
	assert_eq(audio.last_played(), "store_closed")


func test_wheel_follows_speed_and_rests_when_stopped() -> void:
	assert_lt(PlayerAudio.wheel_pitch(2.0), PlayerAudio.wheel_pitch(12.0), "faster = higher squeak")
	assert_lt(PlayerAudio.wheel_volume_db(2.0), PlayerAudio.wheel_volume_db(12.0), "faster = louder")
	assert_false(PlayerAudio.wheel_audible(0.2, true), "stopped: quiet")
	assert_false(PlayerAudio.wheel_audible(8.0, false), "outside gameplay: quiet")
	assert_true(PlayerAudio.wheel_audible(8.0, true))
