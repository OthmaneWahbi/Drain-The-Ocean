extends CanvasLayer
## La fin de la démo (M-05) : quand le moulin-pompe a pompé tout seul, un GROS avion sombre passe
## au-dessus de l'île en portant des silhouettes de machines T3 (teaser), puis l'écran de fin
## s'affiche avec le bilan. « Continuer à jouer » le ferme : la partie continue normalement.

const HudScript := preload("res://scenes/ui/hud.gd")
const SHOW_AFTER_S := 6.0

var _panel: PanelContainer
var _text: Label


func _ready() -> void:
	layer = 20
	_build()
	_panel.visible = false
	GameState.demo_finished.connect(play)
	GameState.game_reset.connect(close)


func play() -> void:
	_fly_teaser_plane()
	get_tree().create_timer(SHOW_AFTER_S).timeout.connect(show_screen)


func show_screen() -> void:
	var drop := GameState.ocean.level_drop_m(GameState.config.ocean_surface_m2)
	_text.text = tr("DEMO_END_TEXT") % [HudScript.format_time(GameState.play_time_s), HudScript.format_liters(GameState.ocean.removed_l), WaterGauge.format_drop_mm(drop)]
	_panel.visible = true
	GameState.ui_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	if not _panel.visible:
		return
	_panel.visible = false
	GameState.ui_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func is_showing() -> bool:
	return _panel.visible


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(640, 300)
	_panel.position = Vector2(-320, -150)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.12, 0.96)
	style.set_corner_radius_all(10)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	_panel.add_child(box)
	var title := Label.new()
	title.text = tr("DEMO_END_TITLE")
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_text)
	var teaser := Label.new()
	teaser.text = tr("DEMO_END_TEASER")
	teaser.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	teaser.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	teaser.modulate = Color(1.0, 0.85, 0.5)
	box.add_child(teaser)
	var button := Button.new()
	button.text = tr("DEMO_END_CONTINUE")
	button.pressed.connect(close)
	box.add_child(button)


## Le gros avion du teaser : trois fois l'avion de l'agence, sombre, avec des silhouettes T3
## suspendues (une éolienne, un panneau solaire, une pompe à moteur).
func _fly_teaser_plane() -> void:
	var world := get_tree().current_scene
	if world == null or not (world is Node3D):
		return
	var plane := Node3D.new()
	var dark := Color(0.08, 0.08, 0.1)
	plane.add_child(Greybox.box(Vector3(2.7, 2.7, 12.0), dark))
	plane.add_child(Greybox.box(Vector3(20.0, 0.3, 3.0), dark, Vector3(0, 0.3, 0.6)))
	plane.add_child(Greybox.box(Vector3(0.3, 2.4, 1.8), dark, Vector3(0, 1.8, -5.4)))
	plane.add_child(Greybox.box(Vector3(0.6, 6.0, 0.6), dark, Vector3(-3, -4.5, 0)))  # mât d'éolienne
	plane.add_child(Greybox.box(Vector3(5.0, 0.3, 0.3), dark, Vector3(-3, -1.5, 0)))
	plane.add_child(Greybox.box(Vector3(3.0, 0.15, 2.0), dark, Vector3(0, -3.0, 2)))  # panneau solaire
	plane.add_child(Greybox.box(Vector3(1.5, 1.5, 2.0), dark, Vector3(3, -3.2, -1)))  # pompe à moteur
	world.add_child(plane)
	var start := Vector3(-260, 45, 40)
	var end := Vector3(260, 55, -40)
	plane.position = start
	plane.look_at_from_position(start, end)
	var t := plane.create_tween()
	t.tween_property(plane, "position", end, 12.0)
	t.tween_callback(plane.queue_free)
