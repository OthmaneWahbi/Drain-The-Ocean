extends RefCounted
## Plan de captures « explorer » (0.1.23) : le décor du campement (de jour, de nuit, au ras du
## sable pour voir ce qui s'enfonce ou flotte), la bouteille et son message, l'épave qui dérive puis
## échouée, le nid et les tortues, la pousse et le cocotier planté, l'horizon (îles, tourbillon),
## la longue-vue, le détecteur et la noix de coco en main, ce que la pelle sort du sable.


func _ground(gs: Node, x: float, z: float) -> Vector3:
	return Vector3(x, gs.terrain.height(x, z) + 0.05, z)


func _hour(gs: Node, h: float) -> void:
	gs.day.time_s = gs.day.day_length_s * (h / 24.0)


func _player(tree: SceneTree) -> Node:
	return tree.root.find_child("Player", true, false)


func run(tree: SceneTree, gs: Node) -> void:
	_hour(gs, 11.0)
	# Le décor du campement, en rang sur la plage.
	var x := -10.0
	for id in ["longue_vue", "feu_de_camp", "cloture", "lampion", "tapis", "coquillage_geant"]:
		gs.apply_item(gs.catalog.find(StringName(id)), _ground(gs, x, 4.0))
		x += 2.0
	for k in 5:
		gs.apply_item(gs.catalog.find(&"dalles"), _ground(gs, -10.0 + k, 6.0))
	var mid := _ground(gs, -5.0, 4.0) + Vector3(0, 0.4, 0)
	await tree.shot("explorer_decor_jour", _ground(gs, -5.0, 10.0), mid)
	await tree.shot("explorer_decor_cote", _ground(gs, 3.0, 6.0), mid)
	await tree.shot("explorer_decor_dos", _ground(gs, -5.0, -1.5), mid)
	# Au ras du sable (on cherche ce qui flotte ou s'enfonce).
	await tree.shot("explorer_decor_ras", _ground(gs, -5.0, 7.5) + Vector3(0, -1.3, 0), mid + Vector3(0, -0.3, 0))
	_hour(gs, 22.5)
	await tree.shot("explorer_decor_nuit", _ground(gs, -5.0, 10.0), mid)
	await tree.snap("explorer_decor_nuit_flammes", 0.4)
	await tree.shot("explorer_feu_pres", _ground(gs, -8.0, 6.5), _ground(gs, -8.0, 4.0))
	_hour(gs, 11.0)
	# La bouteille sur la plage, puis son message.
	var bp := _ground(gs, 6.0, 9.0)
	gs.add_pickup("bottle", bp)
	await tree.shot("explorer_bouteille", bp + Vector3(0, 0, 2.2), bp)
	var bottle: Dictionary = gs.pickups.back()
	gs.take_pickup(bottle)
	await tree.snap("explorer_message_carte", 0.4)
	var note: Node = tree.root.find_child("BottleNote", true, false)
	if note:
		note.close()
	for d in ["chaine", "avion", "crabe"]:
		gs.bottle_opened.emit(d)
		await tree.snap("explorer_message_%s" % d, 0.3)
		if note:
			note.close()
	# L'épave : au large, puis échouée.
	var w: Dictionary = gs.spawn_wreck()
	if not w.is_empty():
		var t: Vector3 = w.target
		var dir := Vector3(t.x, 0, t.z).normalized()
		w.position = t + dir * 6.0
		w.position.y = gs.water_level_y()
		await tree.shot("explorer_epave_large", t - dir * 4.0, w.position)
		gs._run_wrecks(1000.0)
		await tree.shot("explorer_epave_echouee", t - dir * 2.5 + dir.cross(Vector3.UP) * 1.0, t)
		await tree.shot("explorer_epave_ras", t - dir * 2.0 + Vector3(0, -1.2, 0), t)
	# Le nid, la tortue qui pond, puis les petites qui courent.
	_hour(gs, 22.3)
	var n: Dictionary = gs.lay_nest()
	if not n.is_empty():
		var np: Vector3 = n.position
		var out := Vector3(np.x, 0, np.z).normalized()
		await tree.shot("explorer_tortue_pond", np - out * 3.0 + out.cross(Vector3.UP) * 1.5, np)
		await tree.snap("explorer_tortue_pond_2", 1.5)
		_hour(gs, 11.0)
		await tree.shot("explorer_nid_jour", np - out * 2.2, np)
		gs.nests.erase(n)
		gs.turtles_hatched.emit(n)
		await tree.snap("explorer_bebes_tortues", 1.0)
		await tree.snap("explorer_bebes_tortues_2", 1.5)
	_hour(gs, 11.0)
	# La pousse et le cocotier planté.
	gs.coconuts_held = 2
	var spots: Array[Vector3] = []
	for xx in range(-20, 21):
		for zz in range(-20, 21):
			var p := Vector3(xx + 0.5, 0, zz + 0.5)
			if gs.plant_reason(p) == "" and spots.size() < 2 and (spots.is_empty() or spots[0].distance_to(p) > 4.0):
				spots.append(p)
	for s in spots:
		gs.plant_coconut(s)
	if spots.size() == 2:
		var a: Vector3 = gs.planted[0].position
		await tree.shot("explorer_pousse", a + Vector3(1.8, 0, 1.8), a + Vector3(0, 0.3, 0))
		gs.planted[1].planted_day = gs.day.day_index - gs.config.planted_palm_days
		gs._island_morning()
		var b: Vector3 = gs.planted[1].position
		await tree.shot("explorer_cocotier_plante", b + Vector3(5.0, 0, 5.0), b + Vector3(0, 2.0, 0))
	# L'horizon : les îles lointaines et le tourbillon.
	for deg in [35.0, 140.0, 215.0, 300.0]:
		var ra := deg_to_rad(deg)
		var eye := _ground(gs, cos(ra) * 14.0, sin(ra) * 14.0)
		await tree.shot("explorer_horizon_%d" % int(deg), eye, Vector3(cos(ra) * 400.0, 1.0, sin(ra) * 400.0))
	# La longue-vue : on regarde dedans, vers la cabine bleue de l'île lointaine, puis zoom max.
	var spy: Dictionary = {}
	for d in gs.decor:
		if d.kind == "longue_vue":
			spy = d
	var pl := _player(tree)
	if not spy.is_empty() and pl:
		var ra := deg_to_rad(140.0)
		await tree.shot("explorer_longue_vue", spy.position + Vector3(1.5, 0, 1.5), spy.position + Vector3(0, 1.0, 0))
		var at: Vector3 = spy.position - Vector3(cos(ra), 0, sin(ra)) * 0.5
		await tree.shot("explorer_longue_vue_avant", at, Vector3(cos(ra) * 420.0, 2.0, sin(ra) * 420.0))
		pl.enter_spyglass(spy.position + Vector3(0, 1.15, 0))
		await tree.snap("explorer_longue_vue_x4", 0.4)
		pl._spy_zoom = gs.config.spyglass_zoom_max
		await tree.snap("explorer_longue_vue_x12", 0.4)
		pl.exit_spyglass()
	# Le détecteur et la noix de coco en main.
	gs.gear["detecteur"] = true
	gs._sync_toolbar()
	gs.buried.clear()
	var bur := _ground(gs, 8.0, 12.0)
	gs.buried.append({"kind": "piece", "position": bur})
	var i: int = gs.toolbar.index_of("detecteur")
	if i >= 0:
		gs.select_tool(i)
	await tree.shot("explorer_detecteur", bur + Vector3(0, 0, 1.2), bur)
	await tree.snap("explorer_detecteur_2", 0.25)
	gs.coconuts_held = 1
	gs._sync_toolbar()
	i = gs.toolbar.index_of("noix_de_coco")
	if i >= 0:
		gs.select_tool(i)
	await tree.shot("explorer_noix_en_main", _ground(gs, -3.0, -3.0), _ground(gs, -3.0, -6.0))
	# Ce que la pelle sort du sable.
	await tree.shot("explorer_avant_trouvaille", bur + Vector3(0, 0, 2.5), bur)
	gs._check_buried(bur)
	await tree.snap("explorer_trouvaille", 0.3)
	gs.dug_up.emit("tresor", bur)
	await tree.snap("explorer_coffre", 0.5)
	# La vitrine avec les nouvelles rangées.
	for id in ["bouteille_carte", "bouteille_chaine", "piece_ancienne", "coffre", "oeuf_tortue"]:
		if not gs.has_found(id):
			gs.add_to_collection(id)
