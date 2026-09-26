class_name RoundReceipt
extends CanvasLayer
## Receipt-style round results (docs/features/player/08-receipt/FEATURE.md): each shopper's banked
## total, the stamp awarded, and the stamp standings (GAME_SPEC.md §3.1, §3.2). Shown on
## RoundManager.round_ended, hidden on round_started. Fills Evan's assets/ui/receipt_layout.tscn
## through its % names; until that file exists, a placeholder with the same names is used.

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


## Evan's layout if it's in the project, else the placeholder.
static func layout_path() -> String:
	return EVAN_LAYOUT if ResourceLoader.exists(EVAN_LAYOUT) else PLACEHOLDER_LAYOUT


func _init() -> void:
	layer = 5


func _ready() -> void:
	layout = (load(layout_path()) as PackedScene).instantiate() as Control
	layout.visible = false
	add_child(layout)
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
	RoundManager.round_ended.connect(_on_round_ended)
	RoundManager.round_started.connect(_on_round_started)


func is_showing() -> bool:
	return layout != null and layout.visible


func _on_round_started(_round_number: int) -> void:
	layout.visible = false
	_footer_label.visible = false


func _on_round_ended(results: RoundResults) -> void:
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


## cart_id -> name for every registered cart ("You" for the player).
func _names() -> Dictionary:
	var names := {}
	for other: Cart in RoundManager.get_carts():
		names[other.cart_id] = "You" if other == cart else (other.profile.display_name if other.profile != null else "")
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
