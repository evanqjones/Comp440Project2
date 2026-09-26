extends GutTest
## Title, story and rival intro screens (docs/features/player/09-title/FEATURE.md).

const NAMES := ["Name", "Photo", "MemberNumber", "MemberSince", "TierBadge", "Barcode", "LifetimeSavings", "StampRow"]
const DEMO_SCENE := "res://systems/player/demo/demo_round.tscn"


func before_each() -> void:
	TitleFlow.seen = false


func after_each() -> void:
	TitleFlow.seen = false


func _key(pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_ENTER
	event.physical_keycode = KEY_ENTER
	event.pressed = pressed
	return event


func _label(card: Control, part: String) -> String:
	return (card.get_node("%" + part) as Label).text


func test_placeholder_card_has_every_contract_name() -> void:
	var layout := (load(ShopperIdCard.PLACEHOLDER_LAYOUT) as PackedScene).instantiate() as Control
	add_child_autofree(layout)
	for part: String in NAMES:
		assert_not_null(layout.get_node_or_null("%" + part), "placeholder has %" + part)


func test_card_is_filled_from_the_profile() -> void:
	var carl: ShopperProfile = load("res://systems/shared/profiles/carl.tres")
	var card := ShopperIdCard.make(carl)
	add_child_autofree(card)
	assert_eq(_label(card, "Name"), "Coupon Carl")
	assert_eq(_label(card, "TierBadge"), "GOLD")
	assert_string_contains(_label(card, "MemberNumber"), "0417-2231")
	assert_string_contains(_label(card, "MemberSince"), "1986")
	assert_ne(_label(card, "Barcode"), "", "a barcode from the member number")


func test_grandmas_card_uses_the_name_override_and_stamps() -> void:
	var grandma: ShopperProfile = load("res://systems/shared/profiles/player.tres")
	var card := ShopperIdCard.make(grandma, "Grandma", 1)
	add_child_autofree(card)
	assert_eq(_label(card, "Name"), "Grandma")
	assert_eq(_label(card, "TierBadge"), "PLATINUM")
	assert_eq(_label(card, "StampRow").count("★"), 1, "one stamp earned out of three")


func test_steps_run_title_story_rivals_then_finish() -> void:
	var flow := TitleFlow.new()
	add_child_autofree(flow)
	watch_signals(flow)
	assert_eq(flow.step, TitleFlow.Step.TITLE)
	flow.advance()
	assert_eq(flow.step, TitleFlow.Step.STORY)
	flow.advance()
	assert_eq(flow.step, TitleFlow.Step.RIVALS)
	assert_eq(flow.rival_names(), PackedStringArray(["Coupon Carl", "Aunt Bev", "Rolling Rita"]), "meet your rivals")
	flow.advance()
	assert_signal_emitted(flow, "finished")
	assert_true(TitleFlow.seen, "restarts skip the intro")


func test_any_key_press_advances_but_release_does_not() -> void:
	var flow := TitleFlow.new()
	add_child_autofree(flow)
	flow._unhandled_input(_key(false))
	assert_eq(flow.step, TitleFlow.Step.TITLE, "a key release doesn't advance")
	flow._unhandled_input(_key(true))
	assert_eq(flow.step, TitleFlow.Step.STORY, "a key press does")


func test_seen_skips_straight_to_the_round() -> void:
	TitleFlow.seen = true
	var flow := TitleFlow.new()
	watch_signals(flow)
	add_child_autofree(flow)
	assert_signal_emitted(flow, "finished", "a restart doesn't replay the intro")


func test_demo_waits_for_start_match() -> void:
	var demo := (load(DEMO_SCENE) as PackedScene).instantiate()
	demo.set("wait_for_start", true)
	add_child_autofree(demo)
	assert_eq(RoundManager.phase, GameTypes.Phase.IDLE, "waits behind the title")
	demo._physics_process(5.0)
	assert_eq(RoundManager.phase, GameTypes.Phase.IDLE, "the clock doesn't run yet")
	RoundManager.start_match()
	assert_eq(RoundManager.phase, GameTypes.Phase.COUNTDOWN, "start_match begins the countdown")
	demo._physics_process(DemoRoundClock.COUNTDOWN + 0.1)
	assert_eq(RoundManager.phase, GameTypes.Phase.RUSH)


func test_title_then_round_in_main() -> void:
	var main := (load("res://systems/core/main.tscn") as PackedScene).instantiate()
	add_child_autofree(main)
	var demo := main.get_node("DemoRound")
	assert_true(demo.get("wait_for_start"), "main.tscn holds the round for the title")
	var flows := main.get_children().filter(func(n: Node) -> bool: return n is TitleFlow)
	assert_eq(flows.size(), 1, "main.tscn has a TitleFlow")
	if flows.is_empty():
		return
	var flow := flows[0] as TitleFlow
	assert_eq(RoundManager.phase, GameTypes.Phase.IDLE)
	flow.advance()
	flow.advance()
	flow.advance()
	assert_eq(RoundManager.phase, GameTypes.Phase.COUNTDOWN, "after the rivals screen, the countdown starts")
