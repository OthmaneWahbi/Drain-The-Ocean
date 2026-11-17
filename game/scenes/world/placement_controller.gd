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
var _valid: bool = false
## Les cases occupées (une dalle verte ou rouge) et les contours des emprises voisines.
var _foot: MeshInstance3D
var _foot_mat: StandardMaterial3D
var _grid: MeshInstance3D
var _grid_mesh: ImmediateMesh
var _outlines: MeshInstance3D
var _outline_mesh: ImmediateMesh
var _fill_mat: StandardMaterial3D
var _line_mat: StandardMaterial3D
## Objets sortis d'une caisse qui attendent leur tour.
var _queue: Array[Dictionary] = []
## Donne la vue 3D d'un objet de GameState (fourni par main.gd).
var view_for: Callable = func(_it: Dictionary) -> Node3D: return null


func _ready() -> void:
	_foot_mat = StandardMaterial3D.new()
	_foot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_foot_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_foot = MeshInstance3D.new()
	_foot.mesh = BoxMesh.new()
	_foot.material_override = _foot_mat
	_foot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_foot)
	_outline_mesh = ImmediateMesh.new()
	_outlines = MeshInstance3D.new()
	_outlines.mesh = _outline_mesh
	_fill_mat = StandardMaterial3D.new()
	_fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fill_mat.vertex_color_use_as_albedo = true
	_fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_line_mat = _fill_mat.duplicate()
	_line_mat.no_depth_test = true  # les contours restent visibles à travers les objets
	_outlines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_outlines)
	_grid_mesh = ImmediateMesh.new()
	_grid = MeshInstance3D.new()
	_grid.mesh = _grid_mesh
	var grid_mat := StandardMaterial3D.new()
	grid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid_mat.albedo_color = Color(0.15, 0.25, 0.35, 0.7)
	_grid.material_override = grid_mat
	_grid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_grid)
	_set_visuals(false)
	GameState.game_reset.connect(_on_reset)
	GameState.placement_requested.connect(request)


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
				and player.target and player.target.has_method(&"get_movable"):
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
	query.exclude = [player.get_rid(), view.get_rid()]
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
	_target_pos = GameState.snap_item(kind, point - Vector3(center_off.x, 0.0, center_off.y), _rotation_deg)
	_target_pos.y = y
	view.position = _target_pos
	view.rotation_degrees.y = _rotation_deg
	show_footprint(_target_pos, _rotation_deg)


## Dessine au sol les cases que l'objet occupera en `pos`, la grille autour, le contour des
## emprises voisines et, en rouge, celles qui gênent. Public pour les captures et les tests.
func show_footprint(pos: Vector3, rotation_deg: float) -> void:
	var kind := GameState.item_kind(item)
	var rect := GameState.footprint_rect(kind, pos, rotation_deg)
	var conflicts := GameState.placement_conflicts(item, pos, rotation_deg)
	_valid = GameState.can_place(item, pos, rotation_deg)
	var y := pos.y + 0.04
	(_foot.mesh as BoxMesh).size = Vector3(rect.size.x - 0.04, 0.03, rect.size.y - 0.04)
	_foot.position = Vector3(rect.get_center().x, y, rect.get_center().y)
	_foot_mat.albedo_color = OK_COLOR if _valid else BLOCKED_COLOR
	var cell: float = GameState.config.grid_cell_m
	var area := rect.grow(GRID_MARGIN_CELLS * cell)
	_draw_grid(area, y + 0.01)
	var shown: Array = []  # [points du contour, couleur]
	for b in GameState.blockers_for(item):
		var bad := conflicts.has(b)
		if bad or _near(b, area):
			shown.append([_contour(b, y + 0.02), CONFLICT_COLOR if bad else NEIGHBOR_COLOR])
	_outline_mesh.clear_surfaces()
	if shown.is_empty():
		return
	# Le voile au sol (caché par les objets eux-mêmes)…
	_outline_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _fill_mat)
	for s in shown:
		var pts: Array = s[0]
		_outline_mesh.surface_set_color(s[1])
		for i in range(1, pts.size() - 1):
			_outline_mesh.surface_add_vertex(pts[0])
			_outline_mesh.surface_add_vertex(pts[i])
			_outline_mesh.surface_add_vertex(pts[i + 1])
	_outline_mesh.surface_end()
	# … et le contour, visible à travers tout.
	_outline_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _line_mat)
	for s in shown:
		var pts: Array = s[0]
		var c: Color = s[1]
		_outline_mesh.surface_set_color(Color(c, 0.95))
		for i in pts.size():
			_outline_mesh.surface_add_vertex(pts[i])
			_outline_mesh.surface_add_vertex(pts[(i + 1) % pts.size()])
	_outline_mesh.surface_end()


## Une emprise voisine à montrer : un rectangle qui touche la zone de grille, ou un petit
## obstacle fixe (palmier, rocher, noix de coco, tuyau) dedans. Le joueur n'est montré que s'il gêne.
func _near(shape: Dictionary, area: Rect2) -> bool:
	if shape.has("rect"):
		return area.intersects(shape.rect)
	var p: Vector3 = shape.position
	if Vector2(p.x, p.z).is_equal_approx(Vector2(GameState.player_position.x, GameState.player_position.z)):
		return false
	return area.has_point(Vector2(p.x, p.z))


## Le contour d'une forme (rectangle d'emprise, ou cercle : joueur, palmier, tuyau…), à plat.
func _contour(shape: Dictionary, y: float) -> Array:
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
func _draw_grid(area: Rect2, y: float) -> void:
	var cell: float = GameState.config.grid_cell_m
	var nx := roundi(area.size.x / cell)
	var nz := roundi(area.size.y / cell)
	var x0 := area.position.x
	var z0 := area.position.y
	_grid_mesh.clear_surfaces()
	_grid_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in nx + 1:
		_grid_mesh.surface_add_vertex(Vector3(x0 + i * cell, y, z0))
		_grid_mesh.surface_add_vertex(Vector3(x0 + i * cell, y, z0 + nz * cell))
	for i in nz + 1:
		_grid_mesh.surface_add_vertex(Vector3(x0, y, z0 + i * cell))
		_grid_mesh.surface_add_vertex(Vector3(x0 + nx * cell, y, z0 + i * cell))
	_grid_mesh.surface_end()


func _set_visuals(on: bool) -> void:
	_foot.visible = on
	_grid.visible = on
	_outlines.visible = on
