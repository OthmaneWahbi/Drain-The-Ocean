class_name EndingDirector
extends Node3D
## La mise en scène de la vraie fin (PRD §11, M-04). Toutes les règles et la minuterie sont dans
## GameState / EndingLogic ; ce nœud ne fait que montrer chaque phase :
## DRAIN la bonde et sa chaîne se découvrent · GURGLE le tourbillon avale l'océan ·
## WALK le petit personnage traverse le fond à sec · PLANE l'avion publicitaire passe avec sa
## banderole · TIME le temps de partie · CREDITS le générique. Clic : passer l'écran du temps
## ou le générique.

const DeliveryPlane := preload("res://scenes/world/delivery_plane.gd")
const HudScript := preload("res://scenes/ui/hud.gd")
const WATER := Color(0.15, 0.45, 0.6)

var _camera: Camera3D
var _scene: Node3D  # tout ce qui est créé pour la fin, effacé à la fin
var _whirl: Node3D
var _walker: Node3D
var _plane: Node3D
var _overlay: CanvasLayer
var _time_label: Label
var _credits: Label
var _walk_from := Vector3.ZERO


func _ready() -> void:
	GameState.ending_started.connect(_begin)
	GameState.ending_phase_changed.connect(_on_phase)
	GameState.run_finished.connect(_cleanup)
	GameState.game_reset.connect(_cleanup)


func is_playing() -> bool:
	return _scene != null


func _begin() -> void:
	_cleanup()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_scene = Node3D.new()
	add_child(_scene)
	var cfg := GameState.config
	var drain := cfg.drain_position
	# La bonde : un gros bouchon de baignoire, son anneau, et sa chaîne qui monte vers la surface.
	_scene.add_child(Greybox.cylinder(8.0, 0.3, Color(0.75, 0.77, 0.8), drain + Vector3(0, 0.15, 0), 32))
	_scene.add_child(Greybox.cylinder(6.0, 1.0, Color(0.25, 0.25, 0.28), drain + Vector3(0, 0.6, 0), 32))
	_scene.add_child(Greybox.cylinder(0.8, 0.8, Color(0.75, 0.77, 0.8), drain + Vector3(0, 1.4, 0), 12))
	for i in 14:
		var link := Greybox.box(Vector3(0.3, 0.7, 0.1), Color(0.7, 0.7, 0.72), drain + Vector3(0.45 * i, 1.8 + 0.06 * i, 0.55 * i))
		link.rotation_degrees.y = 90.0 * (i % 2)
		_scene.add_child(link)
	# Le tourbillon : des anneaux d'eau qui tournent (montrés au glouglou).
	_whirl = Node3D.new()
	_whirl.position = drain + Vector3(0, 2.0, 0)
	for i in 5:
		var ring := Greybox.cylinder(9.0 - i * 1.6, 0.08, WATER.lightened(i * 0.08), Vector3(0, -i * 0.25, 0), 24)
		ring.rotation_degrees.y = i * 13.0
		_whirl.add_child(ring)
	_whirl.visible = false
	_scene.add_child(_whirl)
	# La caméra de la fin : depuis le bord de l'île, vers la bonde.
	_camera = Camera3D.new()
	_camera.fov = 70.0
	_scene.add_child(_camera)
	_camera.look_at_from_position(drain + Vector3(10, 9, 26), drain + Vector3(0, 1, 0))
	_camera.current = true
	_build_overlay()


func _on_phase(phase: int) -> void:
	if _scene == null:
		return
	match phase:
		EndingLogic.Phase.GURGLE:
			_whirl.visible = true
		EndingLogic.Phase.WALK:
			_whirl.visible = false
			_build_walker()
		EndingLogic.Phase.PLANE:
			_fly_ad_plane()
		EndingLogic.Phase.TIME:
			_time_label.text = tr("ENDING_TIME") % HudScript.format_precise(GameState.play_time_s)
			_time_label.get_parent().visible = true
		EndingLogic.Phase.CREDITS:
			_time_label.get_parent().visible = false
			_credits.visible = true
			_credits.position.y = get_viewport().get_visible_rect().size.y


func _process(delta: float) -> void:
	if _scene == null or GameState.ending == null:
		return
	var e: EndingLogic = GameState.ending
	var t := e.progress()
	match e.phase:
		EndingLogic.Phase.GURGLE:
			_whirl.rotate_y(delta * (2.0 + 10.0 * t))
			_whirl.scale = Vector3.ONE * lerpf(1.0, 0.15, t)
			_whirl.position.y = GameState.water_level_y() + 0.05
		EndingLogic.Phase.WALK:
			_walker.position = _walk_from.lerp(_walk_from + Vector3(0, 0, -16), t)
			_walker.position.y = GameState.terrain.height(_walker.position.x, _walker.position.z) + absf(sin(t * 40.0)) * 0.06
			# Plan large en troisième personne : le petit personnage, le fond immense.
			_camera.look_at_from_position(_walker.position + Vector3(6, 4, 9), _walker.position + Vector3(0, 1, -4))
		EndingLogic.Phase.PLANE:
			if _plane:
				_camera.look_at_from_position(_walker.position + Vector3(4, 2, 7), _plane.global_position)
		EndingLogic.Phase.CREDITS:
			_credits.position.y -= delta * 70.0


func _unhandled_input(event: InputEvent) -> void:
	if _scene and event is InputEventMouseButton and event.pressed:
		GameState.skip_ending_screen()
		get_viewport().set_input_as_handled()


func _build_walker() -> void:
	_walker = Node3D.new()
	_walk_from = Vector3(2, -3.0, -40)
	_walker.add_child(Greybox.cylinder(0.3, 1.6, Color(0.95, 0.75, 0.3), Vector3(0, 0.8, 0), 10))
	_walker.add_child(Greybox.box(Vector3(0.3, 0.3, 0.3), Color(0.9, 0.75, 0.6), Vector3(0, 1.8, 0)))
	_walker.add_child(Greybox.cylinder(0.14, 0.26, Greybox.ROCK, Vector3(0.4, 0.7, 0), 10))  # son seau
	_walker.position = _walk_from
	_scene.add_child(_walker)


## L'avion de l'agence (même pilote, qui fait coucou), avec une banderole : il aurait pu juste appeler.
func _fly_ad_plane() -> void:
	_plane = DeliveryPlane.new()
	_scene.add_child(_plane)
	_plane.hide_hook()
	var banner := Node3D.new()
	banner.position = Vector3(0, 0, -36)
	banner.add_child(Greybox.box(Vector3(0.03, 0.03, 4.0), Color(0.3, 0.3, 0.3), Vector3(0, 0, 22.0)))
	banner.add_child(Greybox.box(Vector3(0.05, 1.8, 40.0), Color(0.97, 0.95, 0.88)))
	for side in [-1.0, 1.0]:
		var text := Label3D.new()
		text.text = tr("ENDING_BANNER")
		text.font_size = 96
		text.pixel_size = 0.0085
		text.modulate = Color(0.75, 0.1, 0.1)
		text.outline_size = 0
		text.double_sided = false  # chaque face a son texte, à l'endroit
		text.position = Vector3(0.05 * side, 0, 0)
		text.rotation_degrees.y = 90.0 * side
		banner.add_child(text)
	_plane.add_child(banner)
	var over := _walker.position if _walker else Vector3(0, -3, -40)
	var start := over + Vector3(-90, 14, 30)
	var end := over + Vector3(90, 16, -30)
	_plane.look_at_from_position(start, end)
	var tw := _plane.create_tween()
	tw.tween_property(_plane, "position", end, GameState.config.ending_durations.get("plane", 8.0))


func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = 28
	_scene.add_child(_overlay)
	var center := MenuStyle.centered()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MenuStyle.panel())
	panel.visible = false
	center.add_child(panel)
	_time_label = Label.new()
	_time_label.add_theme_font_size_override("font_size", 40)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(_time_label)
	_credits = Label.new()
	_credits.text = tr("ENDING_CREDITS")
	_credits.add_theme_font_size_override("font_size", 26)
	_credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_credits.add_theme_constant_override("outline_size", 6)
	_credits.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_credits.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_credits.visible = false
	_overlay.add_child(_credits)


func _cleanup() -> void:
	if _scene:
		_scene.queue_free()
	_scene = null
	_walker = null
	_plane = null
	var player := get_tree().get_first_node_in_group(&"player") if is_inside_tree() else null
	if player and player.has_method(&"_apply_view"):
		player._apply_view()  # on rend la caméra du joueur
