class_name PauseMenu
extends CanvasLayer
## Pause menu on the `pause` action, Esc / Start (docs/features/player/05-pause-menu/FEATURE.md).
## Opening pauses the whole tree (round clock, carts, bots, physics). This layer keeps running
## while paused. Built in code as the artifact's paper card (player/13-artifact-screens).

## Emitted by Restart after unpausing. The scene reloads too, unless restart_reloads_scene is off.
signal restart_requested

## Tests turn this off so Restart doesn't reload GUT's own scene.
var restart_reloads_scene: bool = true

var _root: Control
var _resume: Button
var _backdrop: CardBackdrop


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10


func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	_backdrop = CardUi.backdrop() # the paused store, blurred and dimmed like the title cards
	_root.add_child(_backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var card := CardUi.card(380.0)
	center.add_child(card)
	var column := CardUi.content(card)
	column.add_child(CardUi.eyebrow("Round on hold", CardUi.MUTED, 11, 700))
	column.add_child(CardUi.title("PAUSED"))
	_resume = _button(column, "Resume", CardUi.go_button("Resume"), close)
	_button(column, "Restart", CardUi.plain_button("Restart round"), _restart)
	var quit := _button(column, "Quit", CardUi.plain_button("Quit"), func() -> void: get_tree().quit())
	quit.visible = not OS.has_feature("web")
	column.add_child(CardUi.key_line([["kbd", "Esc"], ["txt", "to keep shopping"]]))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if is_open():
		get_tree().paused = false


func is_open() -> bool:
	return _root != null and _root.visible


func open() -> void:
	_backdrop.capture() # the last frame, before the menu covers it
	_root.visible = true
	get_tree().paused = true
	_resume.grab_focus.call_deferred()


func close() -> void:
	_root.visible = false
	get_tree().paused = false


func toggle() -> void:
	if is_open():
		close()
	else:
		open()


func _restart() -> void:
	close()
	restart_requested.emit()
	if restart_reloads_scene:
		get_tree().reload_current_scene()


func _button(parent: Control, node_name: String, button: Button, action: Callable) -> Button:
	button.name = node_name
	button.size_flags_horizontal = Control.SIZE_FILL
	button.pressed.connect(action)
	parent.add_child(button)
	return button
