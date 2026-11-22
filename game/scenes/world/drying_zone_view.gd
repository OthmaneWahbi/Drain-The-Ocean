extends StaticBody3D
## Vue 3D d'une zone de séchage. Ne contient aucune règle : elle lit le DryingLogic de sa zone
## et appelle GameState quand le joueur agit.
## Clic (l'outil, le seau) : verser dans la zone. Ce qui sèche s'entasse À CÔTÉ, un tas par
## matériau (sel, minéraux, minéraux rares), qu'on ramasse avec E : deux gestes, deux cibles.

var zone: Dictionary
var _water: Node3D
var _piles: Array[SaltPile] = []
var _water_min_y: float
var _water_max_y: float


func setup(p_zone: Dictionary) -> void:
	zone = p_zone
	position = zone.position
	_build(zone.kind)


func _build(kind: String) -> void:
	var model := Props.drying_zone(kind)
	add_child(model)
	_water = model.get_node("Water")
	_water_min_y = model.get_meta("water_min")
	_water_max_y = model.get_meta("water_max")
	match kind:
		"cuvette":
			add_child(Greybox.cylinder_collision(1.5, 0.3, Vector3(0, 0.15, 0)))
		"bache":
			add_child(Greybox.box_collision(Vector3(2.4, 0.25, 2.4), Vector3(0, 0.12, 0)))
		"bassin_bois":
			add_child(Greybox.box_collision(Vector3(4.0, 0.4, 3.0), Vector3(0, 0.2, 0)))
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
	var zone: Dictionary
	var resource: String = "sel"
	var _mesh: Node3D
	var _shape: CollisionShape3D

	func _ready() -> void:
		# 0.1.10 (remarque 9) : chaque tas est dans son petit bac en bois, toujours là (on voit où
		# tombera ce qui sèche), et le tas y grossit.
		add_child(Props.bin(0.84, 0.2))
		# Un vrai tas de ce qu'il contient (Props.pile), pas un cône de couleur (0.1.4).
		_mesh = Props.pile(resource, hash(resource) % 1000)
		_mesh.position.y = 0.03
		add_child(_mesh)
		_shape = Greybox.cylinder_collision(0.45, 0.5, Vector3(0, 0.25, 0))
		add_child(_shape)
		PhysicsLayers.make_walk_through(self)  # on le vise, on ne s'y coince pas
		GameState.salt_dropped.connect(_on_dropped)

	## 0.1.20 (juice) : le tas fait « pop » et un « +1 » monte et s'efface.
	var _pop := 0.0
	var _size := 0.0

	func _on_dropped(z: Dictionary, res: String, n: int) -> void:
		if z != zone or res != resource or not is_visible_in_tree():
			return
		_pop = 1.0
		var label := Label3D.new()
		label.text = "+%d" % n
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 48
		label.outline_size = 10
		label.modulate = Props.PILE_BASE.get(resource, Color.WHITE).lightened(0.3)
		label.position = Vector3(0, 0.6, 0)
		label.no_depth_test = false
		add_child(label)
		var tw := label.create_tween()
		tw.set_parallel(true)
		tw.tween_property(label, "position:y", 1.4, 0.9)
		tw.tween_property(label, "modulate:a", 0.0, 0.9)
		tw.chain().tween_callback(label.queue_free)

	func count() -> int:
		return int((zone.logic as DryingLogic).deposit.get(resource, 0))

	## Le gonflement du « pop » (0 à 0,15) selon ce qu'il reste de l'élan (1 → 0).
	static func pop_scale(left: float) -> float:
		return 0.15 * sin(clampf(left, 0.0, 1.0) * PI)

	func _process(delta: float) -> void:
		var amount := count()
		_mesh.visible = amount > 0
		_shape.disabled = amount <= 0
		# Plus il y a de sel, plus le tas est gros (jusqu'à ~20 unités).
		var s := clampf(0.35 + amount * 0.035, 0.35, 1.05)  # jamais plus large que le bac
		# 0.1.17 : le tas grossit (ou fond) en douceur au lieu de sauter d'un cran par unité.
		var cur := _size if _size > 0.01 else s
		var k := lerpf(cur, s, clampf(delta * 6.0, 0.0, 1.0))
		_size = k
		_pop = maxf(_pop - delta * 5.0, 0.0)
		var bump := 1.0 + pop_scale(_pop)
		_mesh.scale = Vector3(k * bump, k / bump, k * bump) if _pop > 0.0 else Vector3(k, k, k)

	func get_prompt(_player: Node) -> String:
		var amount := count()
		if amount <= 0:
			return ""
		var what := tr("RES_" + resource.to_upper())
		if not GameState.has_slot_for(resource):
			return tr("PROMPT_NO_SLOT") % what
		if GameState.carry_space(resource) <= 0:
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
