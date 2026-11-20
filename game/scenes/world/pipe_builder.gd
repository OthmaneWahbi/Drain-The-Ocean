class_name PipeBuilder
extends Node3D
## Poser les tuyaux à la main (T2) quand on tient les tuyaux (case 4 de la barre).
##
## On vise : le sol (pièce au niveau 0), le dessus d'un objet (pièce au-dessus), ou la face d'une
## pièce déjà posée (nouvelle pièce collée à cette face : à côté, au-dessus, en dessous). Un cube
## vert (possible) ou rouge (impossible) montre où ira la pièce. Clic = poser ; E sur une pièce =
## la reprendre (voir pipes_view.gd). Toutes les règles sont dans GameState.can_place_pipe().
##
## 0.1.10 (Othmane : « les tuyaux doivent mieux marcher ») :
## - clic maintenu en glissant : on pose toute une ligne droite, une pièce par case survolée, au
##   niveau de la première ;
## - clic droit sur une pièce : on la reprend (comme E) ;
## - le fantôme dit ce que fera la pièce : bleu si l'eau d'une pompe y passera, bleu vif avec un
##   texte si elle verse dans une zone.

const REACH := 6.0
const OK_COLOR := Color(0.3, 0.9, 0.35, 0.45)
const BLOCKED_COLOR := Color(0.95, 0.25, 0.2, 0.45)
const WET_COLOR := Color(0.3, 0.6, 1.0, 0.5)
const FEEDS_COLOR := Color(0.2, 0.8, 1.0, 0.65)

var target_cell: Vector3i
var has_target: bool = false
var valid: bool = false
var _ghost: MeshInstance3D
var _ghost_mat: StandardMaterial3D
## Le glisser en cours : le niveau de la première pièce (-1 hors glisser) et la dernière case.
var _drag_level := -1
var _last_cell := Vector3i(1 << 20, 0, 0)


func _ready() -> void:
	_ghost_mat = StandardMaterial3D.new()
	_ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.5
	_ghost.mesh = box
	_ghost.material_override = _ghost_mat
	_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ghost.visible = false
	add_child(_ghost)


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	has_target = false
	if player == null or not _active():
		_ghost.visible = false
		_drag_level = -1
		return
	_aim(player)
	_ghost.visible = has_target
	if not has_target:
		return
	# Pendant un glisser, on reste au niveau de la première pièce (une ligne bien droite).
	if _drag_level >= 0:
		target_cell.y = _drag_level
	valid = GameState.pipe_stock > 0 and GameState.can_place_pipe(target_cell)
	_ghost.position = PipeNetwork.cell_center(target_cell, GameState.config.grid_cell_m, GameState.config.ground_y)
	var preview := GameState.pipe_preview(target_cell) if valid else ""
	_ghost_mat.albedo_color = BLOCKED_COLOR if not valid else (FEEDS_COLOR if preview == "feeds" else (WET_COLOR if preview == "wet" else OK_COLOR))
	var text: String
	if GameState.pipe_stock <= 0:
		text = tr("PROMPT_PIPE_EMPTY")
	elif valid:
		text = tr("PROMPT_PIPE_PLACE") % GameState.pipe_stock
		if preview == "feeds":
			text = "%s · %s" % [text, tr("PROMPT_PIPE_FEEDS")]
		elif preview == "wet":
			text = "%s · %s" % [text, tr("PROMPT_PIPE_WET")]
	else:
		text = tr("PROMPT_PIPE_BLOCKED") % GameState.pipe_stock
	var aimed_piece: bool = is_instance_valid(player.target) and player.target.has_method(&"get_prompt") and "cell" in player.target
	if aimed_piece:
		text = "%s · %s" % [text, tr("PROMPT_PIPE_REMOVE")]
	player.prompt = text
	# Clic : poser ; maintenu en glissant : poser une ligne.
	if Input.is_action_just_pressed(&"use_tool"):
		_drag_level = target_cell.y
		_last_cell = Vector3i(1 << 20, 0, 0)
	if Input.is_action_pressed(&"use_tool") and target_cell != _last_cell:
		_last_cell = target_cell
		if valid:
			GameState.place_pipe(target_cell)
	if not Input.is_action_pressed(&"use_tool"):
		_drag_level = -1
	# Clic droit sur une pièce : la reprendre.
	if Input.is_action_just_pressed(&"use_tool_alt") and aimed_piece:
		GameState.remove_pipe(player.target.cell)


func _active() -> bool:
	return GameState.current_tool() == "tuyaux" and not GameState.placing and not GameState.ui_open \
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


## Trouve la case visée.
func _aim(player: Node) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var length: float = REACH + (player.spring_length() if player.third_person else 0.0)
	var from := cam.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from - cam.global_transform.basis.z * length)
	query.exclude = [player.get_rid()]
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	target_cell = cell_for_hit(hit.collider, hit.position, hit.normal, GameState.config.grid_cell_m, GameState.config.ground_y)
	has_target = true


## La case où irait une nouvelle pièce, selon ce qu'on vise (statique, pour les tests).
static func cell_for_hit(collider: Object, point: Vector3, normal: Vector3, cell_m: float, ground_y: float) -> Vector3i:
	if collider != null and "cell" in collider:
		return collider.cell + axis_of(normal)
	var p := point + normal * 0.05
	var c := PipeNetwork.cell_of(p, cell_m)
	if normal.y > 0.7:
		c.y = maxi(ceili((point.y - ground_y - 0.05) / cell_m), 0)  # sur le dessus d'un objet : au-dessus
	else:
		c.y = maxi(floori((p.y - ground_y) / cell_m), 0)
	return c


## La direction d'axe (±X, ±Y, ±Z) la plus proche d'une normale.
static func axis_of(n: Vector3) -> Vector3i:
	var a := n.abs()
	if a.x >= a.y and a.x >= a.z:
		return Vector3i(signi(int(signf(n.x))), 0, 0)
	if a.y >= a.z:
		return Vector3i(0, int(signf(n.y)), 0)
	return Vector3i(0, 0, int(signf(n.z)))
