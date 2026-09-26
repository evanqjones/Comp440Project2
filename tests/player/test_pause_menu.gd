extends GutTest
## Pause menu (docs/features/player/05-pause-menu/FEATURE.md).


func after_each() -> void:
	get_tree().paused = false


func _menu() -> PauseMenu:
	var menu := PauseMenu.new()
	menu.restart_reloads_scene = false # don't reload GUT's own scene
	add_child_autofree(menu)
	return menu


func _press_pause(menu: PauseMenu) -> void:
	var event := InputEventAction.new()
	event.action = "pause"
	event.pressed = true
	menu._unhandled_input(event)


func test_starts_closed_and_runs_while_paused() -> void:
	var menu := _menu()
	assert_false(menu.is_open())
	assert_false(get_tree().paused)
	assert_eq(menu.process_mode, Node.PROCESS_MODE_ALWAYS, "keeps working while the game is paused")


func test_pause_action_toggles_the_game() -> void:
	var menu := _menu()
	_press_pause(menu)
	assert_true(menu.is_open(), "Esc / Start opens it")
	assert_true(get_tree().paused, "the whole game stops")
	_press_pause(menu)
	assert_false(menu.is_open())
	assert_false(get_tree().paused, "and resumes")


func test_resume_button_closes() -> void:
	var menu := _menu()
	menu.open()
	menu.find_child("Resume", true, false).emit_signal("pressed")
	assert_false(get_tree().paused)
	assert_false(menu.is_open())


func test_restart_unpauses_and_asks_for_a_restart() -> void:
	var menu := _menu()
	watch_signals(menu)
	menu.open()
	menu.find_child("Restart", true, false).emit_signal("pressed")
	assert_false(get_tree().paused, "never reload into a paused tree")
	assert_signal_emitted(menu, "restart_requested")


func test_quit_hidden_only_on_web() -> void:
	var menu := _menu()
	var quit := menu.find_child("Quit", true, false) as Button
	assert_not_null(quit)
	assert_eq(quit.visible, not OS.has_feature("web"), "a browser tab can't quit")


func test_freeing_while_open_unpauses() -> void:
	var menu := PauseMenu.new()
	add_child(menu)
	menu.open()
	menu.free()
	assert_false(get_tree().paused, "leaving the scene never strands the game paused")
