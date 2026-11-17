class_name IslandProps
extends Node3D
## Les éléments fixes de l'île (0.1.2) : palmiers (avec leurs noix de coco), rochers, buissons
## sur les dunes, bois flotté sur les plages. Modèles CC0 retouchés (Models). Les positions des
## palmiers et rochers viennent de GameConfig ; le décor des dunes est tiré au hasard, toujours
## le même (graine fixe), et seulement hors de la zone constructible.

var palms: Array[Node3D] = []


func _ready() -> void:
	var cfg := GameState.config
	var terrain := GameState.terrain
	for i in cfg.palms.size():
		var p := cfg.palms[i]
		_add_palm(Vector3(p.x, terrain.height(p.x, p.y), p.y), p.z, i)
	for i in cfg.outer_palms.size():
		var p := cfg.outer_palms[i]
		var y := terrain.height(p.x, p.y)
		if y > 0.15:  # jamais dans l'eau
			_add_palm(Vector3(p.x, y, p.y), p.z, cfg.palms.size() + i)
	for r in cfg.rocks:
		_add_rock(Vector3(r.x, terrain.height(r.x, r.y), r.y), r.z)
	_scatter(cfg.dune_bushes, cfg.driftwood)
	_scatter_small(cfg.dune_flowers, cfg.beach_shells)


## Le palmier le plus proche de `pos` (pour les traits des réveils).
func palm_near(pos: Vector3) -> Node3D:
	var best: Node3D = null
	for p in palms:
		if best == null or p.global_position.distance_to(pos) < best.global_position.distance_to(pos):
			best = p
	return best


func _add_palm(pos: Vector3, height: float, index: int) -> void:
	var body := StaticBody3D.new()
	body.name = "Palm%d" % (index + 1)
	add_child(body)
	body.position = pos
	var palm := Models.palm(height, 100 + index)
	body.add_child(palm)
	# Les palmiers penchent vers la mer, chacun un peu différemment.
	var out := Vector3(pos.x, 0, pos.z).normalized()
	palm.rotation.y = atan2(-out.z, out.x) + (index - 1) * 0.35
	body.set_meta("trunk", palm.get_meta("trunk"))
	body.set_meta("model", palm)
	# Collision : le bas du tronc (le haut penche, on ne s'y cogne pas).
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.28
	shape.height = 2.4
	col.shape = shape
	col.position = Vector3(0, 1.2, 0)
	body.add_child(col)
	palms.append(body)


func _add_rock(pos: Vector3, width: float) -> void:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = pos + Vector3(0, -0.15, 0)  # un peu enfoncé dans le sable
	var rock := Models.rock("rock_large", Vector3(width, width * 0.55, width * 0.8))
	rock.rotation.y = pos.x * 0.37
	body.add_child(rock)
	for col in Models.convex_collisions(rock):
		col.transform = rock.transform * col.transform
		body.add_child(col)
	var small := Models.rock("rock_small", Vector3(0.8, 0.5, 0.7))
	small.position = Vector3(width * 0.55, 0.0, width * 0.35)
	body.add_child(small)


## Buissons sur les dunes, bois flotté et petits cailloux sur la plage. Pas de collision.
func _scatter(bushes: int, logs: int) -> void:
	var terrain := GameState.terrain
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var placed := 0
	var tries := 0
	while placed < bushes and tries < bushes * 40:
		tries += 1
		var a := rng.randf() * TAU
		var r := rng.randf_range(terrain.build_radius + 1.0, terrain.coast_at(a) - 1.0)
		var x := cos(a) * r
		var z := sin(a) * r
		var h := terrain.height(x, z)
		# Sur les dunes (bien au-dessus du sable de la plage), là où l'herbe pousse.
		if terrain.dune_amount(a) < 0.3 or h < terrain.ground_y + 0.8:
			continue
		var bush := Models.load_model("bush_large" if rng.randf() < 0.4 else "bush")
		Models.fit_on_ground(bush, rng.randf_range(0.6, 1.1))
		var holder := Node3D.new()
		holder.position = Vector3(x, h - 0.05, z)
		holder.rotation.y = rng.randf() * TAU
		holder.add_child(bush)
		add_child(holder)
		placed += 1
	for i in logs:
		var a := rng.randf() * TAU
		if terrain.dune_amount(a) > 0.0:
			a = PI / 2 + rng.randf_range(-0.9, 0.9)  # la plage de départ (+Z), sans dunes
		var r := terrain.coast_at(a) - rng.randf_range(0.8, 2.2)
		var pos := Vector3(cos(a) * r, 0, sin(a) * r)
		pos.y = terrain.height(pos.x, pos.z) - 0.05
		var kind := "log" if i % 2 == 0 else "rock_small"
		var model := Models.load_model(kind)
		Models.fit_on_ground(model, 0.35 if kind == "log" else 0.28)
		var holder := Node3D.new()
		holder.position = pos
		holder.rotation.y = rng.randf() * TAU
		holder.add_child(model)
		add_child(holder)


## Fleurs (Nature Kit, CC0) dans l'herbe des dunes, et coquillages de décor sur la plage, hors
## de la zone constructible (ceux qu'on ramasse sont des objets à part, GameState.pickups).
func _scatter_small(flowers: int, shells: int) -> void:
	var terrain := GameState.terrain
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var placed := 0
	var tries := 0
	while placed < flowers and tries < flowers * 40:
		tries += 1
		var a := rng.randf() * TAU
		var r := rng.randf_range(terrain.build_radius + 1.0, terrain.coast_at(a) - 1.0)
		var x := cos(a) * r
		var z := sin(a) * r
		var h := terrain.height(x, z)
		if terrain.dune_amount(a) < 0.3 or h < terrain.ground_y + 1.4:
			continue  # seulement là où l'herbe pousse (haut des dunes)
		var flower := Models.load_model("flower_red")
		Models.fit_on_ground(flower, rng.randf_range(0.25, 0.4))
		var holder := Node3D.new()
		holder.position = Vector3(x, h - 0.03, z)
		holder.rotation.y = rng.randf() * TAU
		holder.add_child(flower)
		add_child(holder)
		placed += 1
	for i in shells:
		var a := rng.randf() * TAU
		var r := terrain.coast_at(a) - rng.randf_range(0.5, 3.0)
		if r < terrain.build_radius:
			continue
		var pos := Vector3(cos(a) * r, 0, sin(a) * r)
		pos.y = terrain.height(pos.x, pos.z) - 0.02
		if pos.y < 0.1:
			continue  # pas dans l'eau
		var size := rng.randf_range(0.12, 0.2)
		var shell := Props.shell(i, size) if i % 5 else Props.starfish(0.22, Color(1.0, 0.5, 0.35))
		shell.transform = Props.on_sand(terrain, pos, size * 0.55, rng.randf() * TAU)
		add_child(shell)
