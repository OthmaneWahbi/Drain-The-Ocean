class_name MarshView
extends StaticBody3D
## Vue d'un marais salant creusé (0.1.20, PRD §19.27). Aucune règle : elle lit le DryingLogic du
## marais et ses cases. L'eau est un plan par case, à la hauteur du remplissage ; une croûte de
## sel blanche apparaît au fond quand il y a un dépôt ; les tas sont au bord (GameState.piles).

const DryingZoneView := preload("res://scenes/world/drying_zone_view.gd")
const WATER_COLOR := Color(0.25, 0.6, 0.84, 0.85)
const CRUST_COLOR := Color(0.95, 0.95, 0.92)
## Hauteur d'eau d'un marais plein au-dessus de son fond (m).
const FULL_DEPTH := 0.22

var zone: Dictionary
var _cells: Node3D
var _waters: Array[MeshInstance3D] = []
var _crusts: Array[MeshInstance3D] = []
var _means: Array[float] = []
var _piles: Array[Node3D] = []
var _water_mat: StandardMaterial3D
var _crust_mat: StandardMaterial3D


func setup(p_zone: Dictionary) -> void:
	zone = p_zone
	PhysicsLayers.make_walk_through(self)  # on marche dans le trou ; on le vise pour verser
	_water_mat = StandardMaterial3D.new()
	_water_mat.albedo_color = WATER_COLOR
	_water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_water_mat.roughness = 0.1
	_water_mat.metallic_specular = 0.8
	_crust_mat = StandardMaterial3D.new()
	_crust_mat.albedo_color = CRUST_COLOR
	_crust_mat.roughness = 0.9
	GameState.item_moved.connect(_on_moved)
	_rebuild()


func _on_moved(item: Dictionary) -> void:
	if item == zone:
		_rebuild()


func _rebuild() -> void:
	position = zone.position
	for n in get_children():
		n.queue_free()
	_waters.clear()
	_crusts.clear()
	_means.clear()
	_piles.clear()
	var g: float = GameState.config.grid_cell_m
	var plane := PlaneMesh.new()
	plane.size = Vector2(g, g)
	for c: Vector2i in zone.cells:
		var mid := Vector3((c.x + 0.5) * g, 0.0, (c.y + 0.5) * g)
		var mean := GameState.terrain.cell_mean(c)
		_means.append(mean)
		var w := MeshInstance3D.new()
		w.mesh = plane
		w.material_override = _water_mat
		w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		w.position = mid - position
		add_child(w)
		_waters.append(w)
		var crust := MeshInstance3D.new()
		crust.mesh = plane
		crust.material_override = _crust_mat
		crust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		crust.position = mid - position + Vector3(0, mean - position.y + 0.04, 0)
		crust.scale = Vector3(0.85, 1, 0.85)
		add_child(crust)
		_crusts.append(crust)
		# De quoi viser le marais pour y verser (une dalle fine, au fond de la case).
		add_child(Greybox.box_collision(Vector3(g, 0.3, g), mid - position + Vector3(0, mean - position.y + 0.15, 0)))
	for resource: String in GameState.config.pile_slots:
		var pile := DryingZoneView.SaltPile.new()
		pile.zone = zone
		pile.resource = resource
		pile.position = (zone.piles.get(resource, position) as Vector3) - position
		add_child(pile)
		_piles.append(pile)


func _process(_delta: float) -> void:
	var logic: DryingLogic = zone.logic
	var surface := surface_y()
	for i in _waters.size():
		var w := _waters[i]
		w.visible = logic.water_l > 0.01 and surface > _means[i] + 0.01
		w.position.y = surface - position.y
	var crust := logic.has_deposit()
	for c in _crusts:
		c.visible = crust


## La hauteur de l'eau (m) : du fond à FULL_DEPTH au-dessus quand le marais est plein.
func surface_y() -> float:
	var logic: DryingLogic = zone.logic
	return float(zone.position.y) + 0.02 + logic.fill_ratio() * FULL_DEPTH


func get_prompt(_player: Node) -> String:
	var logic: DryingLogic = zone.logic
	var state := tr("MARSH_STATE") % [logic.water_l, logic.capacity_l]
	if GameState.marsh_loss(zone) > 0.0:
		state += " · " + tr("MARSH_LEAKS")
	if GameState.current_tool() == "seau" and not GameState.bucket.is_empty() and logic.free_space_l() > 0.0:
		return "%s · %s" % [tr("PROMPT_POUR"), state]
	if logic.free_space_l() <= 0.0:
		return "%s · %s" % [tr("ZONE_FULL"), state]
	return state


func use(_player: Node) -> void:
	var logic: DryingLogic = zone.logic
	if GameState.current_tool() == "seau" and not GameState.bucket.is_empty() and logic.free_space_l() > 0.0:
		GameState.pour_bucket_into(zone)
