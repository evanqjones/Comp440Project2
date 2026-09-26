class_name TitleFlow
extends CanvasLayer
## Title, story and rival intro screens before the round (docs/features/player/09-title/FEATURE.md).
## TITLE (store name, Grandma's card, "press any key": the first input also lets web audio start)
## → STORY (Grandma's Card, GAME_SPEC.md §2) → RIVALS (Carl, Bev and Rita's cards, §2.2).
## Any key, gamepad button or click advances. At the end it calls RoundManager.start_match()
## (CONTRACTS.md §3) and frees itself. Restarts in the same session skip it.

signal finished

enum Step { TITLE, STORY, RIVALS, DONE }

const RIVALS := ["carl", "bev", "rita"]
const HIGHLIGHT := Color("#FFE135")
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

var _screen: Control
var _rival_names := PackedStringArray()


func _init() -> void:
	layer = 20


func _ready() -> void:
	if seen:
		_finish()
		return
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
	if _screen != null:
		_screen.queue_free()
	_screen = Control.new()
	_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_screen)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.08, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.add_child(center)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)
	match step:
		Step.TITLE:
			column.add_child(_text(PlayerStrings.STORE_NAME.to_upper(), 60, HIGHLIGHT))
			column.add_child(_text("Grand Opening Weekend Sale", 26, Color.WHITE))
			column.add_child(_centered(ShopperIdCard.make(load("res://systems/shared/profiles/player.tres"), "Grandma")))
			column.add_child(_blinking("Press any key"))
		Step.STORY:
			for line: String in STORY:
				var quote := line.begins_with("\"")
				column.add_child(_text(line, 38 if quote else 28, HIGHLIGHT if quote else Color.WHITE))
			column.add_child(_blinking("Press any key"))
		Step.RIVALS:
			column.add_child(_text("Meet your rivals", 44, HIGHLIGHT))
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 16)
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			column.add_child(row)
			_rival_names.clear()
			for rival: String in RIVALS:
				var profile: ShopperProfile = load("res://systems/shared/profiles/%s.tres" % rival)
				_rival_names.append(profile.display_name)
				var stack := VBoxContainer.new()
				stack.add_theme_constant_override("separation", 10)
				stack.add_child(ShopperIdCard.make(profile))
				var blurb := _text(profile.blurb, 18, profile.color)
				blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				blurb.custom_minimum_size = Vector2(340.0, 0.0)
				stack.add_child(blurb)
				row.add_child(stack)
			column.add_child(_blinking("Press any key to start shopping"))


func _text(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	return label


func _blinking(text: String) -> Label:
	var label := _text(text, 24, Color.WHITE)
	var tween := label.create_tween().set_loops()
	tween.tween_property(label, "modulate:a", 0.3, 0.6)
	tween.tween_property(label, "modulate:a", 1.0, 0.6)
	return label


func _centered(child: Control) -> CenterContainer:
	var holder := CenterContainer.new()
	holder.add_child(child)
	return holder
