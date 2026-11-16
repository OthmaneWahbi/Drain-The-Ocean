extends StaticBody3D
## Vue 3D d'une zone de séchage. Ne contient aucune règle : elle lit le DryingLogic de sa zone
## et appelle GameState quand le joueur clique dessus.

var zone: Dictionary
var _water: MeshInstance3D
var _salt: MeshInstance3D
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
	_salt = Greybox.cylinder(1.0, 0.02, Greybox.SALT, Vector3(0, 0.07, 0))
	_water_min_y = 0.07
	_water_max_y = 0.3
	add_child(_water)
	add_child(_salt)


func _build_tarp() -> void:
	# Bâche : un carré de toile avec un petit rebord.
	add_child(Greybox.box(Vector3(2.4, 0.04, 2.4), Greybox.TARP, Vector3(0, 0.02, 0)))
	for side in [Vector3(0, 0.1, 1.2), Vector3(0, 0.1, -1.2)]:
		add_child(Greybox.box(Vector3(2.4, 0.2, 0.08), Greybox.TARP, side))
	for side in [Vector3(1.2, 0.1, 0), Vector3(-1.2, 0.1, 0)]:
		add_child(Greybox.box(Vector3(0.08, 0.2, 2.4), Greybox.TARP, side))
	add_child(Greybox.box_collision(Vector3(2.4, 0.25, 2.4), Vector3(0, 0.12, 0)))
	_water = Greybox.box(Vector3(2.3, 0.02, 2.3), Greybox.WATER)
	_salt = Greybox.box(Vector3(2.0, 0.02, 2.0), Greybox.SALT, Vector3(0, 0.05, 0))
	_water_min_y = 0.05
	_water_max_y = 0.18
	add_child(_water)
	add_child(_salt)


func _process(_delta: float) -> void:
	var logic: DryingLogic = zone.logic
	_water.visible = logic.water_l > 0.0
	_water.position.y = lerpf(_water_min_y, _water_max_y, logic.fill_ratio())
	# Plus il y a de sel, plus la tache blanche est grande.
	var amount := Economy.count(logic.deposit)
	_salt.visible = amount > 0
	var s := clampf(0.25 + amount * 0.08, 0.25, 1.0)
	_salt.scale = Vector3(s, 1, s)


## Texte affiché quand le joueur vise la zone.
func get_prompt(_player: Node) -> String:
	var logic: DryingLogic = zone.logic
	var state := tr("ZONE_STATE") % [logic.water_l, logic.capacity_l]
	if not GameState.bucket.is_empty() and logic.free_space_l() > 0.0:
		return "%s · %s" % [tr("PROMPT_POUR"), state]
	if logic.has_deposit():
		return "%s (%d) · %s" % [tr("PROMPT_HARVEST"), Economy.count(logic.deposit), state]
	if logic.free_space_l() <= 0.0:
		return "%s · %s" % [tr("ZONE_FULL"), state]
	return state


## Clic gauche : verser si on a de l'eau et de la place, sinon récolter.
func use(_player: Node) -> void:
	var logic: DryingLogic = zone.logic
	if not GameState.bucket.is_empty() and logic.free_space_l() > 0.0:
		GameState.pour_bucket_into(zone)
	elif logic.has_deposit():
		GameState.harvest(zone)
