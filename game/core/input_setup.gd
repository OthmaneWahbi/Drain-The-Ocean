extends Node
## Déclare les actions de contrôle (autoload « InputSetup »).
## Les touches utilisent des codes PHYSIQUES : la touche « W » d'un clavier QWERTY
## est à la place du « Z » d'un AZERTY, donc ZQSD/WASD marchent sans réglage (M-15).

const KEY_BINDINGS := {
	&"move_forward": KEY_W,
	&"move_back": KEY_S,
	&"move_left": KEY_A,
	&"move_right": KEY_D,
	&"jump": KEY_SPACE,
	&"sprint": KEY_SHIFT,
	&"interact": KEY_E,
	&"toggle_view": KEY_V,
	&"move_object": KEY_G,
	&"rotate_object": KEY_R,
	&"pause": KEY_ESCAPE,
	&"tool_1": KEY_1,
	&"tool_2": KEY_2,
	&"tool_3": KEY_3,
	&"tool_4": KEY_4,
	&"tool_5": KEY_5,
	&"tool_6": KEY_6,
	&"toolbar_menu": KEY_TAB,
	&"dive": KEY_CTRL,
	&"photo_mode": KEY_P,
}

const MOUSE_BINDINGS := {
	&"use_tool": MOUSE_BUTTON_LEFT,
	&"use_tool_alt": MOUSE_BUTTON_RIGHT,
	&"tool_next": MOUSE_BUTTON_WHEEL_DOWN,
	&"tool_prev": MOUSE_BUTTON_WHEEL_UP,
}


func _enter_tree() -> void:
	register_defaults()


static func register_defaults() -> void:
	for action: StringName in KEY_BINDINGS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_BINDINGS[action]
		InputMap.action_add_event(action, ev)
	for action: StringName in MOUSE_BINDINGS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var mev := InputEventMouseButton.new()
		mev.button_index = MOUSE_BINDINGS[action]
		InputMap.action_add_event(action, mev)
