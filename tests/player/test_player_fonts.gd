extends GutTest
## Fonts (docs/features/player/12-fonts/FEATURE.md, D-032): Rubik is the game's default font;
## Bungee is for big display text; Rubik Bold for the name tags over carts.

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


func _label_with_text(root: Node, text: String) -> Label:
	for node: Node in root.find_children("*", "Label", true, false):
		if (node as Label).text == text:
			return node as Label
	return null


func test_project_default_font_is_rubik_medium() -> void:
	assert_eq(ProjectSettings.get_setting("gui/theme/custom_font", ""), PlayerFonts.UI_PATH)
	var ui := load(PlayerFonts.UI_PATH) as FontVariation
	assert_not_null(ui, "a FontVariation")
	if ui != null:
		assert_string_starts_with(ui.base_font.get_font_name(), "Rubik", "the variable Rubik file (it names itself after its default instance)")
		assert_eq(int(ui.variation_opentype.get(TextServerManager.get_primary_interface().name_to_tag("wght"), 0)), 500, "Medium weight")


func test_display_and_bold_fonts() -> void:
	assert_eq(PlayerFonts.DISPLAY.get_font_name(), "Bungee")
	assert_string_starts_with(PlayerFonts.BOLD.base_font.get_font_name(), "Rubik")
	assert_eq(int(PlayerFonts.BOLD.variation_opentype.get(TextServerManager.get_primary_interface().name_to_tag("wght"), 0)), 700)


func test_licenses_ship_with_the_fonts() -> void:
	assert_true(FileAccess.file_exists("res://systems/player/fonts/OFL-Bungee.txt"))
	assert_true(FileAccess.file_exists("res://systems/player/fonts/OFL-Rubik.txt"))


func test_hud_big_text_uses_bungee() -> void:
	var player := _cart(0, "player")
	var hud := PlayerHud.new()
	hud.cart = player
	add_child_autofree(hud)
	simulate(hud, 1, 0.0)
	var timer := hud.layout.get_node("%TimerLabel") as Label
	assert_eq(timer.get_theme_font("font"), PlayerFonts.DISPLAY, "timer")
	RoundManager.phase = GameTypes.Phase.COUNTDOWN
	simulate(hud, 1, 0.1)
	var countdown := _label_with_text(hud, "3")
	assert_not_null(countdown, "countdown label")
	if countdown != null:
		assert_eq(countdown.get_theme_font("font"), PlayerFonts.DISPLAY, "countdown")
	RoundManager.checked_out.emit(player, 50)
	var popup := _label_with_text(hud, "Checked out $50")
	assert_not_null(popup, "popup label")
	if popup != null:
		assert_eq(popup.get_theme_font("font"), PlayerFonts.DISPLAY, "popup")
	RoundManager.phase = GameTypes.Phase.RUSH
	var item := ItemData.new()
	item.item_id = 9900
	item.value = 10
	player.try_add_item(item)
	assert_eq(hud.pop_nodes()[0].font, PlayerFonts.DISPLAY, "+$ pop")
	var feed_line := _label_with_text(hud, "You checked out $50")
	assert_not_null(feed_line, "feed line")
	if feed_line != null:
		assert_ne(feed_line.get_theme_font("font"), PlayerFonts.DISPLAY, "small text stays Rubik")


func test_name_tags_use_rubik_bold() -> void:
	var carl := _cart(1, "carl")
	assert_eq((carl.get_node("Visual/NameTag") as Label3D).font, PlayerFonts.BOLD)


func test_title_and_pause_titles_use_bungee() -> void:
	var flow := TitleFlow.new()
	add_child_autofree(flow)
	var title := _label_with_text(flow, PlayerStrings.STORE_NAME.to_upper())
	assert_not_null(title, "store name on the title screen")
	if title != null:
		assert_eq(title.get_theme_font("font"), PlayerFonts.DISPLAY)
	var menu := PauseMenu.new()
	menu.restart_reloads_scene = false
	add_child_autofree(menu)
	var paused := _label_with_text(menu, "PAUSED")
	assert_not_null(paused)
	if paused != null:
		assert_eq(paused.get_theme_font("font"), PlayerFonts.DISPLAY)
