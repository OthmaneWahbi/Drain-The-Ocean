class_name PauseMenu
extends CanvasLayer

const HudScript := preload("res://scenes/ui/hud.gd")
## Le menu pause (Échap) : reprendre, sauvegarder, options, menu principal, quitter.
## Le jeu est vraiment en pause (le chronomètre s'arrête, PRD §11). Il ne s'ouvre pas par-dessus
## un autre menu (catalogue, barre d'outils…) : là, Échap ferme ce menu-là (M-74).

signal main_menu_requested

var _root: Control
var _main_box: PanelContainer
var _options: OptionsPanel
var _saved_label: Label
## « Mon île » : tout ce que le HUD n'affiche plus (palette, bras, seau, heure…), depuis 0.1.3.
var _info_label: Label


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause"):
		return
	if _root.visible:
		if _options.visible:
			_show_options(false)
		else:
			resume()
		get_viewport().set_input_as_handled()
	elif not GameState.ui_open and not get_tree().paused:
		open_menu()
		get_viewport().set_input_as_handled()


func open_menu() -> void:
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_saved_label.text = ""
	_info_label.text = island_report()
	_show_options(false)
	_root.visible = true


func is_open() -> bool:
	return _root.visible


func resume() -> void:
	_root.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func save_now() -> void:
	GameState.save_game()
	_saved_label.text = "PAUSE_SAVED"


## « Me débloquer » : retour sur la plage, puis on reprend (filet de sécurité anti-blocage).
func unstuck() -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	if player and player.has_method(&"rescue"):
		player.rescue()
	resume()


## Sauvegarde, puis rend la main au menu principal.
func to_main_menu() -> void:
	GameState.autosave()
	_root.visible = false
	main_menu_requested.emit()


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
	_root.add_child(MenuStyle.backdrop(0.45))
	var center := MenuStyle.centered()
	_root.add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	center.add_child(row)
	var stack := VBoxContainer.new()
	row.add_child(stack)
	_main_box = PanelContainer.new()
	_main_box.add_theme_stylebox_override("panel", MenuStyle.panel())
	_main_box.custom_minimum_size = Vector2(360, 0)
	stack.add_child(_main_box)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_main_box.add_child(box)
	box.add_child(UiTheme.banner("PAUSE_TITLE", 34))
	for entry in [["PAUSE_RESUME", resume], ["PAUSE_SAVE", save_now], ["MENU_OPTIONS", _show_options.bind(true)], ["PAUSE_UNSTUCK", unstuck], ["MENU_NEW_GAME", to_main_menu], ["PAUSE_MAIN_MENU", to_main_menu], ["MENU_QUIT", _quit]]:
		var b := Button.new()
		b.text = entry[0]
		b.pressed.connect(entry[1])
		box.add_child(b)
	_saved_label = MenuStyle.title("", 14)
	_saved_label.add_theme_color_override("font_color", UiTheme.GREEN)
	box.add_child(_saved_label)
	_options = OptionsPanel.new()
	_options.closed.connect(_show_options.bind(false))
	stack.add_child(_options)
	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", MenuStyle.panel())
	info.custom_minimum_size = Vector2(440, 0)
	info.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(info)
	var info_box := VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 10)
	info.add_child(info_box)
	info_box.add_child(UiTheme.banner("PAUSE_INFO_TITLE", 28))
	_info_label = Label.new()
	_info_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_label.custom_minimum_size = Vector2(400, 0)
	info_box.add_child(_info_label)


## Le bilan de l'île, en texte : océan, heure, temps de jeu, palette, bras, seau, faim et soif.
static func island_report(gs: Node = null) -> String:
	if gs == null:
		gs = GameState
	var t := func(k: String) -> String: return TranslationServer.translate(k)
	var h: float = gs.day.hour()
	var lines := [
		"%s : %.10f %%" % [t.call("HUD_OCEAN_REMAINING"), gs.ocean.remaining_ratio() * 100.0],
		"%s : %s L" % [t.call("HUD_REMOVED").capitalize(), HudScript.format_liters(gs.ocean.removed_l)],
		"%s : %02d:%02d · %s : %s" % [t.call("PAUSE_INFO_HOUR"), int(h), int(fmod(h, 1.0) * 60.0), t.call("HUD_PLAY_TIME"), HudScript.format_time(gs.play_time_s)],
		"%s : %s" % [t.call("HUD_STOCK"), CatalogueFormat.format_items(gs.stock, true)],
		"%s (%d/%d) : %s" % [t.call("HUD_CARRIED"), gs.carried_count(), gs.carry_capacity, CatalogueFormat.format_items(gs.carried)],
		t.call("HUD_BUCKET") % [gs.bucket.water_l, gs.bucket.capacity_l],
		t.call("PAUSE_INFO_NEEDS") % [int(round(gs.survival.food * 100.0)), int(round(gs.survival.water * 100.0))],
	]
	return "\n".join(lines)


func _quit() -> void:
	GameState.autosave()
	get_tree().quit()
