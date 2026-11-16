extends TestCase

const InputSetupScript := preload("res://core/input_setup.gd")


func test_actions_are_registered() -> void:
	InputSetupScript.register_defaults()
	for action in [&"move_forward", &"move_back", &"move_left", &"move_right", &"jump", &"sprint", &"interact", &"toggle_view", &"use_tool"]:
		assert_true(InputMap.has_action(action), "action manquante : %s" % action)


func test_movement_uses_physical_keys() -> void:
	InputSetupScript.register_defaults()
	var ev: InputEventKey = InputMap.action_get_events(&"move_forward")[0]
	assert_eq(ev.physical_keycode, KEY_W, "Z sur AZERTY = W physique :")
	assert_eq(ev.keycode, KEY_NONE)
