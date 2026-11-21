class_name ShovelTool
extends Node3D
## Travailler le sable à la pelle quand on la tient (0.1.10 ; 0.1.12 : du vrai sable).
##
## On vise le sable à portée de pelle. Une marque ronde, projetée sur le sable, montre où la
## pelletée sera prise ou posée : verte si on peut, rouge sinon (le texte d'aide dit pourquoi).
## - **Clic gauche** : creuser une pelletée (le sable va sur la pelle). Maintenu : une pelletée
##   toutes les `dig_repeat_s` secondes.
## - **Clic droit** : poser une pelletée du sable porté. Maintenu : pareil.
## - **Maj + clic gauche** (maintenu) : lisser. Le sable sous la pelle se rapproche de sa hauteur
##   moyenne : même hauteur, même volume, mais plus plat (demande d'Othmane, 0.1.12).
## - **Maj + clic droit maintenu** : niveler (la marque devient le carreau de 1 m) ; la première
##   case donne le niveau, chaque case survolée en gardant le clic est mise à ce niveau.
## Autour, le sable trop raide s'éboule (SandPhysics). Les règles sont dans GameState
## (scoop_reason, shovel_scoop, dig_reason, flatten_cell). L'animation est dans SandFx et TerrainView.

const OK_COLOR := Color(0.3, 0.95, 0.35, 0.9)
const BLOCKED_COLOR := Color(1.0, 0.25, 0.2, 0.9)

## Le sommet visé (pelletée) et la case visée (aplanir).
var target_vertex: Vector2i
var target_cell: Vector2i
var has_target: bool = false
## Le niveau d'aplanissement du glisser en cours (NAN hors glisser).
var drag_level := NAN
var _drag_t := 0.0
var _repeat_t := 0.0
var _last_cell := Vector2i(1 << 20, 0)
var _decal: Decal
var _round_tex: ImageTexture
var _square_tex: ImageTexture


func _ready() -> void:
	_round_tex = _mark_texture(true)
	_square_tex = _mark_texture(false)
	_decal = Decal.new()
	_decal.name = "ShovelMark"
	_decal.texture_albedo = _round_tex
	_decal.upper_fade = 0.2
	_decal.lower_fade = 0.2
	_decal.visible = false
	add_child(_decal)


## Une marque blanche (teintée par modulate) : un anneau, ou le contour d'un carreau.
static func _mark_texture(round: bool) -> ImageTexture:
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (x + 0.5) / n * 2.0 - 1.0
			var v := (y + 0.5) / n * 2.0 - 1.0
			var a := 0.0
			if round:
				var d := sqrt(u * u + v * v)
				a = clampf(1.0 - absf(d - 0.85) / 0.1, 0.0, 1.0) + (0.18 if d < 0.85 else 0.0)
			else:
				var d := maxf(absf(u), absf(v))
				a = clampf(1.0 - absf(d - 0.9) / 0.08, 0.0, 1.0) + (0.18 if d < 0.9 else 0.0)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(a, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	has_target = false
	if player == null or not _active():
		_decal.visible = false
		drag_level = NAN
		return
	var hit := _aim(player)
	if not Input.is_action_pressed(&"use_tool_alt"):
		drag_level = NAN
	_decal.visible = has_target
	if not has_target:
		player.prompt = tr("PROMPT_DIG_AIM")
		return
	_drag_t -= delta
	_repeat_t -= delta
	var shift := Input.is_key_pressed(KEY_SHIFT)
	var leveling := (shift and Input.is_action_pressed(&"use_tool_alt")) or not is_nan(drag_level)
	var c := GameState.config.grid_cell_m
	var reason: String
	if leveling:
		# Maj + clic droit maintenu : niveler au niveau de la première case (pour poser un objet).
		var level := drag_level if not is_nan(drag_level) else GameState.dig_snap(GameState.terrain.cell_mean(target_cell))
		var y := GameState.flatten_level(target_cell, level)
		reason = GameState.dig_reason(target_cell, y)
		_place_mark(Vector3((target_cell.x + 0.5) * c, y, (target_cell.y + 0.5) * c), c, _square_tex)
		if is_nan(drag_level):
			drag_level = level
			_last_cell = Vector2i(1 << 20, 0)
		if target_cell != _last_cell and _drag_t <= 0.0:
			_last_cell = target_cell
			_drag_t = GameState.config.dig_drag_interval_s
			if reason == "":
				GameState.flatten_cell(target_cell, drag_level)
	elif shift:
		# Maj + clic gauche (maintenu) : lisser, à la même hauteur.
		reason = GameState.smooth_reason(target_vertex)
		_place_mark(hit, GameState.config.dig_brush_radius_m * 1.6, _round_tex)
		if Input.is_action_just_pressed(&"use_tool") or (Input.is_action_pressed(&"use_tool") and _repeat_t <= 0.0):
			_repeat_t = GameState.config.smooth_repeat_s
			if reason == "":
				GameState.smooth_sand(target_vertex)
	else:
		var dig := not Input.is_action_pressed(&"use_tool_alt")
		reason = GameState.scoop_reason(target_vertex, dig)
		_place_mark(hit, GameState.config.dig_brush_radius_m * 1.6, _round_tex)
		var pressed := Input.is_action_just_pressed(&"use_tool") or Input.is_action_just_pressed(&"use_tool_alt")
		var held := Input.is_action_pressed(&"use_tool") or Input.is_action_pressed(&"use_tool_alt")
		if pressed or (held and _repeat_t <= 0.0):
			_repeat_t = GameState.config.dig_repeat_s
			if reason == "":
				GameState.shovel_scoop(target_vertex, dig)
	_decal.modulate = OK_COLOR if reason == "" else BLOCKED_COLOR
	player.prompt = tr("PROMPT_DIG") % [load_text(GameState.shovel_sand), GameState.config.shovel_capacity_scoops] if reason == "" else tr(reason)


func _place_mark(at: Vector3, size: float, tex: Texture2D) -> void:
	_decal.texture_albedo = tex
	_decal.size = Vector3(size, 1.2, size)
	_decal.global_position = at


## La charge de la pelle, en pelletées, au dixième (« 2 », « 1,5 »).
static func load_text(scoops: float) -> String:
	var s := snappedf(scoops, 0.1)
	if is_equal_approx(s, roundf(s)):
		return str(roundi(s))
	return ("%.1f" % s).replace(".", ",") if TranslationServer.get_locale().begins_with("fr") else "%.1f" % s


func _active() -> bool:
	return GameState.current_tool() == "pelle" and not GameState.placing and not GameState.ui_open \
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


## Trouve le point de sable visé (on ne vise que le terrain, à portée de pelle).
func _aim(player: Node) -> Vector3:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return Vector3.ZERO
	var length: float = GameState.config.dig_reach_m + 2.0 + (player.spring_length() if player.third_person else 0.0)
	var from := cam.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from - cam.global_transform.basis.z * length)
	query.exclude = [player.get_rid()]
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or not (hit.collider is TerrainView):
		return Vector3.ZERO
	var p: Vector3 = hit.position
	if Vector2(p.x - player.global_position.x, p.z - player.global_position.z).length() > GameState.config.dig_reach_m:
		return Vector3.ZERO
	target_cell = cell_of_point(p, GameState.config.grid_cell_m)
	target_vertex = TerrainLogic.nearest_vertex(p.x, p.z)
	has_target = true
	var v := TerrainLogic.vertex_xz(target_vertex)
	return Vector3(v.x, p.y, v.y)


## La case qui contient ce point (statique, pour les tests).
static func cell_of_point(p: Vector3, cell_m: float) -> Vector2i:
	return Vector2i(floori(p.x / cell_m), floori(p.z / cell_m))
