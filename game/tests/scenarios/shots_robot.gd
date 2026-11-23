extends RefCounted
## Le robot photographe (après 0.1.25, demande d'Othmane : « chasser les objets coupés »). Il
## remplit l'île de tout ce qui se pose (chaque article du catalogue, les zones pleines d'eau et de
## sel, les épaves, nids, cocotiers, ramassables, tours de sable, trophées, Pinçon), puis prend
## chaque objet sous 9 angles avec une caméra libre (6 à hauteur d'yeux tout autour, 2 au ras du
## sable pour voir ce qui flotte ou s'enfonce, 1 de dessus), sans HUD. Puis il fait le tour de l'île
## en 3e personne (le joueur dans le décor), et un tour de nuit. Les images vont dans SHOTS_DIR ;
## `tools/planches.py` les assemble en planches pour les regarder vite.
##   SHOTS_DIR=… SHOTS_PLAN=robot xvfb-run godot --path game … -s res://tests/scenarios/shots.gd
## ROBOT_ONLY=mot (facultatif) : seulement les objets dont le nom contient ce mot.

const ANGLES := 6
const PLACEABLE := [0, 2, 7, 9, 10, 12]  # zone, décor, station, miroir, pompe, toboggan

var _cam: Camera3D
var _gs: Node
var _tree: SceneTree
var _only := OS.get_environment("ROBOT_ONLY")


func _ground(x: float, z: float) -> Vector3:
	return Vector3(x, _gs.terrain.height(x, z), z)


func run(tree: SceneTree, gs: Node) -> void:
	_tree = tree
	_gs = gs
	gs.new_game()  # une île neuve : sinon on reprend la sauvegarde du dernier passage, et tout est en double
	gs.day.time_s = gs.day.day_length_s * (10.5 / 24.0)
	gs.set_weather("calme")
	var subjects := _fill_island()
	for f in 30:
		await tree.process_frame
	var overlaps := scan_overlaps(tree)
	# La caméra libre, sans HUD ni outil en main.
	_cam = Camera3D.new()
	_cam.far = 6000.0
	_cam.fov = 70.0
	tree.root.add_child(_cam)
	_cam.current = true
	for n in tree.root.find_children("*", "CanvasLayer", true, false):
		(n as CanvasLayer).visible = false
	var player: Node3D = tree.root.find_child("Player", true, false)
	var head: Node3D = player.get_node("Head")
	head.visible = false
	player.set("spying", true)  # le HUD se cache tout seul (comme à la longue-vue), sans le cercle
	player.global_position = Vector3(0, 30, -60)  # loin de tout, pour qu'il ne gêne pas les photos
	for k in overlaps.size():
		var o: Dictionary = overlaps[k]
		var c: Vector3 = o.center
		var name := "chevauchement_%02d" % k
		await _snap("robot_%s_a" % name, c + Vector3(2.2, 1.2, 2.2), c)
		await _snap("robot_%s_b" % name, c + Vector3(-2.2, 1.0, -1.6), c)
	for s in subjects:
		if _only != "" and not String(s.name).contains(_only):
			continue
		await _orbit(s)
	print("robot : %d sujets" % subjects.size())
	# Le tour de l'île en 3e personne : le joueur dans le décor.
	head.visible = true
	player.set("spying", false)
	_cam.current = false
	_cam.queue_free()
	for n in tree.root.find_children("*", "CanvasLayer", true, false):
		if n.name in ["HUD"]:
			(n as CanvasLayer).visible = true
	if _only == "":
		var k := 0
		for r: float in [8.0, 16.0, 24.0]:
			for i in 8:
				var a := TAU * i / 8.0 + r * 0.1
				var at := _ground(cos(a) * r, sin(a) * r) + Vector3(0, 0.05, 0)
				if at.y < gs.water_level_y():
					continue
				await tree.shot("robot_tour_%02d" % k, at, Vector3(0, 1.0, 0), true)
				k += 1
		# De nuit, le campement.
		gs.day.time_s = gs.day.day_length_s * (22.5 / 24.0)
		for i in 6:
			var a := TAU * i / 6.0
			await tree.shot("robot_nuit_%d" % i, _ground(cos(a) * 12.0, sin(a) * 12.0) + Vector3(0, 0.05, 0), Vector3(0, 1.0, 0))


## Pose tout ce qui existe dans le jeu ; renvoie les sujets à photographier : {name, pos, size}.
func _fill_island() -> Array:
	var gs := _gs
	var out: Array = []
	var catalog: Array = gs.catalog.items
	var spiral := 0
	for item: CatalogItem in catalog:
		if not int(item.effect) in PLACEABLE:
			continue
		var a := spiral * 2.399  # angle d'or : des places bien réparties
		var r := 5.0 + 1.1 * sqrt(spiral) * 4.0
		spiral += 1
		var it: Dictionary = gs.apply_item(item, Vector3(cos(a) * r, 0.5, sin(a) * r))
		if it.is_empty() or not it.has("position"):
			continue
		var rect: Rect2 = gs.item_rect(it)
		out.append({"name": String(item.id), "pos": it.position, "size": maxf(rect.size.x, rect.size.y)})
		if it.has("logic") and it.logic is DryingLogic:
			(it.logic as DryingLogic).water_l = (it.logic as DryingLogic).capacity_l * 0.6
			(it.logic as DryingLogic).deposit = {"sel": 30, "mineraux": 6}
	# La cuvette de départ (pleine) et ce qui est fixe.
	var basin: Dictionary = gs.zones[0]
	(basin.logic as DryingLogic).water_l = (basin.logic as DryingLogic).capacity_l * 0.7
	out.append({"name": "cuvette", "pos": basin.position, "size": 3.0})
	out.append({"name": "cabine", "pos": Vector3(5, 0.5, 1.5), "size": 2.0})
	out.append({"name": "palette", "pos": gs.depot.position, "size": 3.0})
	out.append({"name": "repere_eau", "pos": Vector3(3, 0.5, 22), "size": 1.5})
	for id in gs.config.trophies:
		gs.trophies[id] = true
	gs.trophy_won.emit(gs.config.trophies[0])
	var tp: Vector3 = gs.config.trophy_stand_position
	out.append({"name": "socle_trophees", "pos": tp, "size": 2.0})
	for i in gs.config.palms.size():
		var p: Vector3 = gs.config.palms[i]
		out.append({"name": "palmier_%d" % i, "pos": _ground(p.x, p.y), "size": 3.0})
	for i in gs.config.rocks.size():
		var p: Vector3 = gs.config.rocks[i]
		out.append({"name": "rocher_%d" % i, "pos": _ground(p.x, p.y), "size": p.z * 2.0})
	# Les événements de l'île : épave échouée, nid, cocotier planté (pousse et adulte), ramassables.
	var w: Dictionary = gs.spawn_wreck()
	if not w.is_empty():
		w.position = w.target
		w.landed = true
		gs.wreck_removed.emit(w)
		gs.wreck_added.emit(w)
		out.append({"name": "epave", "pos": w.position, "size": 1.5})
	var nest: Dictionary = gs.lay_nest()
	if not nest.is_empty():
		out.append({"name": "nid_tortue", "pos": nest.position, "size": 1.5})
	gs.coconuts_held = 2
	for k in 2:
		var spot := Vector3.INF
		for tries in 200:
			var p := Vector3(randf_range(-20, 20), 0.5, randf_range(-20, 20))
			if gs.plant_reason(p) == "":
				spot = p
				break
		if spot.is_finite():
			var pl: Dictionary = gs.plant_coconut(spot)
			if k == 1:
				pl.planted_day = gs.day.day_index - 10
			gs.planted_changed.emit()
			out.append({"name": "cocotier_%s" % ("adulte" if k == 1 else "pousse"), "pos": pl.position, "size": 2.0 if k == 1 else 1.0})
	for kind in ["bottle", "coconut", "shell"]:
		var spot: Vector3 = gs._random_beach_spot()
		if spot.is_finite():
			gs.add_pickup(kind, spot)
			out.append({"name": "ramassable_%s" % kind, "pos": spot, "size": 0.8})
	# Trois tours de sable (1, 2, 3 étages) et Pinçon.
	for r in range(8, 30):
		var found := false
		for k in 36:
			var a := TAU * k / 36.0
			var p := _ground(cos(a) * r, sin(a) * r)
			if gs.castle_reason(p) == "" and gs.castle_reason(p + Vector3(1.0, 0, 0)) == "" and gs.castle_reason(p + Vector3(2.0, 0, 0)) == "":
				for i in 3:
					for f in i + 1:
						gs.build_castle(p + Vector3(i, 0, 0))
				out.append({"name": "tours_de_sable", "pos": p + Vector3(1, 0, 0), "size": 3.0})
				found = true
				break
		if found:
			break
	if gs.pet_position.x < 1.0e8:
		out.append({"name": "pincon", "pos": gs.pet_position, "size": 0.8})
	return out


## Neuf photos d'un sujet : 6 autour à hauteur d'yeux, 2 au ras du sol, 1 de dessus.
func _orbit(s: Dictionary) -> void:
	var c: Vector3 = s.pos
	var size := clampf(float(s.size), 0.6, 6.0)
	var look := c + Vector3(0, minf(size * 0.25, 1.0), 0)
	var dist := 1.6 + size * 1.1
	for i in ANGLES:
		var a := TAU * i / ANGLES + 0.3
		await _snap("robot_%s_%d" % [s.name, i], look + Vector3(cos(a) * dist, 1.0 + size * 0.15, sin(a) * dist), look)
	for i in 2:
		var a := TAU * i / 2.0 + 1.1
		var at := c + Vector3(cos(a) * dist * 0.8, 0.0, sin(a) * dist * 0.8)
		at.y = maxf(_gs.terrain.height(at.x, at.z), _gs.water_level_y()) + 0.12
		await _snap("robot_%s_ras%d" % [s.name, i], at, c + Vector3(0, 0.15, 0))
	await _snap("robot_%s_dessus" % s.name, c + Vector3(0.01, dist * 1.2 + 1.0, 0.4), c)


func _snap(name: String, at: Vector3, look: Vector3) -> void:
	_cam.global_position = at
	if at.distance_to(look) > 0.01:
		_cam.look_at(look, Vector3.UP if absf((look - at).normalized().y) < 0.98 else Vector3.FORWARD)
	for f in 4:
		await _tree.process_frame
	var img := _tree.root.get_texture().get_image()
	img.save_png("%s/%s.png" % [OS.get_environment("SHOTS_DIR"), name])



# --- Le scanner : ce qui se traverse ---------------------------------------------------------

## Les objets du monde à comparer deux à deux : [nom, nœud]. Les palmiers comptent pour leur tronc
## seulement (leurs palmes passent au-dessus de tout, c'est voulu).
func _objects(tree: SceneTree) -> Array:
	var main: Node = tree.root.find_child("Main", true, false)
	var out: Array = []
	for v in main.get_node("Views").get_children():
		out.append([_label(v), v])
	for n in ["Phone", "Depot", "TrophyStand"]:
		var node: Node = main.get_node_or_null(n)
		if node:
			out.append([n, node])
	for v in main.get_node("Castles").get_children():
		out.append(["tour_de_sable", v])
	for v in main.get_node("IslandEvents").get_children():
		if v is Node3D and (v as Node3D).position.length() < 80.0:
			out.append(["evenement_" + String(v.name), v])
	for g in main.get_children():
		if g is WaterGauge:
			out.append(["repere_eau", g])
	var props: Node = main.get_node("Props")
	for p in props.get("palms"):
		out.append(["palmier_" + String(p.name), p])
	return out


func _label(v: Node) -> String:
	for key in ["kind", "item_kind"]:
		if key in v:
			return "%s_%s" % [String(v.get(key)), String(v.name)]
	if v.has_method(&"get_movable"):
		var it: Dictionary = v.get_movable()
		return "%s_%s" % [String(it.get("kind", "?")), String(it.get("id", v.name))]
	return String(v.name)


## Les boîtes (AABB mondiales) des morceaux visibles d'un objet. Pour un palmier, le tronc seul
## (une suite de petites boîtes le long de `Models.trunk_at`).
func _boxes(node: Node) -> Array[AABB]:
	var out: Array[AABB] = []
	if node.has_meta("model") and node.has_meta("trunk"):
		var model: Node3D = node.get_meta("model")
		for h in [0.4, 0.9, 1.4, 1.9, 2.4, 2.9, 3.4]:
			var t: Array = Models.trunk_at(model, h)
			var p: Vector3 = model.global_transform * (t[0] as Vector3)
			var r: float = float(t[1]) * model.global_transform.basis.get_scale().x
			out.append(AABB(p - Vector3(r, 0.25, r), Vector3(r, 0.25, r) * 2.0))
		return out
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null or not m.is_visible_in_tree():
			continue
		var box := m.global_transform * m.mesh.get_aabb()
		if box.size.length() < 0.02:
			continue
		out.append(box)
	return out


## Cherche les objets qui se traversent : deux morceaux d'objets différents dont les boîtes se
## chevauchent de plus de 4 cm dans les trois directions, au-dessus du sol. Écrit la liste dans
## SHOTS_DIR/chevauchements.txt et la renvoie ([{a, b, depth, center}]).
func scan_overlaps(tree: SceneTree) -> Array:
	var objs := _objects(tree)
	var boxes: Array = []
	var whole: Array[AABB] = []
	for o in objs:
		var b := _boxes(o[1])
		boxes.append(b)
		var w := AABB()
		for i in b.size():
			w = b[i] if i == 0 else w.merge(b[i])
		whole.append(w)
	var found: Array = []
	var lines := PackedStringArray()
	for i in objs.size():
		for j in range(i + 1, objs.size()):
			if boxes[i].is_empty() or boxes[j].is_empty() or not whole[i].intersects(whole[j]):
				continue
			var best := 0.0
			var center := Vector3.ZERO
			for a: AABB in boxes[i]:
				for b: AABB in boxes[j]:
					var x := a.intersection(b)
					if x.size == Vector3.ZERO:
						continue
					var ground: float = _gs.terrain.height(x.get_center().x, x.get_center().z)
					if x.end.y < ground + 0.05:
						continue  # au ras du sol (dalles, tapis, pieds dans le sable) : pas gênant
					var depth: float = minf(x.size.x, minf(x.size.y, x.size.z))
					if depth > best:
						best = depth
						center = x.get_center()
			if best > 0.04:
				found.append({"a": objs[i][0], "b": objs[j][0], "depth": best, "center": center})
				lines.append("%02d  %s <-> %s  (%.0f cm, en %.1f ; %.1f ; %.1f)" % [found.size() - 1, objs[i][0], objs[j][0], best * 100.0, center.x, center.y, center.z])
	var f := FileAccess.open("%s/chevauchements.txt" % OS.get_environment("SHOTS_DIR"), FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines) + "\n")
	print("robot : %d objets, %d chevauchements" % [objs.size(), found.size()])
	for l in lines:
		print("  ", l)
	return found
