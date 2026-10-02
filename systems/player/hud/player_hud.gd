class_name PlayerHud
extends CanvasLayer
## In-round HUD (docs/features/player/06-hud/FEATURE.md): timer and round, scoreboard, cart panel
## with boost bar, event feed, popups, and the minimap (player/07-minimap). Fills Evan's assets/ui/hud_layout.tscn through its scene
## unique names (ASSETS.md §4). Until his file exists, a placeholder with the same names is used.
## player/10-hud-polish adds the 3-2-1-GO countdown, hint line, checkout arrow, "+$N" pickup pops,
## checkout confetti, and pill backgrounds behind feed and scoreboard lines.

const EVAN_LAYOUT := "res://assets/ui/hud_layout.tscn"
const PLACEHOLDER_LAYOUT := "res://systems/player/hud/placeholder_hud_layout.tscn"
const FINAL_CALL_COLOR := Color("#FF5252")
const POPUP_COLOR := Color("#FFE135")
## Most feed lines shown; each fades out after FEED_SECONDS.
const FEED_SIZE := 5
const FEED_SECONDS := 6.0
const POPUP_SECONDS := 1.6
## Widest a feed pill gets, so it stays left of the cart panel at the 1152 px base width.
const FEED_MAX_WIDTH := 284.0
const HINT_MAX_WIDTH := 560.0
const PILL_PAD_X := 10.0
const PILL_COLOR := Color(0.07, 0.09, 0.11, 0.6)
const GO_SECONDS := 0.8
const HINT_SECONDS := 2.5
const HINT_DOORS := "Doors open! Grab items, then check out outside."
const HINT_FINAL_CALL := "Final call! 20 seconds left"
const HINT_FULL := "Cart full! Drive out the doors to check out"
## "+$N" pops: start height over the cart, how far they rise, and how long they last.
const POP_HEIGHT := 2.4
const POP_RISE := 1.2
const POP_SECONDS := 0.9
## Pops that land together stack this far apart instead of overlapping.
const POP_STACK := 0.55
## Readout text changes rarely, so avoid rebuilding it on every rendered frame.
const HUD_UPDATE_INTERVAL := 0.1

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

var _countdown: Label
var _hint: PanelContainer
var _hint_label: Label
var _arrow_holder: Control
var _arrow: HudArrow
var _pops: Node
var _last_phase: GameTypes.Phase = GameTypes.Phase.IDLE
var _countdown_left := 0.0
var _go_left := 0.0
var _phase_hint := ""
var _phase_hint_left := 0.0
var _clock := 0.0
var _hud_refresh_elapsed := 0.0
var _has_hud_snapshot := false
var _cached_carts: Array[Cart] = []
var _cart_states: Dictionary[int, CartState] = {}
var _player_state: CartState


## Evan's layout if it's in the project, else the placeholder.
static func layout_path() -> String:
	return EVAN_LAYOUT if ResourceLoader.exists(EVAN_LAYOUT) else PLACEHOLDER_LAYOUT


## Signed flat angle from the view's forward direction to the target: 0 = straight ahead,
## + = to the right. Height is ignored, so a chase camera looking down still reads level.
static func heading_angle(view: Basis, from: Vector3, to: Vector3) -> float:
	var forward := -view.z
	forward.y = 0.0
	var right := view.x
	right.y = 0.0
	var to_target := to - from
	to_target.y = 0.0
	if forward.length_squared() < 0.000001 or to_target.length_squared() < 0.000001:
		return 0.0
	return atan2(to_target.dot(right.normalized()), to_target.dot(forward.normalized()))


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
		PlayerFonts.display(_timer)
	var slot := layout.get_node_or_null("%Minimap") as Control
	if slot != null:
		var minimap := HudMinimap.new()
		minimap.player = cart
		minimap.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot.add_child(minimap)
	_build_overlay()
	_popups = Control.new()
	_popups.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popups.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_popups)
	_pops = Node.new()
	_pops.name = "PickupPops"
	add_child(_pops) # 3D labels under a plain Node live in world space
	RoundManager.checked_out.connect(_on_checked_out)
	_watch_registered()


func _process(delta: float) -> void:
	visible = RoundManager.phase != GameTypes.Phase.IDLE # hidden behind the title screens
	_track_phase(delta)
	_hud_refresh_elapsed += delta
	if not _has_hud_snapshot or _hud_refresh_elapsed >= HUD_UPDATE_INTERVAL:
		_hud_refresh_elapsed = fmod(_hud_refresh_elapsed, HUD_UPDATE_INTERVAL)
		_refresh_hud_data()
	_show_arrow(delta)
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


## The big countdown text: "3", "2", "1", "GO!", or "" when hidden.
func countdown_text() -> String:
	if RoundManager.phase == GameTypes.Phase.COUNTDOWN:
		return str(maxi(1, ceili(_countdown_left)))
	if _go_left > 0.0:
		return "GO!"
	return ""


## The hint line's text, or "" when hidden.
func hint_text() -> String:
	if _phase_hint_left > 0.0:
		return _phase_hint
	if RoundManager.is_gameplay_active() and _cart_full():
		return HINT_FULL
	return ""


func arrow_visible() -> bool:
	return _arrow_holder.visible


## The arrow's turn in radians (0 = ahead, + = right).
func arrow_angle() -> float:
	return _arrow.rotation


## "+$N" pops still in the world.
func pop_nodes() -> Array[Label3D]:
	var pops: Array[Label3D] = []
	for child: Node in _pops.get_children():
		if child is Label3D and not child.is_queued_for_deletion():
			pops.append(child as Label3D)
	return pops


func pop_texts() -> PackedStringArray:
	var texts := PackedStringArray()
	for pop: Label3D in pop_nodes():
		texts.append(pop.text)
	return texts


## Confetti bursts still playing.
func confetti_count() -> int:
	var count := 0
	for child: Node in _popups.get_children():
		if child is CPUParticles2D and not child.is_queued_for_deletion():
			count += 1
	return count


func _watch_registered() -> void:
	watch(cart)
	for other: Cart in RoundManager.get_carts():
		watch(other)
	if cart != null and not cart.item_collected.is_connected(_on_item_collected):
		cart.item_collected.connect(_on_item_collected)


## Snapshot cart data once per HUD update pass and use it for each readout.
func _refresh_hud_data() -> void:
	_watch_registered() # carts can register after the HUD is ready
	_cached_carts = RoundManager.get_carts()
	if cart != null and not _cached_carts.has(cart):
		_cached_carts.append(cart)
	_cart_states.clear()
	for other: Cart in _cached_carts:
		_cart_states[other.cart_id] = other.get_state()
	_player_state = null
	if cart != null and _cart_states.has(cart.cart_id):
		_player_state = _cart_states[cart.cart_id]
	_show_timer()
	_show_scores()
	_show_cart()
	_show_countdown_and_hint()
	_has_hud_snapshot = true


# --- Readouts ------------------------------------------------------------------

func _show_timer() -> void:
	if _timer != null:
		var seconds := ceili(maxf(RoundManager.time_left, 0.0))
		_timer.text = "%d:%02d" % [seconds / 60, seconds % 60]
		var final_call := RoundManager.phase == GameTypes.Phase.FINAL_CALL
		_timer.add_theme_color_override("font_color", FINAL_CALL_COLOR if final_call else _timer_color)
	if _round != null:
		_round.text = "Round %d" % maxi(1, RoundManager.round_number)


## One pill per cart, most banked first (ties by cart id, so lines don't flicker).
func _show_scores() -> void:
	if _scores == null:
		return
	var carts: Array[Cart] = _cached_carts.duplicate()
	carts.sort_custom(func(a: Cart, b: Cart) -> bool:
		var banked_a := RoundManager.get_round_banked(a.cart_id)
		var banked_b := RoundManager.get_round_banked(b.cart_id)
		return banked_a > banked_b or (banked_a == banked_b and a.cart_id < b.cart_id))
	while _scores.get_child_count() < carts.size():
		var pill := _pill("", 20)
		pill.size_flags_horizontal = Control.SIZE_SHRINK_END
		(pill.get_child(0) as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_scores.add_child(pill)
	while _scores.get_child_count() > carts.size():
		var extra := _scores.get_child(_scores.get_child_count() - 1)
		_scores.remove_child(extra)
		extra.queue_free()
	for i: int in carts.size():
		var line := _scores.get_child(i).get_child(0) as Label
		var other := carts[i]
		var state: CartState
		if _cart_states.has(other.cart_id):
			state = _cart_states[other.cart_id]
		var cart_value := state.value if state != null else 0
		line.text = "%s   $%d banked · $%d cart" % [_name(other), RoundManager.get_round_banked(other.cart_id), cart_value]
		if other.profile != null:
			line.add_theme_color_override("font_color", other.profile.color)


func _show_cart() -> void:
	if cart == null:
		return
	var state := _player_state
	if state == null:
		return
	if _count != null:
		_count.text = "%d/%d" % [state.items.size(), cart.tuning.item_cap]
	if _value != null:
		_value.text = "$%d" % state.value
	if _boost != null:
		_boost.value = lerpf(_boost.min_value, _boost.max_value, state.boost_meter)


# --- Countdown, hints and the checkout arrow ----------------------------------------

func _build_overlay() -> void:
	_countdown = _make_label("", 150, HORIZONTAL_ALIGNMENT_CENTER)
	_countdown.set_anchors_preset(Control.PRESET_FULL_RECT)
	_countdown.offset_bottom = -80.0
	_countdown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown.add_theme_color_override("font_color", POPUP_COLOR)
	_countdown.add_theme_constant_override("outline_size", 18)
	PlayerFonts.display(_countdown)
	add_child(_countdown)

	var hint_row := HBoxContainer.new()
	hint_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hint_row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint_row.offset_top = -214.0 # just above Evan's cart panel
	hint_row.offset_bottom = -172.0
	hint_row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(hint_row)
	_hint = _pill("", 22)
	_hint.visible = false
	_hint_label = _hint.get_child(0) as Label
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_row.add_child(_hint)

	_arrow_holder = Control.new()
	_arrow_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow_holder.set_anchors_preset(Control.PRESET_CENTER)
	_arrow_holder.offset_left = -60.0
	_arrow_holder.offset_right = 60.0
	_arrow_holder.offset_top = -80.0 # over the shopper's head
	_arrow_holder.offset_bottom = 40.0
	_arrow_holder.visible = false
	add_child(_arrow_holder)
	_arrow = HudArrow.new()
	_arrow.position = Vector2((120.0 - HudArrow.SIZE.x) * 0.5, 0.0)
	_arrow_holder.add_child(_arrow)
	var tag := _make_label("CHECK OUT", 16, HORIZONTAL_ALIGNMENT_CENTER)
	PlayerFonts.display(tag)
	tag.position = Vector2(0.0, HudArrow.SIZE.y + 2.0)
	tag.size = Vector2(120.0, 22.0)
	_arrow_holder.add_child(tag)


## Start the countdown and GO!/hint timers when the phase changes, then tick them.
func _track_phase(delta: float) -> void:
	var phase := RoundManager.phase
	if phase != _last_phase:
		match phase:
			GameTypes.Phase.COUNTDOWN:
				_countdown_left = RoundManager.COUNTDOWN_DURATION
				_go_left = 0.0
			GameTypes.Phase.RUSH:
				_go_left = GO_SECONDS
				_set_phase_hint(HINT_DOORS)
			GameTypes.Phase.FINAL_CALL:
				_set_phase_hint(HINT_FINAL_CALL)
			_:
				_go_left = 0.0
				_phase_hint_left = 0.0
		_last_phase = phase
	_countdown_left = maxf(_countdown_left - delta, 0.0)
	_go_left -= delta
	_phase_hint_left -= delta


func _set_phase_hint(text: String) -> void:
	_phase_hint = text
	_phase_hint_left = HINT_SECONDS


func _show_countdown_and_hint() -> void:
	_countdown.text = countdown_text()
	var hint := hint_text()
	_hint.visible = hint != ""
	if _hint_label.text != hint:
		_hint_label.text = hint
		_fit(_hint_label, HINT_MAX_WIDTH)


func _show_arrow(delta: float) -> void:
	_clock += delta
	var items := _player_state.items.size() if _player_state != null else 0
	var final_call := RoundManager.phase == GameTypes.Phase.FINAL_CALL
	_arrow_holder.visible = RoundManager.is_gameplay_active() and (_cart_full() or (final_call and items > 0))
	if not _arrow_holder.visible:
		return
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		_arrow.rotation = heading_angle(camera.global_basis, cart.global_position, RoundManager.get_checkout_position())
	_arrow.position.y = sin(_clock * 6.0) * 5.0


func _cart_full() -> bool:
	return cart != null and _player_state != null and _player_state.items.size() >= cart.tuning.item_cap


# --- Feed, popups, pops and confetti ------------------------------------------------

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
		_confetti()


## "+$N" in the item's aisle color, rising over the player's cart.
func _on_item_collected(who: Cart, item: ItemData) -> void:
	if who != cart or item == null or not who.is_inside_tree():
		return
	var pop := Label3D.new()
	pop.text = "+$%d" % item.value
	pop.modulate = CartItemStack.color_for(item)
	pop.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
	pop.font = PlayerFonts.DISPLAY
	pop.font_size = 72
	pop.outline_size = 16
	pop.pixel_size = 0.008
	pop.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pop.no_depth_test = true
	pop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pop.position = who.global_position + Vector3(0.0, POP_HEIGHT + POP_STACK * (pop_nodes().size() % 4), 0.0)
	_pops.add_child(pop)
	var tween := pop.create_tween()
	tween.tween_property(pop, "position:y", pop.position.y + POP_RISE, POP_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(pop, "modulate:a", 0.0, POP_SECONDS * 0.5).set_delay(POP_SECONDS * 0.5)
	tween.parallel().tween_property(pop, "outline_modulate:a", 0.0, POP_SECONDS * 0.5).set_delay(POP_SECONDS * 0.5)
	tween.tween_callback(pop.queue_free)


## A one-shot burst of confetti in the six aisle colors, from where the checkout popup appears.
func _confetti() -> void:
	var burst := CPUParticles2D.new()
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = 90
	burst.lifetime = 1.4
	burst.direction = Vector2.UP
	burst.spread = 75.0
	burst.initial_velocity_min = 380.0
	burst.initial_velocity_max = 640.0
	burst.gravity = Vector2(0.0, 980.0)
	burst.angular_velocity_min = -360.0
	burst.angular_velocity_max = 360.0
	burst.scale_amount_min = 6.0
	burst.scale_amount_max = 11.0
	var colors := Gradient.new()
	colors.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var categories := [GameTypes.Category.PRODUCE, GameTypes.Category.BAKERY, GameTypes.Category.DAIRY, GameTypes.Category.SNACKS, GameTypes.Category.FROZEN, GameTypes.Category.ELECTRONICS]
	var offsets := PackedFloat32Array()
	var palette := PackedColorArray()
	for i: int in categories.size():
		offsets.append(float(i) / categories.size())
		palette.append(CartItemStack.COLORS[categories[i]])
	colors.offsets = offsets
	colors.colors = palette
	burst.color_initial_ramp = colors
	var screen := _popups.size if _popups.size != Vector2.ZERO else get_viewport().get_visible_rect().size
	burst.position = Vector2(screen.x * 0.5, screen.y * 0.5 - 140.0)
	burst.emitting = true
	_popups.add_child(burst)
	burst.create_tween().tween_callback(burst.queue_free).set_delay(burst.lifetime + 0.3)


func _add_feed(text: String) -> void:
	if _feed == null:
		return
	var line := _pill(text, 17)
	line.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	line.set_meta("age", 0.0)
	_feed.add_child(line)
	_fit(line.get_child(0) as Label, FEED_MAX_WIDTH)
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
	var label := _make_label(text, 40, HORIZONTAL_ALIGNMENT_CENTER)
	PlayerFonts.display(label)
	label.add_theme_color_override("font_color", color)
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_left = -420.0
	label.offset_right = 420.0
	label.offset_top = -170.0 + popup_texts().size() * 56.0
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


## A label on a soft, rounded dark background that shrinks to its text.
func _pill(text: String, size: int) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = PILL_COLOR
	style.set_corner_radius_all(10)
	style.content_margin_left = PILL_PAD_X
	style.content_margin_right = PILL_PAD_X
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_theme_stylebox_override("panel", style)
	var label := _make_label(text, size, HORIZONTAL_ALIGNMENT_LEFT)
	label.add_theme_constant_override("outline_size", 4)
	pill.add_child(label)
	return pill


## Wrap `label` when its text would make its pill wider than `max_width`.
func _fit(label: Label, max_width: float) -> void:
	var inner := max_width - PILL_PAD_X * 2.0 - 4.0 # 4 px of slack for the outline
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if width > inner:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = inner
	else:
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.custom_minimum_size.x = 0.0


## Texts of the Labels in `container`, looking one level into pills.
func _texts(container: Node) -> PackedStringArray:
	var texts := PackedStringArray()
	if container == null:
		return texts
	for child: Node in container.get_children():
		if child is Label:
			texts.append((child as Label).text)
		elif child.get_child_count() > 0 and child.get_child(0) is Label:
			texts.append((child.get_child(0) as Label).text)
	return texts
