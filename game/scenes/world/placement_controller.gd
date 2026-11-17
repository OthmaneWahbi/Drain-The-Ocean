class_name PlacementController
extends Node3D
## Le mode déplacement (M-22) : viser un objet + G, il suit le regard case par case.
## Depuis 0.1.5, on voit au sol les CASES qu'il occupera (vert, ou rouge si c'est interdit),
## la grille autour, le contour des emprises voisines (blanc) et, en rouge, ce qui gêne.
## R : tourner d'un quart de tour. Clic : poser (GameState.move_item). G ou Échap : annuler,
## l'objet revient à sa place et à son orientation.
##
## Un objet qui sort d'une caisse (GameState.placement_requested) passe tout seul en mode
## déplacement ; s'il y en a plusieurs, ils passent l'un après l'autre. Annuler le laisse où il est.
##
## Ce nœud ne contient aucune règle : la validité vient de GameState.can_place / PlacementGrid.

## Distance maximale de visée pendant le déplacement (plus loin que la main).
const AIM_DISTANCE := 14.0
## Nombre de cases de grille dessinées autour de l'emprise de l'objet.
const GRID_MARGIN_CELLS := 3
## L'aperçu épouse le relief par carreaux de cette taille, et flotte un peu au-dessus du sol (m) :
## assez haut pour ne jamais se battre avec le sable (0.1.7), une couche au-dessus de l'autre.
const DRAPE_STEP := 0.25
const LIFT_FOOT := 0.06
const LIFT_FILL := 0.07
const LIFT_GRID := 0.08
const LIFT_LINE := 0.09
## Il faut viser au moins ça plus près d'une nouvelle case pour que l'objet y saute (m).
const HYSTERESIS_M := 0.15

const OK_COLOR := Color(0.3, 0.9, 0.35, 0.45)
const BLOCKED_COLOR := Color(0.95, 0.25, 0.2, 0.45)
## Les emprises voisines (bleu) et celles qui gênent (rouge) : un voile au sol et un contour.
const NEIGHBOR_COLOR := Color(0.2, 0.45, 0.95, 0.3)
const CONFLICT_COLOR := Color(1.0, 0.12, 0.08, 0.5)

## Objet déplacé (dictionnaire de GameState) et sa vue 3D, ou vide hors du mode.
var item: Dictionary = {}
var view: Node3D = null
var _target_pos: Vector3
var _rotation_deg: float = 0.0
var _shown_rotation: float = NAN
var _valid: bool = false
## Vrai si l'endroit visé est trop loin du joueur (0.1.6).
var _too_far: bool = false
## L'aperçu au sol (0.1.7) : UN maillage, quatre couches dessinées dans un ordre fixe (cases
## occupées, voiles des voisins, grille, contours). Il épouse le relief, un peu au-dessus du sol :
## avant, des dalles plates à 2-5 cm du sable se battaient avec lui et clignotaient.
var _overlay: MeshInstance3D
var _overlay_mesh: ImmediateMesh
var _foot_mat: StandardMaterial3D
var _fill_mat: StandardMaterial3D
var _grid_mat: StandardMaterial3D
var _line_mat: StandardMaterial3D
## Hauteur du sol sous l'objet déplacé (sur l'eau, une pompe : sa plateforme).
var _floor_y: float = -INF
## Objets sortis d'une caisse qui attendent leur tour.
var _queue: Array[Dictionary] = []
## Donne la vue 3D d'un objet de GameState (fourni par main.gd).
var view_for: Callable = func(_it: Dictionary) -> Node3D: return null


func _ready() -> void:
	_foot_mat = _overlay_material(1)
	_fill_mat = _overlay_material(2)
	_grid_mat = _overlay_material(3)
	_line_mat = _overlay_material(4)
	_line_mat.no_depth_test = true  # les contours restent visibles à travers les objets
	_overlay_mesh = ImmediateMesh.new()
	_overlay = MeshInstance3D.new()
	_overlay.mesh = _overlay_mesh
	_overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_overlay)
	_set_visuals(false)
	GameState.game_reset.connect(_on_reset)
	GameState.placement_requested.connect(request)


## Un matériau d'aperçu : sans lumière, transparent, couleur par sommet. `priority` fixe l'ordre
## de dessin des couches transparentes (sinon Godot les trie par distance, et elles s'inversent
## d'une image à l'autre quand la caméra bouge : encore du clignotement).
static func _overlay_material(priority: int) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.render_priority = priority
	return m


## Un objet vient d'arriver : on le déplace tout de suite, ou dès que le précédent est posé.
func request(p_item: Dictionary) -> void:
	_queue.append(p_item)


func _on_reset() -> void:
	_queue.clear()
	cancel()


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	if player == null:
		return
	if not GameState.placing:
		if _start_next_in_queue():
			return
		if Input.is_action_just_pressed(&"move_object") and not GameState.ui_open \
				and is_instance_valid(player.target) and player.target.has_method(&"get_movable"):
			start(player.target)
		return
	# L'objet a disparu entre-temps (nouvelle partie, chargement…) : on arrête.
	if not GameState.movable_items().has(item):
		cancel()
		return
	# Échap libère la souris : on annule aussi le déplacement.
	if Input.is_action_just_pressed(&"move_object") or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		cancel()
		player.prompt = ""
		return
	if Input.is_action_just_pressed(&"rotate_object"):
		_rotation_deg = PlacementGrid.wrap_deg(_rotation_deg + GameState.config.rotation_step_deg)
	_follow_aim(player)
	if _too_far:
		player.prompt = tr("PROMPT_PLACE_TOO_FAR")
	else:
		player.prompt = tr("PROMPT_PLACE") if _valid else tr("PROMPT_PLACE_BLOCKED")
	if Input.is_action_just_pressed(&"use_tool") and _valid:
		confirm()
		player.prompt = ""


## Lance le prochain objet en attente (s'il existe encore et que le joueur a la main).
func _start_next_in_queue() -> bool:
	if GameState.ui_open or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return false
	while not _queue.is_empty():
		var next: Dictionary = _queue.pop_front()
		if not GameState.movable_items().has(next):
			continue
		var v: Node3D = view_for.call(next)
		if v and is_instance_valid(v):
			start(v)
			return true
	return false


## Entre en mode déplacement pour la vue visée.
func start(p_view: Node3D) -> void:
	view = p_view
	item = view.get_movable()
	_target_pos = item.position
	_rotation_deg = GameState.item_rotation(item)
	GameState.placing = true
	_set_visuals(true)


## Pose l'objet sur la case visée (si elle est valide).
func confirm() -> bool:
	var ok := GameState.move_item(item, _target_pos, _rotation_deg)
	_finish()
	return ok


## Abandonne : l'objet revient où il était.
func cancel() -> void:
	if not GameState.placing:
		return
	_finish()


func _finish() -> void:
	if view and is_instance_valid(view) and not item.is_empty():
		view.position = item.position
		view.rotation_degrees.y = GameState.item_rotation(item)
	view = null
	item = {}
	GameState.placing = false
	_set_visuals(false)


## Suit le point visé, aligné sur la grille ; la vue elle-même sert d'aperçu.
func _follow_aim(player: Node) -> void:
	if view == null or not is_instance_valid(view):
		cancel()
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var from := cam.global_position
	var dir := -cam.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(from, from + dir * AIM_DISTANCE)
	# Le rayon ignore le joueur et TOUS les corps de l'objet déplacé (ses tas, par exemple) :
	# avant 0.1.7, il touchait un tas de la zone, l'objet sautait, puis revenait (clignotement).
	var exclude: Array[RID] = [player.get_rid()]
	exclude.append_array(bodies_of(view))
	query.exclude = exclude
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	var y := (item.position as Vector3).y
	var point: Vector3
	if not hit.is_empty():
		point = hit.position
	elif absf(dir.y) > 0.01 and (y - from.y) / dir.y > 0.0:
		point = from + dir * ((y - from.y) / dir.y)  # vers le plan du sol de l'objet
	else:
		return
	# Le point visé devient le centre de l'emprise, alignée sur la grille (avec son orientation).
	var kind := GameState.item_kind(item)
	var center_off := GameState.footprint_rect(kind, Vector3.ZERO, _rotation_deg).get_center()
	var aim := point - Vector3(center_off.x, 0.0, center_off.y)
	var candidate := GameState.snap_item(kind, aim, _rotation_deg)
	candidate.y = y
	# Un peu d'hystérésis : au ras d'une ligne de la grille, le balancement de la tête ne fait plus
	# sauter l'objet d'une case à l'autre à chaque image.
	if keep_target(_target_pos, candidate, aim, _rotation_deg == _shown_rotation):
		candidate = _target_pos
	_target_pos = candidate
	_shown_rotation = _rotation_deg
	view.position = _target_pos
	view.rotation_degrees.y = _rotation_deg
	show_footprint(_target_pos, _rotation_deg)


## Dessine au sol les cases que l'objet occupera en `pos`, la grille autour, le contour des
## emprises voisines et, en rouge, celles qui gênent. Public pour les captures et les tests.
func show_footprint(pos: Vector3, rotation_deg: float) -> void:
	var kind := GameState.item_kind(item)
	var rect := GameState.footprint_rect(kind, pos, rotation_deg)
	var conflicts := GameState.placement_conflicts(item, pos, rotation_deg)
	_too_far = not GameState.in_place_reach(item, pos, rotation_deg)
	_valid = GameState.can_place(item, pos, rotation_deg) and not _too_far
	_floor_y = pos.y if GameState.is_water_kind(kind) else -INF
	var cell: float = GameState.config.grid_cell_m
	var area := rect.grow(GRID_MARGIN_CELLS * cell)
	_overlay_mesh.clear_surfaces()
	# 1. Les cases occupées.
	_overlay_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _foot_mat)
	_drape_rect(rect, OK_COLOR if _valid else BLOCKED_COLOR, LIFT_FOOT)
	_overlay_mesh.surface_end()
	# 2. Les emprises voisines (bleu) et ce qui gêne (rouge), en voile…
	var shown: Array = []  # [forme, couleur]
	for b in GameState.blockers_for(item):
		var bad := conflicts.has(b)
		if bad or _near(b, area):
			shown.append([b, CONFLICT_COLOR if bad else NEIGHBOR_COLOR])
	if not shown.is_empty():
		_overlay_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _fill_mat)
		for sh in shown:
			if (sh[0] as Dictionary).has("rect"):
				_drape_rect(sh[0].rect, sh[1], LIFT_FILL)
			else:
				_drape_fan(_contour(sh[0]), sh[1], LIFT_FILL)
		_overlay_mesh.surface_end()
	# 3. La grille.
	_overlay_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _grid_mat)
	_draw_grid(area)
	_overlay_mesh.surface_end()
	# 4. Les contours, visibles à travers tout.
	if not shown.is_empty():
		_overlay_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _line_mat)
		for sh in shown:
			var pts: Array = _contour(sh[0])
			for i in pts.size():
				_drape_line(pts[i], pts[(i + 1) % pts.size()], Color(sh[1], 0.95), LIFT_LINE)
		_overlay_mesh.surface_end()


## Les corps physiques d'une vue et de tout ce qu'elle contient (le rayon de visée les ignore).
static func bodies_of(node: Node) -> Array[RID]:
	var out: Array[RID] = []
	if node is CollisionObject3D:
		out.append((node as CollisionObject3D).get_rid())
	for child in node.get_children():
		out.append_array(bodies_of(child))
	return out


## Vrai s'il faut garder la case actuelle plutôt que `candidate` : même orientation, et le point
## visé n'est pas nettement (HYSTERESIS_M) plus près du nouveau centre que de l'ancien.
static func keep_target(current: Vector3, candidate: Vector3, aim: Vector3, same_rotation: bool) -> bool:
	if not same_rotation or not current.is_finite() or current.is_equal_approx(candidate):
		return false
	var a := Vector2(aim.x, aim.z)
	var d_cur := a.distance_to(Vector2(current.x, current.z))
	var d_new := a.distance_to(Vector2(candidate.x, candidate.z))
	return d_cur < d_new + HYSTERESIS_M and d_cur < 1.0


## Hauteur de l'aperçu en (x, z) : sur le relief (ou sur l'eau, ou la plateforme d'une pompe),
## plus `lift`. Statique pour les tests : `terrain` donne `height(x, z)`.
static func draped_y(terrain: Object, water_y: float, floor_y: float, x: float, z: float, lift: float) -> float:
	return maxf(maxf(terrain.height(x, z), water_y), floor_y) + lift


func _y(x: float, z: float, lift: float) -> float:
	return draped_y(GameState.terrain, GameState.water_level_y(), _floor_y, x, z, lift)


## Un rectangle posé sur le relief, en carreaux de DRAPE_STEP (rentré de 2 cm sur chaque bord).
func _drape_rect(r: Rect2, color: Color, lift: float) -> void:
	r = r.grow(-0.02)
	_overlay_mesh.surface_set_color(color)
	var nx := maxi(ceili(r.size.x / DRAPE_STEP), 1)
	var nz := maxi(ceili(r.size.y / DRAPE_STEP), 1)
	for i in nx:
		for j in nz:
			var x0 := r.position.x + r.size.x * i / nx
			var x1 := r.position.x + r.size.x * (i + 1) / nx
			var z0 := r.position.y + r.size.y * j / nz
			var z1 := r.position.y + r.size.y * (j + 1) / nz
			var a := Vector3(x0, _y(x0, z0, lift), z0)
			var b := Vector3(x1, _y(x1, z0, lift), z0)
			var c := Vector3(x1, _y(x1, z1, lift), z1)
			var d := Vector3(x0, _y(x0, z1, lift), z1)
			for v in [a, b, c, a, c, d]:
				_overlay_mesh.surface_add_vertex(v)


## Un petit disque (joueur, palmier, tuyau…) posé sur le relief.
func _drape_fan(pts: Array, color: Color, lift: float) -> void:
	_overlay_mesh.surface_set_color(color)
	var c := Vector3.ZERO
	for p in pts:
		c += p
	c /= pts.size()
	c.y = _y(c.x, c.z, lift)
	for i in pts.size():
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % pts.size()]
		_overlay_mesh.surface_add_vertex(c)
		_overlay_mesh.surface_add_vertex(Vector3(a.x, _y(a.x, a.z, lift), a.z))
		_overlay_mesh.surface_add_vertex(Vector3(b.x, _y(b.x, b.z, lift), b.z))


## Un segment qui suit le relief (découpé en pas de DRAPE_STEP).
func _drape_line(a: Vector3, b: Vector3, color: Color, lift: float) -> void:
	_overlay_mesh.surface_set_color(color)
	var n := maxi(ceili(Vector2(b.x - a.x, b.z - a.z).length() / DRAPE_STEP), 1)
	for i in n:
		var p := a.lerp(b, float(i) / n)
		var q := a.lerp(b, float(i + 1) / n)
		_overlay_mesh.surface_add_vertex(Vector3(p.x, _y(p.x, p.z, lift), p.z))
		_overlay_mesh.surface_add_vertex(Vector3(q.x, _y(q.x, q.z, lift), q.z))


## Une emprise voisine à montrer : un rectangle qui touche la zone de grille, ou un petit
## obstacle fixe (palmier, rocher, noix de coco, tuyau) dedans. Le joueur n'est montré que s'il gêne.
func _near(shape: Dictionary, area: Rect2) -> bool:
	if shape.has("rect"):
		return area.intersects(shape.rect)
	var p: Vector3 = shape.position
	if Vector2(p.x, p.z).is_equal_approx(Vector2(GameState.player_position.x, GameState.player_position.z)):
		return false
	return area.has_point(Vector2(p.x, p.z))


## Le contour d'une forme (rectangle d'emprise, ou cercle : joueur, palmier, tuyau…), en X, Z
## (la hauteur vient ensuite du relief).
func _contour(shape: Dictionary) -> Array:
	var y := 0.0
	if shape.has("rect"):
		var r: Rect2 = shape.rect
		return [Vector3(r.position.x, y, r.position.y), Vector3(r.end.x, y, r.position.y),
			Vector3(r.end.x, y, r.end.y), Vector3(r.position.x, y, r.end.y)]
	var p: Vector3 = shape.position
	var radius := float(shape.radius)
	var pts := []
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(Vector3(p.x + cos(a) * radius, y, p.z + sin(a) * radius))
	return pts


## La grille : ses lignes passent par les BORDS des cases, sur toute la zone `area` (alignée).
func _draw_grid(area: Rect2) -> void:
	var cell: float = GameState.config.grid_cell_m
	var nx := roundi(area.size.x / cell)
	var nz := roundi(area.size.y / cell)
	var x0 := area.position.x
	var z0 := area.position.y
	var color := Color(0.15, 0.25, 0.35, 0.7)
	for i in nx + 1:
		_drape_line(Vector3(x0 + i * cell, 0, z0), Vector3(x0 + i * cell, 0, z0 + nz * cell), color, LIFT_GRID)
	for i in nz + 1:
		_drape_line(Vector3(x0, 0, z0 + i * cell), Vector3(x0 + nx * cell, 0, z0 + i * cell), color, LIFT_GRID)


func _set_visuals(on: bool) -> void:
	_overlay.visible = on
	if not on:
		_shown_rotation = NAN
