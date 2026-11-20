class_name ShovelTool
extends Node3D
## Travailler le sable à la pelle (0.1.10, remarque 5 d'Othmane) quand on tient la pelle.
##
## On vise une case du sol (1 m, la même grille que le placement). Un carreau montre le niveau
## qu'aura la case : vert si on peut, rouge sinon (le texte d'aide dit pourquoi).
## - Clic gauche maintenu : aplanir. La première case cliquée donne le niveau, et chaque case
##   survolée en gardant le clic est mise à ce niveau (on « passe la pelle »).
## - Clic droit : creuser d'un cran. Maj + clic droit : remonter d'un cran.
## Toutes les règles (bornes, objets, eau) sont dans GameState (dig_target, dig_reason, work_cell).

const OK_COLOR := Color(0.3, 0.9, 0.35, 0.42)
const BLOCKED_COLOR := Color(0.95, 0.25, 0.2, 0.42)

var target_cell: Vector2i
var has_target: bool = false
## Le niveau d'aplanissement du glisser en cours (NAN hors glisser).
var drag_level := NAN
var _drag_t := 0.0
var _last_cell := Vector2i(1 << 20, 0)
var _ghost: MeshInstance3D
var _ghost_mat: StandardMaterial3D


func _ready() -> void:
	_ghost_mat = StandardMaterial3D.new()
	_ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ghost_mat.no_depth_test = false
	_ghost = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(GameState.config.grid_cell_m, 0.06, GameState.config.grid_cell_m)
	_ghost.mesh = box
	_ghost.material_override = _ghost_mat
	_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ghost.visible = false
	add_child(_ghost)


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	has_target = false
	if player == null or not _active():
		_ghost.visible = false
		drag_level = NAN
		return
	_aim(player)
	if not Input.is_action_pressed(&"use_tool"):
		drag_level = NAN
	_ghost.visible = has_target
	if not has_target:
		player.prompt = tr("PROMPT_DIG_AIM")
		return
	var raise := Input.is_key_pressed(KEY_SHIFT)
	var level := drag_level if not is_nan(drag_level) else GameState.dig_snap(GameState.terrain.cell_mean(target_cell))
	var y := GameState.dig_target(target_cell, GameState.Dig.FLATTEN, level)
	var reason := GameState.dig_reason(target_cell, y)
	var c := GameState.config.grid_cell_m
	_ghost.position = Vector3((target_cell.x + 0.5) * c, y + 0.03, (target_cell.y + 0.5) * c)
	_ghost_mat.albedo_color = OK_COLOR if reason == "" else BLOCKED_COLOR
	player.prompt = tr("PROMPT_DIG") if reason == "" else tr(reason)
	# Clic gauche : aplanir (le premier clic fixe le niveau, le glisser l'étend).
	_drag_t -= delta
	if Input.is_action_just_pressed(&"use_tool"):
		drag_level = level
		_last_cell = Vector2i(1 << 20, 0)
	if Input.is_action_pressed(&"use_tool") and target_cell != _last_cell and _drag_t <= 0.0:
		_last_cell = target_cell
		_drag_t = GameState.config.dig_drag_interval_s
		if reason == "":
			GameState.work_cell(target_cell, GameState.Dig.FLATTEN, drag_level)
	# Clic droit : creuser (ou remonter avec Maj), un cran par clic.
	if Input.is_action_just_pressed(&"use_tool_alt"):
		GameState.work_cell(target_cell, GameState.Dig.RAISE if raise else GameState.Dig.DIG)


func _active() -> bool:
	return GameState.current_tool() == "pelle" and not GameState.placing and not GameState.ui_open \
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


## Trouve la case de sable visée (on ne vise que le terrain, à portée de pelle).
func _aim(player: Node) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var length: float = GameState.config.dig_reach_m + 2.0 + (player.spring_length() if player.third_person else 0.0)
	var from := cam.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from - cam.global_transform.basis.z * length)
	query.exclude = [player.get_rid()]
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or not (hit.collider is TerrainView):
		return
	var p: Vector3 = hit.position
	if Vector2(p.x - player.global_position.x, p.z - player.global_position.z).length() > GameState.config.dig_reach_m:
		return
	target_cell = cell_of_point(p, GameState.config.grid_cell_m)
	has_target = true


## La case qui contient ce point (statique, pour les tests).
static func cell_of_point(p: Vector3, cell_m: float) -> Vector2i:
	return Vector2i(floori(p.x / cell_m), floori(p.z / cell_m))
