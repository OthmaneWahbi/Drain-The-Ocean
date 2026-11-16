extends StaticBody3D
## Vue 3D d'une zone de séchage. Ne contient aucune règle : elle lit le DryingLogic de sa zone
## et appelle GameState quand le joueur agit.
## Clic (l'outil, le seau) : verser dans la zone. Ce qui sèche s'entasse À CÔTÉ, un tas par
## matériau (sel, minéraux, minéraux rares), qu'on ramasse avec E : deux gestes, deux cibles.

var zone: Dictionary
var _water: MeshInstance3D
var _piles: Array[SaltPile] = []
var _water_min_y: float
var _water_max_y: float


func setup(p_zone: Dictionary) -> void:
	zone = p_zone
	position = zone.position
	match zone.kind:
		"cuvette":
			_build_basin()
		"bache":
			_build_tarp()
		"bassin_bois":
			_build_wood_basin()


func _build_basin() -> void:
	# Cuvette : un anneau de rochers bas autour d'un creux.
	add_child(Greybox.cylinder(1.4, 0.06, Greybox.ROCK, Vector3(0, 0.03, 0)))
	for i in 10:
		var a := TAU * i / 10.0
		var rock := Greybox.box(Vector3(0.7, 0.35, 0.45), Greybox.ROCK, Vector3(cos(a) * 1.25, 0.17, sin(a) * 1.25))
		rock.rotation.y = -a
		add_child(rock)
	add_child(Greybox.cylinder_collision(1.4, 0.35, Vector3(0, 0.17, 0)))
	_water = Greybox.cylinder(1.08, 0.02, Greybox.WATER)
	_water_min_y = 0.07
	_water_max_y = 0.3
	add_child(_water)
	_add_pile()


func _build_tarp() -> void:
	# Bâche : un carré de toile avec un petit rebord.
	add_child(Greybox.box(Vector3(2.4, 0.04, 2.4), Greybox.TARP, Vector3(0, 0.02, 0)))
	for side in [Vector3(0, 0.1, 1.2), Vector3(0, 0.1, -1.2)]:
		add_child(Greybox.box(Vector3(2.4, 0.2, 0.08), Greybox.TARP, side))
	for side in [Vector3(1.2, 0.1, 0), Vector3(-1.2, 0.1, 0)]:
		add_child(Greybox.box(Vector3(0.08, 0.2, 2.4), Greybox.TARP, side))
	add_child(Greybox.box_collision(Vector3(2.4, 0.25, 2.4), Vector3(0, 0.12, 0)))
	_water = Greybox.box(Vector3(2.3, 0.02, 2.3), Greybox.WATER)
	_water_min_y = 0.05
	_water_max_y = 0.18
	add_child(_water)
	_add_pile()


func _build_wood_basin() -> void:
	# Bassin en bois : un grand bac rectangulaire à planches.
	var size := Vector2(4.0, 3.0)
	add_child(Greybox.box(Vector3(size.x, 0.06, size.y), Greybox.WOOD, Vector3(0, 0.03, 0)))
	for z in [size.y / 2.0, -size.y / 2.0]:
		add_child(Greybox.box(Vector3(size.x, 0.4, 0.1), Greybox.WOOD, Vector3(0, 0.2, z)))
	for x in [size.x / 2.0, -size.x / 2.0]:
		add_child(Greybox.box(Vector3(0.1, 0.4, size.y), Greybox.WOOD, Vector3(x, 0.2, 0)))
	add_child(Greybox.box_collision(Vector3(size.x, 0.4, size.y), Vector3(0, 0.2, 0)))
	_water = Greybox.box(Vector3(size.x - 0.2, 0.02, size.y - 0.2), Greybox.WATER)
	_water_min_y = 0.07
	_water_max_y = 0.36
	add_child(_water)
	_add_pile()


## Un tas par matériau, chacun sur sa propre case de la grille, dans l'emprise de la zone
## (GameState.pile_offset) : ils ne peuvent donc jamais tomber sur un autre objet.
func _add_pile() -> void:
	for resource: String in GameState.config.pile_slots:
		var pile := SaltPile.new()
		pile.zone = zone
		pile.resource = resource
		pile.position = GameState.pile_offset(zone, resource)
		add_child(pile)
		_piles.append(pile)


func _process(_delta: float) -> void:
	var logic: DryingLogic = zone.logic
	_water.visible = logic.water_l > 0.0
	_water.position.y = lerpf(_water_min_y, _water_max_y, logic.fill_ratio())


## Texte affiché quand le joueur vise la zone.
func get_prompt(_player: Node) -> String:
	var logic: DryingLogic = zone.logic
	var state := tr("ZONE_STATE") % [logic.water_l, logic.capacity_l]
	if GameState.current_tool() == "seau" and not GameState.bucket.is_empty() and logic.free_space_l() > 0.0:
		return "%s · %s" % [tr("PROMPT_POUR"), state]
	if logic.free_space_l() <= 0.0:
		return "%s · %s" % [tr("ZONE_FULL"), state]
	return state


## Clic gauche : verser si on a de l'eau et de la place.
func use(_player: Node) -> void:
	var logic: DryingLogic = zone.logic
	if GameState.current_tool() == "seau" and not GameState.bucket.is_empty() and logic.free_space_l() > 0.0:
		GameState.pour_bucket_into(zone)


## Le tas d'UN matériau à côté de la zone. Il grossit avec le dépôt ; E pour ramasser.
class SaltPile extends StaticBody3D:
	const COLORS := {
		"sel": Color(0.95, 0.95, 0.92),
		"mineraux": Color(0.55, 0.55, 0.6),
		"mineraux_rares": Color(0.6, 0.3, 0.85),
	}
	var zone: Dictionary
	var resource: String = "sel"
	var _mesh: MeshInstance3D
	var _shape: CollisionShape3D

	func _ready() -> void:
		_mesh = MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.04
		cone.bottom_radius = 0.45
		cone.height = 0.5
		cone.radial_segments = 10
		cone.material = Greybox.material(COLORS.get(resource, Greybox.SALT))
		_mesh.mesh = cone
		_mesh.position.y = 0.25
		add_child(_mesh)
		_shape = Greybox.cylinder_collision(0.45, 0.5, Vector3(0, 0.25, 0))
		add_child(_shape)

	func count() -> int:
		return int((zone.logic as DryingLogic).deposit.get(resource, 0))

	func _process(_delta: float) -> void:
		var amount := count()
		_mesh.visible = amount > 0
		_shape.disabled = amount <= 0
		# Plus il y a de sel, plus le tas est gros (jusqu'à ~20 unités).
		var s := clampf(0.35 + amount * 0.035, 0.35, 1.1)
		_mesh.scale = Vector3(s, s, s)
		_mesh.position.y = 0.25 * s

	func get_prompt(_player: Node) -> String:
		var amount := count()
		if amount <= 0:
			return ""
		var what := tr("RES_" + resource.to_upper())
		if not GameState.has_slot_for(resource):
			return tr("PROMPT_NO_SLOT") % what
		if GameState.carry_space() <= 0:
			return tr("PROMPT_HANDS_FULL")
		if GameState.current_tool() == "rateau":
			return tr("PROMPT_RAKE") % [what, amount]
		return tr("PROMPT_PILE") % [what, amount]

	func interact(_player: Node) -> void:
		GameState.harvest(zone, resource)

	## Clic avec le râteau en main : tout le tas d'un coup.
	func use(_player: Node) -> void:
		if GameState.current_tool() == "rateau":
			GameState.harvest(zone, resource)


## Ce que la touche G déplace (voir placement_controller.gd).
func get_movable() -> Dictionary:
	return zone
