class_name MainMenu
extends CanvasLayer
## Le menu principal (M-71) : 3 emplacements de sauvegarde, les options, quitter.
## Tant qu'il est ouvert, le jeu est en pause (l'île tourne au ralenti derrière, figée) et rien
## n'est sauvegardé. Choisir un emplacement le reprend, ou y commence une partie neuve.

const HudScript := preload("res://scenes/ui/hud.gd")
const SLOTS := 3

var _root: Control
var _main_box: PanelContainer
var _options: OptionsPanel
var _slot_labels: Array[Label] = []
var _delete_buttons: Array[Button] = []


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false


func open_menu() -> void:
	GameState.autosave_enabled = false
	get_tree().paused = true
	GameState.ui_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_options(false)
	refresh()
	_root.visible = true


func is_open() -> bool:
	return _root.visible


## Reprend l'emplacement `slot` (ou y commence une partie) et rend la main au joueur.
func play(slot: int) -> void:
	_root.visible = false
	get_tree().paused = false
	GameState.ui_open = false
	GameState.play_slot(slot)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func delete(slot: int) -> void:
	GameState.delete_slot(slot)
	refresh()


func refresh() -> void:
	for i in SLOTS:
		var summary := SaveSystem.summary(i + 1)
		_slot_labels[i].text = slot_text(i + 1, summary)
		_delete_buttons[i].disabled = summary.is_empty()


## « Emplacement 2 — 01:12:30 · 3,40 k L · 2026-11-16 18:40 », ou « vide ».
static func slot_text(slot: int, summary: Dictionary) -> String:
	var head := TranslationServer.translate("MENU_SLOT") % slot
	if summary.is_empty():
		return "%s — %s" % [head, TranslationServer.translate("MENU_SLOT_EMPTY")]
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var date := Time.get_datetime_string_from_unix_time(int(summary.saved_at_unix) + bias, true).left(16)
	return "%s — %s · %s L · %s" % [head, HudScript.format_time(summary.play_time_s), HudScript.format_liters(summary.removed_l), date]


func _show_options(on: bool) -> void:
	_options.visible = on
	_main_box.visible = not on
	if on:
		_options.refresh()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = MenuStyle.theme()
	add_child(_root)
	_root.add_child(MenuStyle.backdrop(0.55))
	var center := MenuStyle.centered()
	_root.add_child(center)
	var stack := VBoxContainer.new()
	center.add_child(stack)
	_main_box = PanelContainer.new()
	_main_box.add_theme_stylebox_override("panel", MenuStyle.panel())
	_main_box.custom_minimum_size = Vector2(620, 0)
	stack.add_child(_main_box)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_main_box.add_child(box)
	box.add_child(MenuStyle.title("MENU_GAME_TITLE", 46))
	var sub := MenuStyle.title("MENU_SUBTITLE", 16)
	sub.modulate = Color(0.7, 0.85, 1.0)
	box.add_child(sub)
	for i in SLOTS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		row.add_child(label)
		_slot_labels.append(label)
		var play_button := Button.new()
		play_button.text = "MENU_PLAY"
		play_button.pressed.connect(play.bind(i + 1))
		row.add_child(play_button)
		var del := Button.new()
		del.text = "MENU_DELETE"
		del.pressed.connect(delete.bind(i + 1))
		row.add_child(del)
		_delete_buttons.append(del)
		box.add_child(row)
	var options := Button.new()
	options.text = "MENU_OPTIONS"
	options.pressed.connect(_show_options.bind(true))
	box.add_child(options)
	var quit := Button.new()
	quit.text = "MENU_QUIT"
	quit.pressed.connect(func(): get_tree().quit())
	box.add_child(quit)
	_options = OptionsPanel.new()
	_options.closed.connect(_show_options.bind(false))
	stack.add_child(_options)
	# Les textes des emplacements sont composés à la main : on les refait au changement de langue.
	Settings.changed.connect(func(): if _root.visible: refresh())
