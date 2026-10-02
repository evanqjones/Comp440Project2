class_name TitleFlow
extends CanvasLayer
## Title, story and rival intro screens before the round (docs/features/player/09-title/FEATURE.md),
## drawn as the Shopping Cart Derby artifact's paper cards over a blurred store
## (docs/features/player/13-artifact-screens/FEATURE.md):
## TITLE (the artifact's menu card: the first input also lets web audio start) → STORY (Grandma's
## Card, GAME_SPEC.md §2) → RIVALS (Carl, Bev and Rita, §2.2) → OPEN THE DOORS.
## Each card's button, or any key, gamepad button or click, advances. At the end it calls
## RoundManager.start_match() (CONTRACTS.md §3) and frees itself. Restarts in the same session skip it.

signal finished

enum Step { TITLE, STORY, RIVALS, DONE }

const RIVALS := ["carl", "bev", "rita"]
const CATEGORY_NAMES := ["Produce", "Bakery", "Dairy", "Snacks", "Frozen", "Electronics"]
const LEDE := "It's the grand opening. When the doors slide open you have two minutes to grab what you can and drive it back out the front doors. Only checked-out items count."
const STORY := [
	"Your grandma was this store's most famous shopper.",
	"She left you her Platinum Shopper ID card...",
	"...and one instruction:",
	"\"Don't let Carl win.\"",
	"Win the weekend sale, and the card is reissued in your name.",
]

## True once the intro has played this session; restarts go straight to the round.
static var seen: bool = false

var step: Step = Step.TITLE

var _center: CenterContainer
var _card: PanelContainer
var _rival_names := PackedStringArray()


func _init() -> void:
	layer = 20


func _ready() -> void:
	if seen:
		_finish()
		return
	var backdrop := CardUi.backdrop()
	add_child(backdrop)
	backdrop.capture_after_next_frame()
	_center = CenterContainer.new()
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_center)
	_show_step()


func advance() -> void:
	match step:
		Step.TITLE:
			step = Step.STORY
			_show_step()
		Step.STORY:
			step = Step.RIVALS
			_show_step()
		Step.RIVALS:
			_finish()


## Names on the rival cards (RIVALS step).
func rival_names() -> PackedStringArray:
	return _rival_names


## The paper card on screen now.
func card() -> PanelContainer:
	return _card


func _unhandled_input(event: InputEvent) -> void:
	if step == Step.DONE:
		return
	var is_press := event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton
	if is_press and event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		advance()


func _finish() -> void:
	step = Step.DONE
	seen = true
	finished.emit()
	RoundManager.start_match()
	queue_free()


# --- Screens -----------------------------------------------------------------

func _show_step() -> void:
	if _card != null:
		_center.remove_child(_card)
		_card.queue_free()
	match step:
		Step.TITLE:
			_card = _menu_card()
		Step.STORY:
			_card = _story_card()
		Step.RIVALS:
			_card = _rivals_card()
	_center.add_child(_card)
	CardUi.pop_in(_card)


## The artifact's menu card, retold for Checkout Chaos.
func _menu_card() -> PanelContainer:
	var panel := CardUi.card()
	var column := CardUi.content(panel)
	var heading := VBoxContainer.new()
	heading.add_theme_constant_override("separation", 4)
	heading.add_child(CardUi.eyebrow("%s · Grand opening weekend" % PlayerStrings.STORE_NAME, CardUi.MUTED, 11, 700))
	heading.add_child(CardUi.title("Checkout Chaos"))
	column.add_child(heading)
	column.add_child(CardUi.wrapped(LEDE, 15, CardUi.LEDE))
	var parts := HBoxContainer.new()
	parts.add_theme_constant_override("separation", 10)
	parts.add_child(CardUi.part(CardUi.MUSTARD, "Part 1", "The player", "You steer, brake and boost. Your inputs drive the cart."))
	parts.add_child(CardUi.part(CardUi.GREEN, "Part 2", "The cart", "Holds up to 24 items. Every item makes it a little slower."))
	parts.add_child(CardUi.part(CardUi.TOMATO, "Part 3", "The rivals", "Carl, Bev and Rita grab, ram and check out on their own."))
	column.add_child(parts)
	column.add_child(CardUi.rule("[color=#FFC93C][b]Inheritance rule:[/b][/color] when two carts crash, the faster cart wins and inherits the slower cart's whole load. Whatever doesn't fit spills on the floor for anyone to grab."))
	var tags := HFlowContainer.new()
	tags.add_theme_constant_override("h_separation", 6)
	tags.add_theme_constant_override("v_separation", 6)
	for i: int in CATEGORY_NAMES.size():
		tags.add_child(CardUi.tag(CartItemStack.COLORS[i as GameTypes.Category], CATEGORY_NAMES[i], "$%d" % RoundManager.CATEGORY_VALUES[i]))
	column.add_child(tags)
	column.add_child(CardUi.key_line([["kbd", "W"], ["kbd", "A"], ["kbd", "S"], ["kbd", "D"], ["txt", "or arrow keys to drive ·"], ["kbd", "Shift"], ["txt", "or"], ["kbd", "Space"], ["txt", "to boost ·"], ["kbd", "Enter"], ["txt", "to start"]]))
	column.add_child(_step_button("Let's shop"))
	return panel


## Grandma's Card: her Shopper ID beside the story.
func _story_card() -> PanelContainer:
	var panel := CardUi.card(720.0)
	var column := CardUi.content(panel)
	var heading := VBoxContainer.new()
	heading.add_theme_constant_override("separation", 4)
	heading.add_child(CardUi.eyebrow("The family business", CardUi.MUTED, 11, 700))
	heading.add_child(CardUi.title("Grandma's Card"))
	column.add_child(heading)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var id_card := CenterContainer.new()
	id_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	id_card.add_child(ShopperIdCard.make(load("res://systems/shared/profiles/player.tres"), "Grandma"))
	row.add_child(id_card)
	var story := VBoxContainer.new()
	story.add_theme_constant_override("separation", 8)
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for line: String in STORY:
		if line.begins_with("\""):
			story.add_child(CardUi.wrapped(line, 20, CardUi.TOMATO, PlayerFonts.rubik(700)))
		else:
			story.add_child(CardUi.wrapped(line, 15, CardUi.LEDE))
	row.add_child(story)
	column.add_child(row)
	column.add_child(CardUi.key_line([["kbd", "Enter"], ["txt", "or click to meet your rivals"]]))
	column.add_child(_step_button("Meet your rivals"))
	return panel


## Carl, Bev and Rita as ID tiles in their colors, and a tip.
func _rivals_card() -> PanelContainer:
	var panel := CardUi.card(720.0)
	var column := CardUi.content(panel)
	var heading := VBoxContainer.new()
	heading.add_theme_constant_override("separation", 4)
	heading.add_child(CardUi.eyebrow("Also shopping today", CardUi.MUTED, 11, 700))
	heading.add_child(CardUi.title("Meet your rivals"))
	column.add_child(heading)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_rival_names.clear()
	for rival: String in RIVALS:
		var profile: ShopperProfile = load("res://systems/shared/profiles/%s.tres" % rival)
		_rival_names.append(profile.display_name)
		row.add_child(_rival_tile(profile))
	column.add_child(row)
	column.add_child(CardUi.rule("[color=#FFC93C][b]Tip:[/b][/color] every item slows a cart down, so a full cart is a juicy target. Hit it faster than it's going and you inherit the lot."))
	column.add_child(CardUi.key_line([["kbd", "Enter"], ["txt", "or click to open the doors"]]))
	column.add_child(_step_button("Open the doors"))
	return panel


func _rival_tile(profile: ShopperProfile) -> PanelContainer:
	var tile := CardUi.tile(profile.color)
	var column := CardUi.content(tile)
	column.add_theme_constant_override("separation", 6)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.add_child(CardUi.swatch(profile.color, 34.0, 6))
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 1)
	names.add_child(CardUi.eyebrow("%s member" % profile.tier, CardUi.MUTED, 11, 700))
	names.add_child(CardUi.label(profile.display_name, PlayerFonts.rubik(700), 16, CardUi.INK))
	top.add_child(names)
	column.add_child(top)
	column.add_child(CardUi.label("No. %s · since %d" % [profile.member_number, profile.member_since], PlayerFonts.COURIER_BOLD, 12, CardUi.BODY))
	column.add_child(CardUi.wrapped(profile.blurb, 13, CardUi.BODY))
	return tile


func _step_button(text: String) -> Button:
	var button := CardUi.go_button(text)
	button.pressed.connect(advance)
	return button
