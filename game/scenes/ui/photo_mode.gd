class_name PhotoMode
extends Node
## Le mode photo (0.1.24, PRD §19.31). P (hors menus) met le jeu en pause, cache le HUD et
## détache une caméra libre à la place de celle du joueur : touches de déplacement pour voler,
## souris pour tourner, Maj pour aller vite, molette pour le champ de vision ; 1 à 4 changent le
## filtre (normal, sépia, noir et blanc, couleurs vives) ; clic : la photo (PNG dans
## `user://photos/`) ; P ou Échap : retour au jeu. Aucune règle du jeu ici.

const PHOTO_DIR := "user://photos"
const SPEED := 6.0
const FAST := 3.0
const FOV_MIN := 25.0
const FOV_MAX := 100.0
const FILTERS := ["PHOTO_FILTER_0", "PHOTO_FILTER_1", "PHOTO_FILTER_2", "PHOTO_FILTER_3"]

var active := false
var filter := 0
var _camera: Camera3D
var _previous: Camera3D
var _yaw := 0.0
var _pitch := 0.0
var _layer: CanvasLayer
var _tint: ColorRect
var _hint: Label
var _flash_t := 0.0
var _hidden: Array[CanvasLayer] = []
var _was_paused := false
var _head: Node3D  # la tête du joueur : cachée pendant la photo (outil en main au premier plan)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 26  # au-dessus du menu pause (25) : rien ne passe devant la photo
	_layer.visible = false
	add_child(_layer)
	_tint = ColorRect.new()
	_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = _filter_shader()
	_tint.material = mat
	_layer.add_child(_tint)
	_hint = Label.new()
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_top = -44.0
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", 6)
	_layer.add_child(_hint)


## Le filtre : un shader sur une image de l'écran. 0 normal, 1 sépia, 2 noir et blanc, 3 vif.
static func _filter_shader() -> Shader:
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform int mode = 0;
void fragment() {
	vec3 c = texture(screen, SCREEN_UV).rgb;
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	if (mode == 1) {
		c = vec3(g * 1.07, g * 0.88, g * 0.66) + vec3(0.06, 0.03, 0.0);
	} else if (mode == 2) {
		c = vec3(g);
	} else if (mode == 3) {
		c = mix(vec3(g), c, 1.6);
		c = (c - 0.5) * 1.12 + 0.5;
	}
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
"""
	return sh


## Le chemin d'une photo prise à l'instant `unix_ms` (nom triable, jamais deux fois le même).
static func photo_path(unix_ms: int) -> String:
	return "%s/photo_%d.png" % [PHOTO_DIR, unix_ms]


static func clamp_fov(fov: float) -> float:
	return clampf(fov, FOV_MIN, FOV_MAX)


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		if event.is_action_pressed(&"photo_mode") and can_enter():
			enter()
			get_viewport().set_input_as_handled()


## Pas de photo par-dessus un menu, le catalogue, la longue-vue ou la fin.
func can_enter() -> bool:
	if GameState.ui_open or GameState.placing or get_tree().paused or GameState.ending != null:
		return false
	var player := get_tree().get_first_node_in_group(&"player")
	return player != null and not bool(player.get("spying"))


func _input(event: InputEvent) -> void:
	if not active:
		return
	get_viewport().set_input_as_handled()  # rien n'arrive au jeu en pause
	if event.is_action_pressed(&"photo_mode") or event.is_action_pressed(&"pause"):
		leave()
	elif event is InputEventMouseMotion:
		var sens := Settings.data.mouse_sensitivity
		_yaw -= event.relative.x * sens
		_pitch = clampf(_pitch - event.relative.y * sens, deg_to_rad(-89.0), deg_to_rad(89.0))
	elif event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_camera.fov = clamp_fov(_camera.fov - 4.0)
			MOUSE_BUTTON_WHEEL_DOWN:
				_camera.fov = clamp_fov(_camera.fov + 4.0)
			MOUSE_BUTTON_LEFT:
				take_photo()
	elif (event is InputEventJoypadButton or event is InputEventJoypadMotion) and event.is_action_pressed(&"use_tool"):
		take_photo()  # 0.1.25 : à la manette, la gâchette droite
	elif event is InputEventKey and event.pressed and not event.echo:
		for i in FILTERS.size():
			if event.is_action_pressed(StringName("tool_%d" % (i + 1))):
				set_filter(i)


func enter() -> void:
	_previous = get_viewport().get_camera_3d()
	if _previous == null:
		return
	active = true
	_camera = Camera3D.new()
	_camera.fov = _previous.fov
	_camera.far = _previous.far
	(get_parent() as Node).add_child(_camera)
	_camera.global_transform = _previous.global_transform
	var e := _previous.global_basis.get_euler()
	_yaw = e.y
	_pitch = e.x
	_camera.current = true
	_was_paused = get_tree().paused
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_hidden.clear()
	for n in get_tree().root.find_children("*", "CanvasLayer", true, false):
		var cl := n as CanvasLayer
		if cl != _layer and cl.visible:
			cl.visible = false
			_hidden.append(cl)
	_layer.visible = true
	var player := get_tree().get_first_node_in_group(&"player")
	_head = player.get_node_or_null("Head") as Node3D if player else null
	if _head:
		_head.visible = false
	set_filter(0)


func leave() -> void:
	if not active:
		return
	active = false
	_layer.visible = false
	for cl in _hidden:
		if is_instance_valid(cl):
			cl.visible = true
	_hidden.clear()
	if is_instance_valid(_head):
		_head.visible = true
	if is_instance_valid(_previous):
		_previous.current = true
	_camera.queue_free()
	_camera = null
	get_tree().paused = _was_paused


func set_filter(i: int) -> void:
	filter = clampi(i, 0, FILTERS.size() - 1)
	(_tint.material as ShaderMaterial).set_shader_parameter("mode", filter)
	_tint.visible = filter != 0
	_show_hint()


func _show_hint() -> void:
	_hint.text = "%s · %s" % [tr(FILTERS[filter]), tr("PHOTO_HINT")]


## Prend la photo sans l'aide à l'écran, puis l'enregistre. Renvoie le chemin (ou "").
func take_photo() -> String:
	_hint.visible = false
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	_hint.visible = true
	DirAccess.make_dir_recursive_absolute(PHOTO_DIR)
	var path := photo_path(int(Time.get_unix_time_from_system() * 1000.0))
	if img == null or img.save_png(path) != OK:
		return ""
	_hint.text = tr("PHOTO_SAVED")
	_flash_t = 1.2
	return path


func _process(delta: float) -> void:
	if not active or _camera == null:
		return
	var look := Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
	_yaw -= look.x * GameState.config.stick_look_speed * delta
	_pitch = clampf(_pitch - look.y * GameState.config.stick_look_speed * delta, deg_to_rad(-89.0), deg_to_rad(89.0))
	_camera.rotation = Vector3(_pitch, _yaw, 0.0)
	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var up := 0.0
	if Input.is_action_pressed(&"jump"):
		up += 1.0
	if Input.is_action_pressed(&"dive"):
		up -= 1.0
	var dir := _camera.global_basis * Vector3(input.x, 0.0, input.y) + Vector3(0, up, 0)
	var speed := SPEED * (FAST if Input.is_action_pressed(&"sprint") else 1.0)
	_camera.global_position += dir * speed * delta
	if _flash_t > 0.0:
		_flash_t -= delta
		if _flash_t <= 0.0:
			_show_hint()
