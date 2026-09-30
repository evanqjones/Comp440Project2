class_name CardUi
## The Shopping Cart Derby artifact's look, in one place (docs/features/player/12-artifact-screens/
## FEATURE.md; reference: docs/reference/shopping_cart_derby.html on the `artifact` branch): the
## palette, the paper card, part tiles, aisle tags, key caps, the chunky tomato button, the dark HUD
## panel with its mint eyebrow, the blurred backdrop (CardBackdrop), and the card pop-in.

const PAPER := Color("#F7F3E8")
const INK := Color("#0B2520")
const TOMATO := Color("#E4412B")
const TOMATO_EDGE := Color("#9E2716")
const MUSTARD := Color("#FFC93C")
const MINT := Color("#CFE3D6")
const MUTED := Color("#5E7A71")
const AISLE := Color("#123C33")
const GREEN := Color("#1C7A55")
const LEDE := Color("#274A42")
const BODY := Color("#355A51")
const LINE := Color("#D9D3C3")
const KEY_EDGE := Color("#CFC8B6")
const PANEL_BG := Color(11 / 255.0, 37 / 255.0, 32 / 255.0, 0.86)
const PILL_BG := Color(11 / 255.0, 37 / 255.0, 32 / 255.0, 0.8)
const SCREEN_DIM := Color(8 / 255.0, 26 / 255.0, 22 / 255.0, 0.5)
## CSS: 600 px of content + 24 px padding each side.
const CARD_WIDTH := 648.0
const POP_SECONDS := 0.28

## A rounded flat box (CSS background + border-radius + padding).
static func box(color: Color, radius: int, pad_x: float, pad_y: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = pad_x
	style.content_margin_right = pad_x
	style.content_margin_top = pad_y
	style.content_margin_bottom = pad_y
	return style


static func label(text: String, font: Font, size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_override("font", font)
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result


## Body text that wraps to its container's width.
static func wrapped(text: String, size: int, color: Color, font: Font = null) -> Label:
	var result := label(text, font if font != null else PlayerFonts.rubik(400), size, color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.custom_minimum_size = Vector2(50.0, 0.0)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result


## Text with [b]bold[/b] and [color] runs.
static func rich(bbcode: String, size: int, color: Color) -> RichTextLabel:
	var result := RichTextLabel.new()
	result.bbcode_enabled = true
	result.fit_content = true
	result.scroll_active = false
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.add_theme_font_override("normal_font", PlayerFonts.rubik(400))
	result.add_theme_font_override("bold_font", PlayerFonts.rubik(700))
	for kind: String in ["normal_font_size", "bold_font_size"]:
		result.add_theme_font_size_override(kind, size)
	result.add_theme_color_override("default_color", color)
	result.text = bbcode
	return result


## An uppercase eyebrow: small, letter-spaced (.12em), mint on dark panels or muted on paper.
static func eyebrow(text: String, color: Color = MINT, size: int = 11, weight: int = 400) -> Label:
	return label(text.to_upper(), PlayerFonts.spaced(PlayerFonts.rubik(weight), 1), size, color)


## The artifact's h1: Bungee in tomato.
static func title(text: String, size: int = 44) -> Label:
	return label(text, PlayerFonts.DISPLAY, size, TOMATO)


## The paper card: returns the PanelContainer; add rows to its "Content" VBoxContainer.
static func card(width: float = CARD_WIDTH) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := box(PAPER, 14, 24.0, 22.0)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 30
	style.shadow_offset = Vector2(0.0, 20.0)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(width, 0.0)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	return panel


## The "Content" column of a card() or tile().
static func content(panel: PanelContainer) -> VBoxContainer:
	return panel.get_node("Content") as VBoxContainer


## An empty white tile with a colored top edge; add rows to its "Content" VBoxContainer.
static func tile(accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := box(Color.WHITE, 10, 12.0, 10.0)
	style.border_width_top = 4
	style.border_color = accent
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.name = "Content"
	column.add_theme_constant_override("separation", 3)
	panel.add_child(column)
	return panel


## The artifact's "part" tile: eyebrow, bold title, body.
static func part(accent: Color, eyebrow_text: String, title_text: String, body: String) -> PanelContainer:
	var panel := tile(accent)
	var column := content(panel)
	column.add_child(eyebrow(eyebrow_text, MUTED, 11, 700))
	column.add_child(label(title_text, PlayerFonts.rubik(700), 15, INK))
	column.add_child(wrapped(body, 13, BODY))
	return panel


## A dark aisle-green box for a rule or tip; `bbcode` may color and bold its lead-in.
static func rule(bbcode: String) -> PanelContainer:
	var holder := PanelContainer.new()
	holder.add_theme_stylebox_override("panel", box(AISLE, 10, 12.0, 10.0))
	holder.add_child(rich(bbcode, 14, PAPER))
	return holder


## An aisle chip: color swatch, name, Courier price.
static func tag(color: Color, text: String, value: String) -> PanelContainer:
	var chip := PanelContainer.new()
	var style := box(Color.WHITE, 4, 0.0, 3.0)
	style.content_margin_left = 6.0
	style.content_margin_right = 8.0
	style.set_border_width_all(1)
	style.border_color = LINE
	chip.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(swatch(color, 9.0, 2))
	row.add_child(label(text, PlayerFonts.rubik(500), 12, INK))
	row.add_child(label(value, PlayerFonts.COURIER_BOLD, 12, INK))
	chip.add_child(row)
	return chip


## A small rounded color square.
static func swatch(color: Color, side: float, radius: int) -> Panel:
	var square := Panel.new()
	square.custom_minimum_size = Vector2(side, side)
	square.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	square.mouse_filter = Control.MOUSE_FILTER_IGNORE
	square.add_theme_stylebox_override("panel", box(color, radius, 0.0, 0.0))
	return square


## Key hints: parts are ["kbd", "W"] (a Courier key cap) or ["txt", "to drive ·"].
static func key_line(parts: Array) -> HFlowContainer:
	var line := HFlowContainer.new()
	line.add_theme_constant_override("h_separation", 4)
	line.add_theme_constant_override("v_separation", 4)
	for part: Array in parts:
		if part[0] == "kbd":
			var cap := PanelContainer.new()
			var style := box(Color.WHITE, 4, 5.0, 0.0)
			style.set_border_width_all(1)
			style.border_width_bottom = 2
			style.border_color = KEY_EDGE
			cap.add_theme_stylebox_override("panel", style)
			cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			cap.add_child(label(part[1], PlayerFonts.COURIER_BOLD, 13, INK))
			line.add_child(cap)
		else:
			line.add_child(label(part[1], PlayerFonts.rubik(400), 13, BODY))
	return line


## The chunky tomato button: Bungee caps, dark bottom edge, lighter on hover, presses down 2 px.
static func go_button(text: String) -> Button:
	var button := Button.new()
	button.text = text.to_upper()
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", PlayerFonts.DISPLAY)
	button.add_theme_font_size_override("font_size", 20)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, Color.WHITE)
	_button_styles(button, TOMATO, TOMATO_EDGE)
	return button


## The quieter button: white with an outline and ink text.
static func plain_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", PlayerFonts.rubik(700))
	button.add_theme_font_size_override("font_size", 17)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, INK)
	_button_styles(button, Color.WHITE, KEY_EDGE)
	return button


static func _button_styles(button: Button, fill: Color, edge: Color) -> void:
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		var pressed := state == "pressed" or state == "hover_pressed"
		var style := box(fill.lightened(0.08) if state == "hover" else fill, 10, 22.0, 12.0)
		style.border_width_bottom = 2 if pressed else 4
		style.border_color = edge
		if fill == Color.WHITE:
			style.border_width_left = 1
			style.border_width_right = 1
			style.border_width_top = 1
		if pressed: # the artifact's translateY(2px)
			style.content_margin_top = 14.0
			style.content_margin_bottom = 10.0
		if state == "focus":
			style.draw_center = false
			style.set_border_width_all(3)
			style.border_color = MUSTARD
			style.expand_margin_left = 3.0
			style.expand_margin_right = 3.0
			style.expand_margin_top = 3.0
			style.expand_margin_bottom = 3.0
		button.add_theme_stylebox_override(state, style)


## The dark rounded HUD panel.
static func hud_panel(pad_x: float = 12.0, pad_y: float = 8.0) -> StyleBoxFlat:
	return box(PANEL_BG, 10, pad_x, pad_y)


## Full-screen blurred and dimmed view of the store (see CardBackdrop for when it snapshots).
static func backdrop() -> CardBackdrop:
	return CardBackdrop.new()


## Fade `control` in from 0 while it grows from 94% to full size around its center.
static func pop_in(control: Control) -> void:
	control.modulate.a = 0.0
	control.scale = Vector2(0.94, 0.94)
	var center := func() -> void: control.pivot_offset = control.size / 2.0
	control.resized.connect(center)
	center.call()
	var tween := control.create_tween().set_parallel()
	tween.tween_property(control, "modulate:a", 1.0, POP_SECONDS).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, POP_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
