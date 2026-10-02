class_name RoundReceipt
extends CanvasLayer
## Receipt-style round results (docs/features/player/08-receipt/FEATURE.md): each shopper's banked
## total, the stamp awarded, and the stamp standings (GAME_SPEC.md §3.1, §3.2). Shown on
## RoundManager.round_ended, hidden on round_started. Fills Evan's assets/ui/receipt_layout.tscn
## through its % names; until that file exists, a placeholder with the same names is used.
## Best of 3 (docs/features/store/05-best-of-three/FEATURE.md): between rounds a top line counts
## down to the next round and the receipt hides when its 3-2-1 starts; after round 3 it's the
## MATCH OVER receipt with SHOP AGAIN, and Grandma's card reissued in your name if you won.

const EVAN_LAYOUT := "res://assets/ui/receipt_layout.tscn"
const PLACEHOLDER_LAYOUT := "res://systems/player/results/placeholder_receipt_layout.tscn"
## Characters per receipt line, name + dot leader + amount.
const LINE_WIDTH := 30

## The human's cart (reads as "You").
@export var cart: Cart
## Optional line shown under the receipt (the demo: "Press R to play again").
@export var footer: String = ""

## The instanced layout (Evan's or the placeholder).
var layout: Control
var _footer_label: Label
var _next_round: int = 0
var _next_round_left: float = 0.0
var _shop_again: Button
var _card_holder: Control


## Evan's layout if it's in the project, else the placeholder.
static func layout_path() -> String:
	return EVAN_LAYOUT if ResourceLoader.exists(EVAN_LAYOUT) else PLACEHOLDER_LAYOUT


func _init() -> void:
	layer = 5


func _ready() -> void:
	layout = (load(layout_path()) as PackedScene).instantiate() as Control
	layout.visible = false
	add_child(layout)
	_use_receipt_fonts()
	_footer_label = Label.new()
	_footer_label.set_anchors_preset(Control.PRESET_CENTER_TOP) # top center is free: timer left, scores right
	_footer_label.offset_left = -300.0
	_footer_label.offset_right = 300.0
	_footer_label.offset_top = 22.0
	_footer_label.offset_bottom = 62.0
	_footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer_label.add_theme_font_size_override("font_size", 24)
	_footer_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_footer_label.add_theme_constant_override("outline_size", 6)
	_footer_label.visible = false
	add_child(_footer_label)
	_build_match_end()
	RoundManager.round_ended.connect(_on_round_ended)
	RoundManager.round_started.connect(_on_round_started)
	RoundManager.phase_changed.connect(_on_phase_changed)


func _process(delta: float) -> void:
	if _next_round_left <= 0.0:
		return
	_next_round_left = maxf(_next_round_left - delta, 0.0)
	_footer_label.text = "Round %d starts in %d" % [_next_round, ceili(_next_round_left)]


## SHOP AGAIN (bottom center) and the reissued Shopper ID card (left of the receipt).
func _build_match_end() -> void:
	_shop_again = CardUi.go_button("Shop again")
	_shop_again.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_shop_again.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_shop_again.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_shop_again.offset_bottom = -24.0
	_shop_again.visible = false
	_shop_again.pressed.connect(_on_shop_again)
	add_child(_shop_again)
	_card_holder = VBoxContainer.new()
	_card_holder.add_theme_constant_override("separation", 8)
	_card_holder.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_card_holder.offset_left = 24.0
	_card_holder.offset_top = -150.0
	_card_holder.scale = Vector2(0.85, 0.85)
	_card_holder.visible = false
	add_child(_card_holder)


## What the top line says now ("" when hidden).
func footer_text() -> String:
	return _footer_label.text if _footer_label.visible else ""


func shop_again_visible() -> bool:
	return _shop_again.visible


func shop_again_button() -> Button:
	return _shop_again


func reissued_card_visible() -> bool:
	return _card_holder.visible


## Courier Prime on every receipt label, the round title and stamp line in bold (the artifact's
## receipt type, player/13-artifact-screens).
func _use_receipt_fonts() -> void:
	for node: Node in layout.find_children("*", "Label", true, false):
		(node as Label).add_theme_font_override("font", PlayerFonts.COURIER)
	for part: String in ["RoundTitle", "StampRow"]:
		var label := layout.get_node_or_null("%" + part) as Label
		if label != null:
			label.add_theme_font_override("font", PlayerFonts.COURIER_BOLD)


func is_showing() -> bool:
	return layout != null and layout.visible


func _on_round_started(_round_number: int) -> void:
	_hide_all()


## The next round's 3-2-1 (or a new match's) clears the receipt so the countdown is visible.
func _on_phase_changed(next_phase: GameTypes.Phase) -> void:
	if next_phase == GameTypes.Phase.COUNTDOWN:
		_hide_all()


func _hide_all() -> void:
	layout.visible = false
	_footer_label.visible = false
	_footer_label.text = ""
	_next_round_left = 0.0
	_shop_again.visible = false
	_card_holder.visible = false


func _on_shop_again() -> void:
	_hide_all()
	RoundManager.start_match()


func _on_round_ended(results: RoundResults) -> void:
	if results.is_match_over:
		_show_match_over(results)
		return
	var names := _names()
	var round_number := maxi(1, results.round_number)
	_set_text("RoundTitle", "%s\nRound %d · Day %d of the sale" % [PlayerStrings.STORE_NAME.to_upper(), round_number, round_number])
	var ids: Array[int] = []
	for id: int in names:
		ids.append(id)
	for id: int in results.banked:
		if not ids.has(id):
			ids.append(id)
	ids.sort_custom(func(a: int, b: int) -> bool:
		var banked_a: int = results.banked.get(a, 0)
		var banked_b: int = results.banked.get(b, 0)
		return banked_a > banked_b or (banked_a == banked_b and a < b))
	var lines: PackedStringArray = []
	for id: int in ids:
		lines.append(_leader(_name(names, id), "$%d" % results.banked.get(id, 0)))
	_set_text("ReceiptLines", "\n".join(lines))
	var winners: PackedStringArray = []
	for id: int in results.winner_ids:
		winners.append(_name(names, id))
	if winners.is_empty():
		_set_text("StampRow", "No stamp today")
	else:
		_set_text("StampRow", "★ %s: %s" % ["Stamp" if winners.size() == 1 else "Stamps", ", ".join(winners)])
	ids.sort_custom(func(a: int, b: int) -> bool:
		var stamps_a: int = results.stamps.get(a, 0)
		var stamps_b: int = results.stamps.get(b, 0)
		return stamps_a > stamps_b or (stamps_a == stamps_b and a < b))
	var standings: PackedStringArray = []
	for id: int in ids:
		standings.append("%s %d" % [_name(names, id), results.stamps.get(id, 0)])
	_set_text("Standings", "Stamps: " + " · ".join(standings))
	layout.visible = true
	_footer_label.text = footer
	_footer_label.visible = footer != ""
	if footer == "" and results.round_number < RoundManager.ROUNDS_PER_MATCH:
		_next_round = results.round_number + 1
		_next_round_left = RoundManager.RESULTS_DURATION
		_footer_label.text = "Round %d starts in %d" % [_next_round, ceili(_next_round_left)]
		_footer_label.visible = true


## After round 3: match totals sorted by stamps then money, the winner, SHOP AGAIN, and Grandma's
## card reissued in your name if you won (GAME_SPEC.md §3.2).
func _show_match_over(results: RoundResults) -> void:
	var names := _names()
	_set_text("RoundTitle", "%s\nMatch over · %d days of the sale" % [PlayerStrings.STORE_NAME.to_upper(), maxi(1, results.round_number)])
	var ids: Array[int] = []
	for id: int in names:
		ids.append(id)
	for id: int in results.match_banked:
		if not ids.has(id):
			ids.append(id)
	ids.sort_custom(func(a: int, b: int) -> bool:
		var stamps_a: int = results.stamps.get(a, 0)
		var stamps_b: int = results.stamps.get(b, 0)
		var banked_a: int = results.match_banked.get(a, 0)
		var banked_b: int = results.match_banked.get(b, 0)
		return stamps_a > stamps_b or (stamps_a == stamps_b and (banked_a > banked_b or (banked_a == banked_b and a < b))))
	var lines: PackedStringArray = []
	for id: int in ids:
		var stars := "★".repeat(results.stamps.get(id, 0))
		lines.append(_leader(("%s %s" % [_name(names, id), stars]).strip_edges(), "$%d" % results.match_banked.get(id, 0)))
	_set_text("ReceiptLines", "\n".join(lines))
	var winners: PackedStringArray = []
	for id: int in results.match_winner_ids:
		winners.append(_name(names, id))
	if winners.is_empty():
		_set_text("StampRow", "No winner today")
	else:
		_set_text("StampRow", "★ %s: %s" % ["Winner" if winners.size() == 1 else "Winners", ", ".join(winners)])
	var standings: PackedStringArray = []
	for id: int in ids:
		standings.append("%s %d" % [_name(names, id), results.stamps.get(id, 0)])
	_set_text("Standings", "Stamps: " + " · ".join(standings))
	layout.visible = true
	_next_round_left = 0.0
	_footer_label.text = "Match over"
	_footer_label.visible = true
	_shop_again.visible = true
	_shop_again.grab_focus.call_deferred()
	for child: Node in _card_holder.get_children():
		_card_holder.remove_child(child)
		child.queue_free()
	var you_won := cart != null and results.match_winner_ids.has(cart.cart_id)
	_card_holder.visible = you_won
	if you_won and cart.profile != null:
		var caption := CardUi.label("Grandma's card, reissued in your name", PlayerFonts.rubik(700), 18, CardUi.MUSTARD)
		caption.add_theme_color_override("font_outline_color", Color.BLACK)
		caption.add_theme_constant_override("outline_size", 6)
		_card_holder.add_child(caption)
		_card_holder.add_child(ShopperIdCard.make(cart.profile, "", results.stamps.get(cart.cart_id, 0)))


## cart_id -> name for every registered cart ("You" for the player).
func _names() -> Dictionary:
	var names := {}
	for other: Cart in RoundManager.get_carts():
		names[other.cart_id] = "You" if other == cart else (other.profile.display_name if other.profile != null else "")
	if cart != null:
		names[cart.cart_id] = "You"
	return names


func _name(names: Dictionary, id: int) -> String:
	var found: String = names.get(id, "")
	return found if found != "" else "Shopper %d" % id


## "Coupon Carl ........ $480": the name and amount with a dot leader between.
func _leader(left: String, right: String) -> String:
	var dots := maxi(2, LINE_WIDTH - left.length() - right.length() - 2)
	return "%s %s %s" % [left, ".".repeat(dots), right]


func _set_text(part: String, text: String) -> void:
	var label := layout.get_node_or_null("%" + part) as Label
	if label != null:
		label.text = text
