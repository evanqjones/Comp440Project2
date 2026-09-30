extends GutTest
## Artifact-style screens (docs/features/player/12-artifact-screens/FEATURE.md): the paper menu,
## story and rivals cards, the blurred backdrop, the CHECKED OUT standings, the timer panel,
## Courier receipt text and the pause card.

const CART_SCENE := "res://systems/cart/cart.tscn"

var _saved_phase: GameTypes.Phase


func before_each() -> void:
	_saved_phase = RoundManager.phase
	RoundManager.phase = GameTypes.Phase.IDLE
	TitleFlow.seen = false


func after_each() -> void:
	RoundManager.phase = _saved_phase
	TitleFlow.seen = false


func _cart(id: int, profile_name: String) -> Cart:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	cart.cart_id = id
	cart.profile = load("res://systems/shared/profiles/%s.tres" % profile_name)
	cart.position = Vector3(id * 5.0, 0.0, 0.0)
	add_child_autofree(cart)
	return cart


func _flow() -> TitleFlow:
	var flow := TitleFlow.new()
	add_child_autofree(flow)
	return flow


func _texts(root: Node) -> PackedStringArray:
	var texts := PackedStringArray()
	for node: Node in root.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	return texts


func _button(root: Node, text: String) -> Button:
	for node: Node in root.find_children("*", "Button", true, false):
		if (node as Button).text == text:
			return node as Button
	return null


func test_menu_card_matches_the_artifact() -> void:
	var flow := _flow()
	var card := flow.card()
	assert_not_null(card, "a paper card")
	var texts := _texts(card)
	assert_has(texts, "Checkout Chaos", "title")
	var title := card.find_children("*", "Label", true, false).filter(func(n: Node) -> bool: return (n as Label).text == "Checkout Chaos")[0] as Label
	assert_eq(title.get_theme_font("font"), PlayerFonts.DISPLAY, "Bungee title")
	assert_eq(title.get_theme_color("font_color"), CardUi.TOMATO, "in tomato")
	for part: String in ["The player", "The cart", "The rivals"]:
		assert_has(texts, part)
	var names := ["Produce", "Bakery", "Dairy", "Snacks", "Frozen", "Electronics"]
	for i: int in names.size():
		assert_has(texts, names[i], "tag " + names[i])
		assert_has(texts, "$%d" % RoundManager.CATEGORY_VALUES[i], "price for " + names[i])
	assert_has(texts, "Enter", "Enter key cap")
	var rich := card.find_children("*", "RichTextLabel", true, false)
	assert_eq(rich.size(), 1, "the dark rule box")
	if rich.size() == 1:
		assert_string_contains((rich[0] as RichTextLabel).get_parsed_text(), "Inheritance rule:")
	assert_not_null(_button(card, "LET'S SHOP"), "the tomato button")


func test_buttons_step_through_story_and_rivals_then_open_the_doors() -> void:
	var flow := _flow()
	watch_signals(flow)
	_button(flow.card(), "LET'S SHOP").pressed.emit()
	assert_eq(flow.step, TitleFlow.Step.STORY)
	var story := flow.card()
	assert_has(_texts(story), "Grandma's Card")
	assert_has(_texts(story), "Grandma", "Grandma's Shopper ID card")
	assert_has(_texts(story), "PLATINUM", "her tier badge")
	_button(story, "MEET YOUR RIVALS").pressed.emit()
	assert_eq(flow.step, TitleFlow.Step.RIVALS)
	var rivals := flow.card()
	var texts := _texts(rivals)
	for rival: String in ["Coupon Carl", "Aunt Bev", "Rolling Rita"]:
		assert_has(texts, rival)
	assert_eq(flow.rival_names(), PackedStringArray(["Coupon Carl", "Aunt Bev", "Rolling Rita"]))
	_button(rivals, "OPEN THE DOORS").pressed.emit()
	assert_signal_emitted(flow, "finished")


func test_blurred_backdrop_behind_the_cards() -> void:
	var flow := _flow()
	var backdrop := flow.find_child("Backdrop", true, false) as CardBackdrop
	assert_not_null(backdrop, "a blurred backdrop behind the cards")
	if backdrop != null:
		await wait_process_frames(3)
		assert_true(backdrop.visible, "shown after its snapshot frame")


func test_card_pops_in() -> void:
	var flow := _flow()
	var card := flow.card()
	assert_lt(card.modulate.a, 1.0, "starts faded")
	await wait_seconds(CardUi.POP_SECONDS + 0.15)
	assert_almost_eq(card.modulate.a, 1.0, 0.001, "fully shown")
	assert_almost_eq(card.scale, Vector2.ONE, Vector2.ONE * 0.001, "full size")


func test_checked_out_standings() -> void:
	var player := _cart(0, "player")
	var carl := _cart(1, "carl")
	var bev := _cart(2, "bev")
	var hud := PlayerHud.new()
	hud.cart = player
	add_child_autofree(hud)
	RoundManager.phase = GameTypes.Phase.RUSH
	var item := ItemData.new()
	item.item_id = 9700
	item.value = 20
	carl.try_add_item(item)
	var carts: Array[Cart] = [player, carl, bev]
	hud.show_standings(carts)
	assert_eq(hud.standings_texts(), PackedStringArray(["You $0", "Coupon Carl $0 +$20", "Aunt Bev $0"]), "+$cart only while carrying")
	var list := hud.layout.get_node("%ScoreList") as Container
	assert_has(_texts(list), "CHECKED OUT", "eyebrow")
	var you := list.find_children("*", "Label", true, false).filter(func(n: Node) -> bool: return (n as Label).text == "You")[0] as Label
	assert_eq(you.get_theme_font("font"), PlayerFonts.rubik(700), "you in bold")


func test_timer_sits_on_a_dark_panel() -> void:
	var hud := PlayerHud.new()
	hud.cart = _cart(0, "player")
	add_child_autofree(hud)
	RoundManager.phase = GameTypes.Phase.RUSH
	await wait_process_frames(3)
	var panel := hud.timer_panel()
	assert_not_null(panel)
	var timer := hud.layout.get_node("%TimerLabel") as Label
	var width := timer.get_theme_font("font").get_string_size(timer.text, HORIZONTAL_ALIGNMENT_LEFT, -1, timer.get_theme_font_size("font_size")).x
	var text_rect := Rect2(timer.global_position, Vector2(width, timer.size.y))
	assert_true(panel.get_global_rect().encloses(text_rect), "panel wraps the timer text")
	assert_lt(panel.size.x, timer.size.x + 24.0, "and hugs the text, not the wider layout box")
	assert_string_contains((hud.layout.get_node("%RoundLabel") as Label).text, "GRAND OPENING")


func test_receipt_text_is_courier() -> void:
	var receipt := RoundReceipt.new()
	add_child_autofree(receipt)
	var lines := receipt.layout.get_node("%ReceiptLines") as Label
	assert_eq(lines.get_theme_font("font"), PlayerFonts.COURIER)
	var title := receipt.layout.get_node("%RoundTitle") as Label
	assert_eq(title.get_theme_font("font"), PlayerFonts.COURIER_BOLD)


func test_pause_menu_is_a_paper_card_with_the_same_buttons() -> void:
	var menu := PauseMenu.new()
	menu.restart_reloads_scene = false
	add_child_autofree(menu)
	var paused := menu.find_children("*", "Label", true, false).filter(func(n: Node) -> bool: return (n as Label).text == "PAUSED")[0] as Label
	assert_eq(paused.get_theme_color("font_color"), CardUi.TOMATO)
	for name: String in ["Resume", "Restart", "Quit"]:
		assert_not_null(menu.find_child(name, true, false), name + " button kept")
	var resume := menu.find_child("Resume", true, false) as Button
	assert_eq((resume.get_theme_stylebox("normal") as StyleBoxFlat).bg_color, CardUi.TOMATO, "Resume is the tomato button")
