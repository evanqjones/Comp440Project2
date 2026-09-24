extends GutTest
## Project settings every system relies on (docs/CONTRACTS.md §5–§6, GAME_SPEC.md §8).

const KEYBOARD := {
	"drive_gas": [KEY_W, KEY_UP],
	"drive_brake": [KEY_S, KEY_DOWN],
	"steer_left": [KEY_A, KEY_LEFT],
	"steer_right": [KEY_D, KEY_RIGHT],
	"boost": [KEY_SHIFT, KEY_SPACE],
	"pause": [KEY_ESCAPE],
}

const LAYERS := ["world", "carts", "pickups", "hazards", "zones"]


func test_input_actions_exist() -> void:
	for action: String in KEYBOARD:
		assert_true(InputMap.has_action(action), "input action %s exists" % action)
		if not InputMap.has_action(action):
			continue
		var events := InputMap.action_get_events(action)
		var has_key := events.any(func(e: InputEvent) -> bool: return e is InputEventKey)
		var has_pad := events.any(func(e: InputEvent) -> bool:
			return e is InputEventJoypadButton or e is InputEventJoypadMotion)
		assert_true(has_key, "%s has a keyboard binding" % action)
		assert_true(has_pad, "%s has a gamepad binding" % action)


func test_keyboard_bindings_match_spec() -> void:
	for action: String in KEYBOARD:
		if not InputMap.has_action(action):
			fail_test("input action %s is missing" % action)
			continue
		var keys: Array = []
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				keys.append((event as InputEventKey).physical_keycode)
		for key: Key in KEYBOARD[action]:
			assert_has(keys, key, "%s is bound to %s" % [action, OS.get_keycode_string(key)])


func test_physics_layer_names() -> void:
	for i: int in LAYERS.size():
		var setting := "layer_names/3d_physics/layer_%d" % (i + 1)
		assert_eq(ProjectSettings.get_setting(setting, ""), LAYERS[i], "3D physics layer %d name" % (i + 1))
