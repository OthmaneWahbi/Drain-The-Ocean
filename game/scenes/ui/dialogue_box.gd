class_name DialogueBox
extends CanvasLayer
## Les sous-titres et les réponses quand on parle au téléphone de la cabine (0.1.2).
## Une bande « page de catalogue » en bas de l'écran : le nom de l'interlocuteur sur une étiquette
## rouge, la réplique qui s'écrit lettre par lettre, puis les réponses (clic, ou touches 1 à 4).
## E, Espace ou un clic : finir la réplique, puis passer à la suivante. Échap : raccrocher.
## Toute la conversation est dans DialogueLogic ; les actions (ouvrir le catalogue…) sont
## renvoyées à qui a lancé la conversation.

signal finished

const CHARS_PER_S := 48.0

var logic: DialogueLogic
var _handler: Callable
var _args: Array = []
var _root: Control
var _speaker: Label
var _text: Label
var _hint: Label
var _choices: VBoxContainer
var _shown := 0.0
var _opened_at := 0.0


func _ready() -> void:
	add_to_group(&"dialogue")
	layer = 12
	_build()
	_root.visible = false


func is_open() -> bool:
	return _root.visible


## Lance la conversation `conv`. `args` remplissent les %s des répliques ; `handler(action)`
## reçoit les actions des répliques et des réponses.
func start(conv: String, args: Array = [], handler: Callable = Callable()) -> bool:
	logic = DialogueLogic.new(GameState.dialogues)
	if not logic.start(conv):
		return false
	_args = args
	_handler = handler
	_root.visible = true
	_opened_at = Time.get_ticks_msec() / 1000.0
	GameState.ui_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_line()
	return true


## Raccroche : la conversation s'arrête là.
func hang_up() -> void:
	if logic:
		logic.end()
	_close()


func _close() -> void:
	if not _root.visible:
		return
	_root.visible = false
	GameState.ui_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	finished.emit()


func _show_line() -> void:
	_speaker.text = tr(logic.speaker())
	var line := tr(logic.text())
	if line.contains("%s") and not _args.is_empty():
		line = line % _args
	_text.text = line
	_text.visible_characters = 0
	_shown = 0.0
	for c in _choices.get_children():
		c.queue_free()
	_choices.visible = false
	_hint.visible = false


func _process(delta: float) -> void:
	if not _root.visible:
		return
	if _text.visible_characters >= 0 and _text.visible_characters < _text.get_total_character_count():
		_shown += delta * CHARS_PER_S
		_text.visible_characters = int(_shown)
	else:
		_text.visible_characters = -1
		_reveal_choices()


func _line_done() -> bool:
	return _text.visible_characters == -1


func _reveal_choices() -> void:
	if _choices.visible or _hint.visible:
		return
	var keys := logic.choices()
	if keys.is_empty():
		_hint.visible = true
		return
	for i in keys.size():
		var b := Button.new()
		b.text = "%d.  %s" % [i + 1, tr(keys[i])]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(pick.bind(i))
		_choices.add_child(b)
	_choices.visible = true


## Avance : finit d'écrire la réplique, ou passe à la suivante (si elle n'attend pas de réponse).
func next() -> void:
	if not _line_done():
		_text.visible_characters = -1
		return
	if not logic.choices().is_empty():
		return
	_run(logic.advance())


## Choisit la réponse `i`.
func pick(i: int) -> void:
	if not _line_done() or i >= logic.choices().size():
		return
	_run(logic.choose(i))


func _run(action: String) -> void:
	var still_talking := logic.is_active()
	if still_talking:
		_show_line()
	else:
		_close()
	if action != "" and _handler.is_valid():
		_handler.call(action)


func _unhandled_input(event: InputEvent) -> void:
	if not _root.visible:
		return
	# La touche qui a décroché ne doit pas sauter la première réplique.
	if Time.get_ticks_msec() / 1000.0 - _opened_at < 0.2:
		return
	if event.is_action_pressed(&"pause"):
		hang_up()
	elif event.is_action_pressed(&"interact") or event.is_action_pressed(&"jump"):
		next()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		next()
	else:
		for i in 4:
			if event.is_action_pressed(StringName("tool_%d" % (i + 1))):
				pick(i)
				break
		return
	get_viewport().set_input_as_handled()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiTheme.theme()
	add_child(_root)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -580.0
	panel.offset_right = 580.0
	panel.offset_top = -330.0
	panel.offset_bottom = -150.0
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.add_theme_stylebox_override("panel", UiTheme.paper(UiTheme.PAPER, UiTheme.INK, 16, 20))
	_root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	var tag := PanelContainer.new()
	var tag_box := StyleBoxFlat.new()
	tag_box.bg_color = UiTheme.RED
	tag_box.border_color = UiTheme.INK
	tag_box.set_border_width_all(3)
	tag_box.set_corner_radius_all(8)
	tag_box.content_margin_left = 12
	tag_box.content_margin_right = 12
	tag_box.content_margin_top = 2
	tag_box.content_margin_bottom = 4
	tag.add_theme_stylebox_override("panel", tag_box)
	head.add_child(tag)
	_speaker = Label.new()
	_speaker.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_speaker.add_theme_font_override("font", UiTheme.title_font())
	_speaker.add_theme_font_size_override("font_size", 26)
	_speaker.add_theme_color_override("font_color", UiTheme.PAPER)
	tag.add_child(_speaker)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	var hang := Label.new()
	hang.text = "DLG_HANG_UP_HINT"
	hang.theme_type_variation = "Fine"
	head.add_child(hang)
	_text = Label.new()
	_text.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(1110, 0)
	_text.add_theme_font_size_override("font_size", 28)
	box.add_child(_text)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 6)
	box.add_child(_choices)
	_hint = Label.new()
	_hint.text = "DLG_CONTINUE"
	_hint.theme_type_variation = "Fine"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(_hint)
