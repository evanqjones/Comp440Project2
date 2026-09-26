class_name PlayerHud
extends CanvasLayer
## In-round HUD (docs/features/player/06-hud/FEATURE.md): timer and round, scoreboard, cart panel
## with boost bar, event feed, popups, and the minimap (player/07-minimap). Fills Evan's assets/ui/hud_layout.tscn through its scene
## unique names (ASSETS.md §4). Until his file exists, a placeholder with the same names is used.

const EVAN_LAYOUT := "res://assets/ui/hud_layout.tscn"
const PLACEHOLDER_LAYOUT := "res://systems/player/hud/placeholder_hud_layout.tscn"
const FINAL_CALL_COLOR := Color("#FF5252")
const POPUP_COLOR := Color("#FFE135")
## Most feed lines shown; each fades out after FEED_SECONDS.
const FEED_SIZE := 5
const FEED_SECONDS := 6.0
const POPUP_SECONDS := 1.6

## The human's cart.
@export var cart: Cart

## The instanced layout (Evan's or the placeholder).
var layout: Control

var _timer: Label
var _round: Label
var _scores: Container
var _count: Label
var _value: Label
var _boost: Range
var _feed: Container
var _popups: Control
var _timer_color := Color.WHITE


## Evan's layout if it's in the project, else the placeholder.
static func layout_path() -> String:
	return EVAN_LAYOUT if ResourceLoader.exists(EVAN_LAYOUT) else PLACEHOLDER_LAYOUT


func _ready() -> void:
	layout = (load(layout_path()) as PackedScene).instantiate() as Control
	add_child(layout)
	_timer = layout.get_node_or_null("%TimerLabel") as Label
	_round = layout.get_node_or_null("%RoundLabel") as Label
	_scores = layout.get_node_or_null("%ScoreList") as Container
	_count = layout.get_node_or_null("%CartCountLabel") as Label
	_value = layout.get_node_or_null("%CartValueLabel") as Label
	_boost = layout.get_node_or_null("%BoostBar") as Range
	_feed = layout.get_node_or_null("%FeedList") as Container
	if _timer != null:
		_timer_color = _timer.get_theme_color("font_color")
	var slot := layout.get_node_or_null("%Minimap") as Control
	if slot != null:
		var minimap := HudMinimap.new()
		minimap.player = cart
		minimap.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot.add_child(minimap)
	_popups = Control.new()
	_popups.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popups.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_popups)
	RoundManager.checked_out.connect(_on_checked_out)
	_watch_registered()


func _process(delta: float) -> void:
	_watch_registered() # carts can register after the HUD is ready
	_show_timer()
	_show_scores()
	_show_cart()
	_age_feed(delta)


## Report steals involving `other` (safe to call more than once).
func watch(other: Cart) -> void:
	if other != null and not other.cart_robbed.is_connected(_on_cart_robbed):
		other.cart_robbed.connect(_on_cart_robbed)


## The feed's lines, oldest first.
func feed_lines() -> PackedStringArray:
	return _texts(_feed)


## Popups still on screen.
func popup_texts() -> PackedStringArray:
	return _texts(_popups)


func _watch_registered() -> void:
	watch(cart)
	for other: Cart in RoundManager.get_carts():
		watch(other)


# --- Readouts ------------------------------------------------------------------

func _show_timer() -> void:
	if _timer != null:
		var seconds := ceili(maxf(RoundManager.time_left, 0.0))
		_timer.text = "%d:%02d" % [seconds / 60, seconds % 60]
		var final_call := RoundManager.phase == GameTypes.Phase.FINAL_CALL
		_timer.add_theme_color_override("font_color", FINAL_CALL_COLOR if final_call else _timer_color)
	if _round != null:
		_round.text = "Round %d" % maxi(1, RoundManager.round_number)


## One line per cart, most banked first (ties by cart id, so lines don't flicker).
func _show_scores() -> void:
	if _scores == null:
		return
	var carts := RoundManager.get_carts()
	carts.sort_custom(func(a: Cart, b: Cart) -> bool:
		var banked_a := RoundManager.get_round_banked(a.cart_id)
		var banked_b := RoundManager.get_round_banked(b.cart_id)
		return banked_a > banked_b or (banked_a == banked_b and a.cart_id < b.cart_id))
	while _scores.get_child_count() < carts.size():
		_scores.add_child(_make_label("", 20, HORIZONTAL_ALIGNMENT_RIGHT))
	while _scores.get_child_count() > carts.size():
		var extra := _scores.get_child(_scores.get_child_count() - 1)
		_scores.remove_child(extra)
		extra.queue_free()
	for i: int in carts.size():
		var line := _scores.get_child(i) as Label
		var other := carts[i]
		line.text = "%s   $%d banked · $%d cart" % [_name(other), RoundManager.get_round_banked(other.cart_id), other.get_state().value]
		if other.profile != null:
			line.add_theme_color_override("font_color", other.profile.color)


func _show_cart() -> void:
	if cart == null:
		return
	var state := cart.get_state()
	if _count != null:
		_count.text = "%d/%d" % [state.items.size(), cart.tuning.item_cap]
	if _value != null:
		_value.text = "$%d" % state.value
	if _boost != null:
		_boost.value = lerpf(_boost.min_value, _boost.max_value, state.boost_meter)


# --- Feed and popups -------------------------------------------------------------

func _on_cart_robbed(winner: Cart, loser: Cart, items: Array[ItemData], _spilled: Array[ItemData]) -> void:
	if winner == null or loser == null:
		return
	_add_feed("%s inherited %s cart" % [_name(winner), _possessive(loser)])
	if winner == cart:
		_popup("Inherited! +%d %s" % [items.size(), "item" if items.size() == 1 else "items"], POPUP_COLOR)
	elif loser == cart:
		_popup("Knocked out of the sale!", FINAL_CALL_COLOR)


func _on_checked_out(who: Cart, value: int) -> void:
	if who == null:
		return
	_add_feed("%s checked out $%d" % [_name(who), value])
	if who == cart:
		_popup("Checked out $%d" % value, POPUP_COLOR)


func _add_feed(text: String) -> void:
	if _feed == null:
		return
	var line := _make_label(text, 20, HORIZONTAL_ALIGNMENT_LEFT)
	line.set_meta("age", 0.0)
	_feed.add_child(line)
	while _feed.get_child_count() > FEED_SIZE:
		var oldest := _feed.get_child(0)
		_feed.remove_child(oldest)
		oldest.queue_free()


func _age_feed(delta: float) -> void:
	if _feed == null:
		return
	for line: Node in _feed.get_children():
		var age: float = line.get_meta("age", 0.0) + delta
		line.set_meta("age", age)
		(line as CanvasItem).modulate.a = clampf(FEED_SECONDS - age, 0.0, 1.0) # fades in the last second
		if age >= FEED_SECONDS:
			_feed.remove_child(line)
			line.queue_free()


## Big text above the middle of the screen that floats up and fades.
func _popup(text: String, color: Color) -> void:
	var label := _make_label(text, 46, HORIZONTAL_ALIGNMENT_CENTER)
	label.add_theme_color_override("font_color", color)
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_left = -420.0
	label.offset_right = 420.0
	label.offset_top = -170.0 + _popups.get_child_count() * 56.0
	label.offset_bottom = label.offset_top + 56.0
	_popups.add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 60.0, POPUP_SECONDS)
	tween.parallel().tween_property(label, "modulate:a", 0.0, POPUP_SECONDS * 0.5).set_delay(POPUP_SECONDS * 0.5)
	tween.tween_callback(func() -> void:
		_popups.remove_child(label)
		label.queue_free())


# --- Helpers -------------------------------------------------------------------

func _name(who: Cart) -> String:
	if who == cart:
		return "You"
	return who.profile.display_name if who.profile != null else "Shopper %d" % who.cart_id


func _possessive(who: Cart) -> String:
	return "your" if who == cart else _name(who) + "'s"


func _make_label(text: String, size: int, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	return label


func _texts(container: Node) -> PackedStringArray:
	var texts := PackedStringArray()
	if container != null:
		for child: Node in container.get_children():
			if child is Label:
				texts.append((child as Label).text)
	return texts
