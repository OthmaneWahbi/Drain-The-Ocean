extends CanvasLayer
## Le menu qui range la barre de 5 cases (Tab). On clique une case, puis une autre : elles
## s'échangent (GameState.swap_slots). Tab ou Échap referme. Ce nœud ne contient aucune règle.

const HudScript := preload("res://scenes/ui/hud.gd")

var _panel: PanelContainer
var _buttons: Array[Button] = []
## Case choisie en premier, ou -1.
var _picked: int = -1


func _ready() -> void:
	layer = 11
	_build()
	_panel.visible = false
	GameState.tool_changed.connect(_refresh)
	GameState.carried_changed.connect(_refresh)
	GameState.game_reset.connect(close_menu)


func is_open() -> bool:
	return _panel.visible


func open_menu() -> void:
	_picked = -1
	_panel.visible = true
	GameState.ui_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh()


func close_menu() -> void:
	if not _panel.visible:
		return
	_panel.visible = false
	_picked = -1
	GameState.ui_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if _panel.visible:
		if event.is_action_pressed(&"toolbar_menu") or event.is_action_pressed(&"pause"):
			close_menu()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"toolbar_menu") and not GameState.ui_open and not GameState.placing:
		open_menu()
		get_viewport().set_input_as_handled()


## Clic sur une case : la première est choisie, la seconde est échangée avec elle.
func click_slot(i: int) -> void:
	if _picked < 0:
		_picked = i
	elif _picked == i:
		_picked = -1
	else:
		GameState.swap_slots(_picked, i)
		_picked = -1
	_refresh()


func _build() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.17, 0.95)
	style.set_corner_radius_all(6)
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	var title := Label.new()
	title.text = tr("TOOLBAR_MENU_TITLE")
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	for i in GameState.toolbar.slots.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(110, 80)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(click_slot.bind(i))
		row.add_child(b)
		_buttons.append(b)
	var hint := Label.new()
	hint.text = tr("TOOLBAR_MENU_HINT")
	hint.add_theme_font_size_override("font_size", 13)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)


func _refresh() -> void:
	var tb := GameState.toolbar
	for i in _buttons.size():
		var entry: String = tb.slots[i] if i < tb.slots.size() else ""
		_buttons[i].text = "%d\n%s" % [i + 1, HudScript.slot_text(entry)]
		_buttons[i].modulate = Color(1.0, 0.85, 0.3) if i == _picked else Color.WHITE
