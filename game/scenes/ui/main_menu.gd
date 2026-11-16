class_name MainMenu
extends CanvasLayer
## Le menu principal (M-71) : 3 emplacements de sauvegarde, les options, quitter.
## Tant qu'il est ouvert, le jeu est en pause (l'île figée derrière) et rien n'est sauvegardé.
## Chaque emplacement : Continuer, Nouvelle partie, Effacer. Le gros bouton « Nouvelle partie »
## prend le premier emplacement vide. Écraser ou effacer une partie demande toujours confirmation.

const HudScript := preload("res://scenes/ui/hud.gd")
const SLOTS := 3

var _root: Control
var _main_box: PanelContainer
var _options: OptionsPanel
var _slot_labels: Array[Label] = []
var _delete_buttons: Array[Button] = []
var _continue_buttons: Array[Button] = []
var _confirm_box: PanelContainer
var _confirm_label: Label
var _confirm_action: Callable


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
	_close_confirm()
	refresh()
	_root.visible = true


func is_open() -> bool:
	return _root.visible


## Reprend l'emplacement `slot` (ou y commence une partie) et rend la main au joueur.
func play(slot: int) -> void:
	_start(func(): GameState.play_slot(slot))


## « Nouvelle partie » sur un emplacement : tout de suite s'il est vide, sinon après confirmation.
func new_game(slot: int) -> void:
	if not SaveSystem.exists(slot, GameState.save_dir):
		_start(func(): GameState.new_game_in_slot(slot))
	else:
		ask(TranslationServer.translate("MENU_CONFIRM_OVERWRITE") % slot, func(): _start(func(): GameState.new_game_in_slot(slot)))


## Le gros bouton : premier emplacement vide ; s'ils sont tous pris, on propose d'écraser le plus ancien.
func new_game_anywhere() -> void:
	new_game(pick_new_game_slot())


## Premier emplacement vide, sinon celui dont la sauvegarde est la plus ancienne.
static func pick_new_game_slot(dir: String = SaveSystem.DEFAULT_DIR) -> int:
	var oldest := 1
	var oldest_t := INF
	for slot in range(1, SLOTS + 1):
		var sm := SaveSystem.summary(slot, dir)
		if sm.is_empty():
			return slot
		if float(sm.saved_at_unix) < oldest_t:
			oldest_t = float(sm.saved_at_unix)
			oldest = slot
	return oldest


func delete(slot: int) -> void:
	ask(TranslationServer.translate("MENU_CONFIRM_DELETE") % slot, func():
		GameState.delete_slot(slot)
		refresh())


## Une question Oui / Annuler à la place du menu.
func ask(question: String, on_yes: Callable) -> void:
	_confirm_label.text = question
	_confirm_action = on_yes
	_confirm_box.visible = true
	_main_box.visible = false


func is_asking() -> bool:
	return _confirm_box.visible


func confirm() -> void:
	var action := _confirm_action
	_close_confirm()
	if action.is_valid():
		action.call()


func _close_confirm() -> void:
	_confirm_action = Callable()
	if _confirm_box:
		_confirm_box.visible = false
		_main_box.visible = not _options.visible


func _start(action: Callable) -> void:
	_root.visible = false
	get_tree().paused = false
	GameState.ui_open = false
	action.call()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func refresh() -> void:
	for i in SLOTS:
		var summary := SaveSystem.summary(i + 1)
		_slot_labels[i].text = slot_text(i + 1, summary)
		_delete_buttons[i].disabled = summary.is_empty()
		_continue_buttons[i].disabled = summary.is_empty()


## « Emplacement 2 — 01:12:30 · 3,40 k L · 2026-11-16 18:40 », ou « vide ».
static func slot_text(slot: int, summary: Dictionary) -> String:
	var head := TranslationServer.translate("MENU_SLOT") % slot
	if summary.is_empty():
		return "%s — %s" % [head, TranslationServer.translate("MENU_SLOT_EMPTY")]
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var date := Time.get_datetime_string_from_unix_time(int(summary.saved_at_unix) + bias, true).left(16)
	var text := "%s — %s · %s L · %s" % [head, HudScript.format_time(summary.play_time_s), HudScript.format_liters(summary.removed_l), date]
	if int(summary.get("finished_runs", 0)) > 0:
		text += " · ★ " + HudScript.format_time(summary.best_time_s)  # partie finie : meilleur temps
	return text


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
	box.add_child(UiTheme.banner("MENU_GAME_TITLE", 50))
	var sub := MenuStyle.title("MENU_SUBTITLE", 18)
	sub.theme_type_variation = "Fine"
	box.add_child(sub)
	var big_new := Button.new()
	big_new.text = "MENU_NEW_GAME"
	big_new.add_theme_font_size_override("font_size", 24)
	big_new.pressed.connect(new_game_anywhere)
	box.add_child(big_new)
	for i in SLOTS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		row.add_child(label)
		_slot_labels.append(label)
		var play_button := Button.new()
		play_button.text = "MENU_CONTINUE"
		play_button.pressed.connect(play.bind(i + 1))
		row.add_child(play_button)
		_continue_buttons.append(play_button)
		var new_button := Button.new()
		new_button.text = "MENU_NEW"
		new_button.pressed.connect(new_game.bind(i + 1))
		row.add_child(new_button)
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
	_build_confirm(stack)
	# Les textes des emplacements sont composés à la main : on les refait au changement de langue.
	Settings.events.changed.connect(func(): if _root.visible: refresh())


func _build_confirm(stack: Control) -> void:
	_confirm_box = PanelContainer.new()
	_confirm_box.add_theme_stylebox_override("panel", MenuStyle.panel())
	_confirm_box.custom_minimum_size = Vector2(460, 0)
	_confirm_box.visible = false
	stack.add_child(_confirm_box)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	_confirm_box.add_child(box)
	_confirm_label = MenuStyle.title("", 20)
	_confirm_label.theme_type_variation = ""
	_confirm_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_confirm_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	var yes := Button.new()
	yes.text = "MENU_YES"
	yes.pressed.connect(confirm)
	row.add_child(yes)
	var no := Button.new()
	no.text = "MENU_CANCEL"
	no.pressed.connect(_close_confirm)
	row.add_child(no)
	box.add_child(row)
