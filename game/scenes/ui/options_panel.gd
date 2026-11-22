class_name OptionsPanel
extends PanelContainer
## Le panneau des options (M-21, M-72, M-73), partagé par le menu principal et le menu pause.
## Chaque réglage écrit directement dans l'autoload Settings, qui l'applique et l'enregistre.
## Les textes sont des clés de traduction : ils changent tout seuls quand on change de langue.

signal closed

var _rows: Dictionary = {}  # clé d'option -> contrôle (pour les tests et le rafraîchissement)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_theme_stylebox_override("panel", MenuStyle.panel())
	custom_minimum_size = Vector2(520, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	box.add_child(UiTheme.banner("OPTIONS_TITLE", 30))
	_slider(box, "fov", "OPTIONS_FOV", 60.0, 110.0, 1.0)
	_slider(box, "mouse_sensitivity", "OPTIONS_SENSITIVITY", 0.0005, 0.008, 0.0001)
	_slider(box, "volume", "OPTIONS_VOLUME", 0.0, 1.0, 0.05)
	_slider(box, "music_volume", "OPTIONS_MUSIC", 0.0, 1.0, 0.05)
	_check(box, "head_bob", "OPTIONS_HEAD_BOB")
	_check(box, "fullscreen", "OPTIONS_FULLSCREEN")
	_check(box, "show_timer", "OPTIONS_TIMER")
	var lang_row := HBoxContainer.new()
	var lang_label := Label.new()
	lang_label.text = "OPTIONS_LANGUAGE"
	lang_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lang_row.add_child(lang_label)
	var lang := OptionButton.new()
	lang.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	for code in SettingsLogic.LANGUAGES:
		lang.add_item({"fr": "Français", "en": "English"}.get(code, code))
	lang.item_selected.connect(func(i: int): Settings.set_value("language", SettingsLogic.LANGUAGES[i]))
	lang_row.add_child(lang)
	box.add_child(lang_row)
	_rows["language"] = lang
	var back := Button.new()
	back.text = "MENU_BACK"
	back.pressed.connect(func(): closed.emit())
	box.add_child(back)
	refresh()


## Remet chaque contrôle sur la valeur actuelle des options.
func refresh() -> void:
	var d := Settings.data.to_dict()
	for key in _rows:
		var c: Control = _rows[key]
		if c is Slider:
			(c as Slider).set_value_no_signal(float(d[key]))
		elif c is CheckBox:
			(c as CheckBox).set_pressed_no_signal(bool(d[key]))
		elif c is OptionButton:
			(c as OptionButton).select(maxi(SettingsLogic.LANGUAGES.find(d[key]), 0))


func control_for(key: String) -> Control:
	return _rows.get(key)


func _slider(box: VBoxContainer, key: String, label_key: String, lo: float, hi: float, step: float) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_key
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = lo
	slider.max_value = hi
	slider.step = step
	slider.custom_minimum_size = Vector2(220, 0)
	slider.value_changed.connect(func(v: float): Settings.set_value(key, v))
	row.add_child(slider)
	box.add_child(row)
	_rows[key] = slider


func _check(box: VBoxContainer, key: String, label_key: String) -> void:
	var check := CheckBox.new()
	check.text = label_key
	check.toggled.connect(func(on: bool): Settings.set_value(key, on))
	box.add_child(check)
	_rows[key] = check
