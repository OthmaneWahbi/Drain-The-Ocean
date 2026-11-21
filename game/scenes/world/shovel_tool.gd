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
## Cases nivelées au plus par image pendant un glisser (0.1.14).
const LEVEL_CELLS_PER_FRAME := 2
## Les raisons (« Pelle pleine »…) sont gardées ce temps-là tant que rien ne change (0.1.14 : les
## recalculer à chaque image coûtait ~0,6 ms).
const REASON_TTL_S := 0.2
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
## Les raisons [creuser, poser] de la pelletée visée cette image (vide hors pelletée).
var _both: Array = []
## Le cache des raisons : nom -> [clé, raison] ; vidé à chaque geste et toutes les REASON_TTL_S.
var _reasons := {}
var _reason_t := 0.0


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
	_reason_t -= delta
	if _reason_t <= 0.0:
		_reasons.clear()
		_reason_t = REASON_TTL_S
	var shift := Input.is_key_pressed(KEY_SHIFT)
	var leveling := (shift and Input.is_action_pressed(&"use_tool_alt")) or not is_nan(drag_level)
	var c := GameState.config.grid_cell_m
	var reason: String
	if leveling:
		# Maj + clic droit maintenu : niveler au niveau de la première case (pour poser un objet).
		var level := drag_level if not is_nan(drag_level) else GameState.dig_snap(GameState.terrain.cell_mean(target_cell))
		var y := GameState.flatten_level(target_cell, level)
		reason = _cached_reason("level", func() -> String: return GameState.dig_reason(target_cell, y))
		_place_mark(Vector3((target_cell.x + 0.5) * c, y, (target_cell.y + 0.5) * c), c, _square_tex)
		if is_nan(drag_level):
			drag_level = level
			_last_cell = Vector2i(1 << 20, 0)
		# 0.1.14 (« niveler plus vite ») : on nivelle aussi les cases entre la dernière et celle
		# visée (un glisser rapide n'en saute plus), au plus LEVEL_CELLS_PER_FRAME par image.
		if _drag_t <= 0.0 and _last_cell != target_cell:
			for _k in LEVEL_CELLS_PER_FRAME:
				if _last_cell == target_cell:
					break
				var next := target_cell if _last_cell.x >= 1 << 19 else step_toward(_last_cell, target_cell)
				_last_cell = next
				if GameState.dig_reason(next, GameState.flatten_level(next, drag_level)) == "":
					GameState.flatten_cell(next, drag_level)
					_reasons.clear()
			_drag_t = GameState.config.dig_drag_interval_s
	elif shift:
		# Maj + clic gauche (maintenu) : lisser, à la même hauteur.
		reason = _cached_reason("smooth", func() -> String: return GameState.smooth_reason(target_vertex))
		_place_mark(hit, GameState.config.dig_brush_radius_m * 1.6, _round_tex)
		if Input.is_action_just_pressed(&"use_tool") or (Input.is_action_pressed(&"use_tool") and _repeat_t <= 0.0):
			_repeat_t = GameState.config.smooth_repeat_s
			if reason == "":
				GameState.smooth_sand(target_vertex)
				_reasons.clear()
	else:
		var dig := not Input.is_action_pressed(&"use_tool_alt")
		# 0.1.13 : on dit pour les deux boutons ce qui est possible (avant, le texte et la marque
		# ne parlaient que de creuser : « Pelle pleine » en rouge alors que poser marchait).
		var dig_reason := _cached_reason("dig", func() -> String: return GameState.scoop_reason(target_vertex, true))
		var drop_reason := _cached_reason("drop", func() -> String: return GameState.scoop_reason(target_vertex, false))
		reason = dig_reason if dig else drop_reason
		_both = [dig_reason, drop_reason]
		_place_mark(hit, GameState.config.dig_brush_radius_m * 1.6, _round_tex)
		var pressed := Input.is_action_just_pressed(&"use_tool") or Input.is_action_just_pressed(&"use_tool_alt")
		var held := Input.is_action_pressed(&"use_tool") or Input.is_action_pressed(&"use_tool_alt")
		if pressed or (held and _repeat_t <= 0.0):
			_repeat_t = GameState.config.dig_repeat_s
			if reason == "":
				GameState.shovel_scoop(target_vertex, dig)
				_reasons.clear()
	if not _both.is_empty():
		# Pelletée : vert si l'un des deux boutons marche, et le texte dit pourquoi l'autre non.
		var ok: bool = _both[0] == "" or _both[1] == ""
		_decal.modulate = OK_COLOR if ok else BLOCKED_COLOR
		player.prompt = scoop_prompt(_both[0], _both[1])
		_both = []
		return
	_decal.modulate = OK_COLOR if reason == "" else BLOCKED_COLOR
	player.prompt = tr("PROMPT_DIG") % [load_text(GameState.shovel_sand), GameState.config.shovel_capacity_scoops] if reason == "" else tr(reason)


## Une raison gardée tant que la cible, la charge et le mode ne changent pas (voir REASON_TTL_S).
func _cached_reason(mode: String, compute: Callable) -> String:
	var key := [target_vertex, target_cell, GameState.shovel_sand, -999.0 if is_nan(drag_level) else drag_level]
	var hit: Array = _reasons.get(mode, [])
	if not hit.is_empty() and hit[0] == key:
		return hit[1]
	var r: String = compute.call()
	_reasons[mode] = [key, r]
	return r


## Un pas d'une case vers `to` (en ligne droite, diagonales comprises).
static func step_toward(from: Vector2i, to: Vector2i) -> Vector2i:
	return from + Vector2i(signi(to.x - from.x), signi(to.y - from.y))


## Le texte d'aide de la pelletée : les gestes, la charge, et ce qui empêche creuser ou poser.
static func scoop_prompt(dig_reason: String, drop_reason: String) -> String:
	var t := TranslationServer.translate("PROMPT_DIG") % [load_text(GameState.shovel_sand), GameState.config.shovel_capacity_scoops]
	if dig_reason != "" and dig_reason == drop_reason:
		return TranslationServer.translate(dig_reason)
	if dig_reason != "":
		t += " · " + TranslationServer.translate(dig_reason)
	if drop_reason != "":
		t += " · " + TranslationServer.translate(drop_reason)
	return t


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
	var exclude: Array[RID] = [player.get_rid()]
	var hit: Dictionary = {}
	# 0.1.13 : un coquillage, une noix de coco ou un objet devant le sable ne cache plus le sable
	# (on visait « rien » et la pelle refusait sans raison claire) : on regarde à travers.
	for _try in 6:
		query.exclude = exclude
		hit = player.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or hit.collider is TerrainView:
			break
		exclude.append(hit.rid)
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
