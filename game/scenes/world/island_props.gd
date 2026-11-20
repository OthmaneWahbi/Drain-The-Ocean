class_name IslandProps
extends Node3D
## Les éléments fixes de l'île (0.1.2) : palmiers (avec leurs noix de coco), rochers, buissons
## sur les dunes, bois flotté sur les plages. Modèles CC0 retouchés (Models). Les positions des
## palmiers et rochers viennent de GameConfig ; le décor des dunes est tiré au hasard, toujours
## le même (graine fixe), et seulement hors de la zone constructible.

var palms: Array[Node3D] = []
## Le petit décor (0.1.10) : [nœud, x, z, rayon, enfoncement (ou orientation), règle] ; règle
## "grass" (fleurs : seulement sur l'herbe), "shell" (coquillage couché sur la pente) ou "sand". Quand la pelle touche le sable, on le recale au
## sol ou on le cache (fleur hors de l'herbe, décor sur une case travaillée).
var _decor: Array = []


func _ready() -> void:
	var cfg := GameState.config
	var terrain := GameState.terrain
	for i in cfg.palms.size():
		var p := cfg.palms[i]
		_add_palm(Vector3(p.x, terrain.lowest_height(p.x, p.y, 0.35), p.y), p.z, i)
	for i in cfg.outer_palms.size():
		var p := cfg.outer_palms[i]
		var y := terrain.lowest_height(p.x, p.y, 0.35)
		if y > 0.15:  # jamais dans l'eau
			_add_palm(Vector3(p.x, y, p.y), p.z, cfg.palms.size() + i)
	for r in cfg.rocks:
		_add_rock(Vector3(r.x, terrain.lowest_height(r.x, r.y, r.z * 0.4), r.y), r.z)
	_scatter(cfg.dune_bushes, cfg.driftwood)
	_scatter_small(cfg.dune_flowers, cfg.beach_shells)
	GameState.terrain_changed.connect(_on_terrain_changed)


## Garde un élément de décor posé au plus bas du sol sous lui (jamais en l'air sur une pente).
func _add_decor(node: Node3D, x: float, z: float, radius: float, sink: float, rule: String) -> void:
	node.position = Vector3(x, GameState.terrain.lowest_height(x, z, radius) - sink, z)
	add_child(node)
	_decor.append([node, x, z, radius, sink, rule])


## La pelle a bougé des coins : on recale le décor proche, et on cache ce qui n'a plus sa place.
func _on_terrain_changed(corners: Array) -> void:
	if corners.is_empty():
		return
	var terrain := GameState.terrain
	var near := {}
	for c: Vector2i in corners:
		for dj in range(-2, 2):
			for di in range(-2, 2):
				near[c + Vector2i(di, dj)] = true
	for d in _decor:
		var cell := TerrainLogic.cell_of(d[1], d[2])
		if not near.has(cell):
			continue
		var node: Node3D = d[0]
		if d[5] == "shell":  # couché sur la pente (d[4] = son orientation)
			node.transform = Props.on_sand(terrain, Vector3(d[1], 0.0, d[2]), d[3], d[4])
		else:
			node.position.y = terrain.lowest_height(d[1], d[2], d[3]) - d[4]
		node.visible = decor_allowed(terrain, d[1], d[2], d[3], d[5])


## Un élément de décor a-t-il sa place ici ? (statique, pour les tests)
static func decor_allowed(terrain: TerrainLogic, x: float, z: float, radius: float, rule: String) -> bool:
	if terrain.cell_worked(TerrainLogic.cell_of(x, z)):
		return false
	return rule != "grass" or terrain.is_grass_around(x, z, radius)


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
		var size := rng.randf_range(0.6, 1.1)
		var bush := Models.load_model("bush_large" if rng.randf() < 0.4 else "bush")
		Models.fit_on_ground(bush, size)
		var holder := Node3D.new()
		holder.rotation.y = rng.randf() * TAU
		holder.add_child(bush)
		_add_decor(holder, x, z, size * 0.3, 0.03, "sand")
		placed += 1
	for i in logs:
		var a := rng.randf() * TAU
		if terrain.dune_amount(a) > 0.0:
			a = PI / 2 + rng.randf_range(-0.9, 0.9)  # la plage de départ (+Z), sans dunes
		var r := terrain.coast_at(a) - rng.randf_range(0.8, 2.2)
		var kind := "log" if i % 2 == 0 else "rock_small"
		var model := Models.load_model(kind)
		Models.fit_on_ground(model, 0.35 if kind == "log" else 0.28)
		var holder := Node3D.new()
		holder.rotation.y = rng.randf() * TAU
		holder.add_child(model)
		_add_decor(holder, cos(a) * r, sin(a) * r, 0.3, 0.04, "sand")


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
		var size := rng.randf_range(0.25, 0.4)
		# Seulement sur les facettes d'herbe, sans déborder sur le sable (remarque 1, 0.1.10).
		if terrain.dune_amount(a) < 0.3 or not terrain.is_grass_around(x, z, size * 0.5):
			continue
		var flower := Models.load_model("flower_red")
		Models.fit_on_ground(flower, size)
		var holder := Node3D.new()
		holder.rotation.y = rng.randf() * TAU
		holder.add_child(flower)
		_add_decor(holder, x, z, size * 0.3, 0.02, "grass")
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
		var yaw := rng.randf() * TAU
		shell.transform = Props.on_sand(terrain, pos, size * 0.55, yaw)
		add_child(shell)
		_decor.append([shell, pos.x, pos.z, size * 0.55, yaw, "shell"])
