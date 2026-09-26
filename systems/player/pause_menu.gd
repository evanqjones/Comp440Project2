class_name PauseMenu
extends CanvasLayer
## Pause menu on the `pause` action, Esc / Start (docs/features/player/05-pause-menu/FEATURE.md).
## Opening pauses the whole tree (round clock, carts, bots, physics). This layer keeps running
## while paused. Built in code; Evan can restyle it later.

## Emitted by Restart after unpausing. The scene reloads too, unless restart_reloads_scene is off.
signal restart_requested

## Tests turn this off so Restart doesn't reload GUT's own scene.
var restart_reloads_scene: bool = true

var _root: Control
var _resume: Button


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10


func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	column.add_child(title)
	_resume = _button(column, "Resume", "Resume", close)
	_button(column, "Restart", "Restart round", _restart)
	var quit := _button(column, "Quit", "Quit", func() -> void: get_tree().quit())
	quit.visible = not OS.has_feature("web")


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


func _button(parent: Control, node_name: String, label: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.custom_minimum_size = Vector2(260.0, 52.0)
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(action)
	parent.add_child(button)
	return button
