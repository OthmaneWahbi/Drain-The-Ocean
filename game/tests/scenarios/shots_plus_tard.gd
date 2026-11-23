extends RefCounted
## Plan de captures « plus tard » (0.1.25) : les tours de sable (de près, au ras du sable, en
## 3e personne avec le seau), le socle des trophées vide puis plein, l'orage au large et son éclair,
## la baleine (à la longue-vue) et les dauphins, la vitrine et sa nouvelle rangée, la carte.


func _ground(gs: Node, x: float, z: float) -> Vector3:
	return Vector3(x, gs.terrain.height(x, z) + 0.05, z)


func _hour(gs: Node, h: float) -> void:
	gs.day.time_s = gs.day.day_length_s * (h / 24.0)


func run(tree: SceneTree, gs: Node) -> void:
	_hour(gs, 10.0)
	var player: Node = tree.root.find_child("Player", true, false)
	# Les tours de sable : trois tours (1, 2, 3 étages) sur du sable plat.
	var spots: Array[Vector3] = []
	for r in range(8, 30):
		for k in 36:
			var a := TAU * k / 36.0
			var p := Vector3(cos(a) * r, 0.0, sin(a) * r)
			p.y = gs.terrain.height(p.x, p.z)
			if spots.size() < 3 and gs.castle_reason(p) == "" and gs.castle_reason(p + Vector3(1.2, 0, 0)) == "" and gs.castle_reason(p + Vector3(2.4, 0, 0)) == "":
				spots = [p, p + Vector3(1.2, 0, 0), p + Vector3(2.4, 0, 0)]
	if spots.size() == 3:
		for i in 3:
			for f in i + 1:
				gs.build_castle(spots[i])
		var mid: Vector3 = spots[1] + Vector3(0, 0.25, 0)
		await tree.shot("tard_chateaux", mid + Vector3(0, 0, 3.0) - Vector3(0, 0.25, 0), mid)
		await tree.shot("tard_chateaux_ras", mid + Vector3(0.5, -1.45, 1.6), mid)
		await tree.shot("tard_chateaux_dessus", mid + Vector3(0, 0.6, 1.2), mid - Vector3(0, 0.3, 0))
		gs.select_tool(gs.toolbar.index_of("seau"))
		await tree.shot("tard_chateaux_seau", spots[0] + Vector3(-1.6, 0, 1.2), spots[0], true)
		await tree.shot("tard_chateaux_aide", spots[2] + Vector3(1.6, 0, 1.6), spots[2] + Vector3(0.6, 0, 0.6))
	# Le socle des trophées, vide puis plein.
	var stand: Vector3 = gs.config.trophy_stand_position
	stand.y = gs.terrain.height(stand.x, stand.z)
	await tree.shot("tard_socle_vide", stand + Vector3(0.4, 0, 2.8), stand + Vector3(0, 0.6, 0))
	for id in gs.config.trophies:
		gs.trophies[id] = true
		gs.trophy_won.emit(id)
	await tree.snap("tard_socle_saut", 0.3)
	await tree.shot("tard_socle_plein", stand + Vector3(0.4, 0, 2.2), stand + Vector3(0, 0.65, 0))
	await tree.shot("tard_socle_cote", stand + Vector3(2.4, 0, 0.6), stand + Vector3(0, 0.6, 0))
	await tree.shot("tard_socle_dessus", stand + Vector3(0, 0.3, 1.0), stand + Vector3(0, 0.5, 0))
	# L'orage au large (au sud-ouest, à 170 m) et son éclair.
	gs.set_weather("orage")
	var weather: Node = tree.root.find_child("Main", true, false).get_node_or_null("Weather")
	var a := deg_to_rad(250.0)
	var far := Vector3(cos(a) * 170.0, 25.0, sin(a) * 170.0)
	await tree.shot("tard_orage_debut", _ground(gs, cos(a) * 18.0, sin(a) * 18.0), far)
	await tree.snap("tard_orage", 10.0)  # le temps change en douceur
	if weather:
		weather.flash()
		for i in 30:  # l'image où l'éclair brille (il clignote)
			await tree.process_frame
			if weather._bolt.visible:
				break
	await tree.snap("tard_orage_eclair", 0.0)
	await tree.snap("tard_orage_apres", 1.0)
	gs.set_weather("calme")
	# Les dauphins à 160 m, la baleine à 700 m (à la longue-vue).
	var sea_dir := Vector3(0, 0, 1)
	var coast := _ground(gs, 0.0, 26.0)
	gs.start_sea_life("dauphins")
	gs.sea_life.position = Vector3(0, 0, 160)
	gs.sea_life.heading = PI / 2
	gs.sea_life_changed.emit()
	await tree.shot("tard_dauphins", coast, coast + sea_dir * 160.0 + Vector3(0, -1.0, 0))
	await tree.snap("tard_dauphins_2", 0.5)
	gs.start_sea_life("baleine")
	gs.sea_life.position = Vector3(0, 0, 700)
	gs.sea_life.heading = PI / 2
	gs.sea_life.age = 2.0
	gs.sea_life_changed.emit()
	await tree.shot("tard_baleine_oeil", coast, coast + sea_dir * 700.0)
	if player:
		player.enter_spyglass(coast + Vector3(0, 1.6, 0))
		player.rotation.y = atan2(-sea_dir.x, -sea_dir.z)
		player.get_node("Head").rotation.x = deg_to_rad(0.6)
		player._spy_zoom = gs.config.spyglass_zoom_max
		await tree.snap("tard_baleine_entree", 0.2)
		gs.sea_life.age = 2.4  # le rendu des captures est lent : on recale l'âge juste avant l'image
		await tree.snap("tard_baleine_jet", 0.01)
		gs.sea_life.age = 10.5
		await tree.snap("tard_baleine_queue", 0.4)
		player.exit_spyglass()
	print("collection baleine=", gs.has_found("baleine"), " dauphin=", gs.has_found("dauphin"))
	# La vitrine, toute la collection.
	for id in gs.collection_slots():
		if not gs.has_found(id):
			gs.add_to_collection(id)
	var shelf := _ground(gs, -6.0, 2.0)
	gs.apply_item(gs.catalog.find(&"vitrine"), shelf)
	await tree.shot("tard_vitrine", shelf + Vector3(0, 0, 2.6), shelf + Vector3(0, 1.0, 0))
	# La carte de l'île.
	var island_map: Node = tree.root.find_child("IslandMap", true, false)
	await tree.shot("tard_avant_carte", _ground(gs, 2.0, 8.0), _ground(gs, 0.0, 0.0))
	if island_map:
		island_map.open()
		await tree.snap("tard_carte", 0.2)
		island_map.close()
