class_name PlacementController
extends Node3D
## Le mode déplacement (M-22) : viser un objet + G, il suit le regard case par case,
## un disque vert (ou rouge si c'est interdit) montre son emprise et la grille s'affiche autour.
## R : tourner d'un quart de tour. Clic : poser (GameState.move_item). G ou Échap : annuler,
## l'objet revient à sa place et à son orientation.
##
## Ce nœud ne contient aucune règle : la validité vient de GameState.can_place / PlacementGrid.

## Distance maximale de visée pendant le déplacement (plus loin que la main).
const AIM_DISTANCE := 14.0
## Nombre de cases dessinées de chaque côté de l'objet.
const GRID_HALF_CELLS := 4

const OK_COLOR := Color(0.3, 0.9, 0.35, 0.45)
const BLOCKED_COLOR := Color(0.95, 0.25, 0.2, 0.45)

## Objet déplacé (dictionnaire de GameState) et sa vue 3D, ou vide hors du mode.
var item: Dictionary = {}
var view: Node3D = null
var _target_pos: Vector3
var _rotation_deg: float = 0.0
var _valid: bool = false
var _disk: MeshInstance3D
var _disk_mat: StandardMaterial3D
var _grid: MeshInstance3D
var _grid_mesh: ImmediateMesh


func _ready() -> void:
	_disk_mat = StandardMaterial3D.new()
	_disk_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_disk_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_disk = MeshInstance3D.new()
	_disk.mesh = CylinderMesh.new()
	_disk.material_override = _disk_mat
	_disk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_disk)
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
	GameState.game_reset.connect(cancel)


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	if player == null:
		return
	if not GameState.placing:
		if Input.is_action_just_pressed(&"move_object") and not GameState.ui_open \
				and player.target and player.target.has_method(&"get_movable"):
			start(player.target)
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


## Entre en mode déplacement pour la vue visée.
func start(p_view: Node3D) -> void:
	view = p_view
	item = view.get_movable()
	_target_pos = item.position
	_rotation_deg = GameState.item_rotation(item)
	GameState.placing = true
	var r := GameState.footprint(item)
	var cyl := _disk.mesh as CylinderMesh
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = 0.04
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
	_target_pos = PlacementGrid.snap(point, GameState.config.grid_cell_m)
	_target_pos.y = y
	_valid = GameState.can_place(item, _target_pos)
	view.position = _target_pos
	view.rotation_degrees.y = _rotation_deg
	_disk.position = _target_pos + Vector3(0, 0.03, 0)
	_disk_mat.albedo_color = OK_COLOR if _valid else BLOCKED_COLOR
	_draw_grid(_target_pos)


func _draw_grid(center: Vector3) -> void:
	var cell: float = GameState.config.grid_cell_m
	var half := GRID_HALF_CELLS * cell
	# Les lignes de la grille passent par les BORDS des cases ; `center` est un centre de case.
	var x0 := center.x - cell / 2.0 - half
	var z0 := center.z - cell / 2.0 - half
	var y := center.y + 0.05
	var n := GRID_HALF_CELLS * 2 + 1
	_grid_mesh.clear_surfaces()
	_grid_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in n + 1:
		_grid_mesh.surface_add_vertex(Vector3(x0 + i * cell, y, z0))
		_grid_mesh.surface_add_vertex(Vector3(x0 + i * cell, y, z0 + n * cell))
		_grid_mesh.surface_add_vertex(Vector3(x0, y, z0 + i * cell))
		_grid_mesh.surface_add_vertex(Vector3(x0 + n * cell, y, z0 + i * cell))
	_grid_mesh.surface_end()


func _set_visuals(on: bool) -> void:
	_disk.visible = on
	_grid.visible = on
