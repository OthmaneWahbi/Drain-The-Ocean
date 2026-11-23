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
	&"map": KEY_M,
}

## 0.1.25 : la manette (M-16, Steam Deck). Les boutons, en positions Xbox (A en bas, X à gauche).
const JOY_BUTTONS := {
	&"jump": JOY_BUTTON_A,
	&"interact": JOY_BUTTON_X,
	&"dive": JOY_BUTTON_B,
	&"toggle_view": JOY_BUTTON_Y,
	&"tool_prev": JOY_BUTTON_LEFT_SHOULDER,
	&"tool_next": JOY_BUTTON_RIGHT_SHOULDER,
	&"pause": JOY_BUTTON_START,
	&"map": JOY_BUTTON_BACK,
	&"sprint": JOY_BUTTON_LEFT_STICK,
	&"toolbar_menu": JOY_BUTTON_DPAD_UP,
	&"photo_mode": JOY_BUTTON_DPAD_DOWN,
	&"move_object": JOY_BUTTON_DPAD_LEFT,
	&"rotate_object": JOY_BUTTON_DPAD_RIGHT,
}

## Les sticks et les gâchettes : [axe, sens]. Stick gauche pour marcher, stick droit pour regarder,
## gâchette droite pour l'outil, gâchette gauche pour le geste secondaire.
const JOY_AXES := {
	&"move_left": [JOY_AXIS_LEFT_X, -1.0],
	&"move_right": [JOY_AXIS_LEFT_X, 1.0],
	&"move_forward": [JOY_AXIS_LEFT_Y, -1.0],
	&"move_back": [JOY_AXIS_LEFT_Y, 1.0],
	&"look_left": [JOY_AXIS_RIGHT_X, -1.0],
	&"look_right": [JOY_AXIS_RIGHT_X, 1.0],
	&"look_up": [JOY_AXIS_RIGHT_Y, -1.0],
	&"look_down": [JOY_AXIS_RIGHT_Y, 1.0],
	&"use_tool": [JOY_AXIS_TRIGGER_RIGHT, 1.0],
	&"use_tool_alt": [JOY_AXIS_TRIGGER_LEFT, 1.0],
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
	for action: StringName in JOY_BUTTONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var jb := InputEventJoypadButton.new()
		jb.button_index = JOY_BUTTONS[action]
		if not InputMap.action_has_event(action, jb):
			InputMap.action_add_event(action, jb)
	for action: StringName in JOY_AXES:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if String(action).begins_with("move_") or String(action).begins_with("look_"):
			InputMap.action_set_deadzone(action, 0.2)
		var ja := InputEventJoypadMotion.new()
		ja.axis = JOY_AXES[action][0]
		ja.axis_value = JOY_AXES[action][1]
		if not InputMap.action_has_event(action, ja):
			InputMap.action_add_event(action, ja)
