class_name PauseMenu
extends CanvasLayer
## Le menu pause (Échap) : reprendre, sauvegarder, options, menu principal, quitter.
## Le jeu est vraiment en pause (le chronomètre s'arrête, PRD §11). Il ne s'ouvre pas par-dessus
## un autre menu (catalogue, barre d'outils…) : là, Échap ferme ce menu-là (M-74).

signal main_menu_requested

var _root: Control
var _main_box: PanelContainer
var _options: OptionsPanel
var _saved_label: Label


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
	var stack := VBoxContainer.new()
	center.add_child(stack)
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


func _quit() -> void:
	GameState.autosave()
	get_tree().quit()
