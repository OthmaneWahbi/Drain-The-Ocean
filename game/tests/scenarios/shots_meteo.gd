extends RefCounted
## Plan de captures « météo » (0.1.22) : l'affiche et le baromètre de la cabine, la fleur de sel
## sur une zone, le marais de sel rose, la palette avec ses nouveaux bacs, les décors chic et les
## surprises, chaque temps (vent, couvert, canicule, averse au loin), le catalogue.


func _ground(gs: Node, x: float, z: float) -> Vector3:
	return Vector3(x, gs.terrain.height(x, z) + 0.05, z)


func _weather(tree: SceneTree, gs: Node, id: String) -> void:
	gs.set_weather(id)
	for view in tree.root.find_children("*", "Node3D", true, false):
		if not view is WeatherView:
			continue
		view._wind = gs.weather_value("wind")
		view._overcast = gs.weather_value("overcast")
		view._heat = gs.weather_value("heat")
		view._rain = gs.weather_value("rain")


func run(tree: SceneTree, gs: Node) -> void:
	gs.day.time_s = gs.day.day_length_s * (11.0 / 24.0)
	gs.agency_order = {"id": "o_sel", "sent": false}
	gs.agency_order_changed.emit()
	# L'affiche et le baromètre.
	var board: Node3D = tree.root.find_child("AgencyBoard*", true, false)
	if board == null:
		for n in tree.root.find_children("*", "Node3D", true, false):
			if n is AgencyBoard:
				board = n
				break
	if board:
		var p := board.global_position
		var out := board.global_basis.z
		var mid := p + Vector3(0, 1.45, 0)
		await tree.shot("meteo_affiche", p + out * 2.2, mid)
	# La fleur de sel sur la cuvette.
	var z: Dictionary = gs.zones[0]
	(z.logic as DryingLogic).water_l = 20.0
	(z.logic as DryingLogic).deposit = {"fleur_de_sel": 9, "sel": 6}
	var c: Vector3 = z.position
	await tree.shot("meteo_fleur_de_sel", c + Vector3(1.6, 1.6, 1.6), c)
	# La palette, une fois tout trouvé.
	gs.add_carried({"fleur_de_sel": 1, "sel_rose": 1})
	gs.stock = {"sel": 60, "mineraux": 12, "mineraux_rares": 2, "coquillages": 9, "perles": 1, "fleur_de_sel": 14, "sel_rose": 25}
	gs.stock_changed.emit()
	var d: Vector3 = gs.depot.position
	await tree.shot("meteo_palette", d + Vector3(0, 1.6, 3.2), d)
	# Les décors chic et les surprises, en rang.
	var x := -9.0
	for id in ["parasol", "flamant_sel", "saliere", "surprise_bouee", "surprise_nain"]:
		gs.apply_item(gs.catalog.find(StringName(id)), _ground(gs, x, 3.0))
		x += 2.2
	await tree.shot("meteo_decors", _ground(gs, -4.6, 8.0) + Vector3(0, 1.2, 0), _ground(gs, -4.6, 3.0) + Vector3(0, 0.6, 0))
	# Chaque temps, vu de la plage vers le large.
	var eye := _ground(gs, -2.0, -6.0) + Vector3(0, 1.6, 0)
	var a := deg_to_rad(250.0)
	var far := Vector3(cos(a) * 150.0, 18.0, sin(a) * 150.0)
	for id in ["calme", "venteux", "couvert", "canicule", "averse"]:
		_weather(tree, gs, id)
		await tree.snap("meteo_temps_%s_snap" % id, 0.3)
		await tree.shot("meteo_temps_%s" % id, eye, far)
	_weather(tree, gs, "calme")
	# Le catalogue : la commande de l'agence en haut.
	var cat: Node = tree.get_first_node_in_group(&"catalogue")
	if cat:
		cat.open_catalogue()
		await tree.process_frame
		await tree.snap("meteo_catalogue", 0.6)
		var scrolls := cat.find_children("*", "ScrollContainer", true, false)
		if not scrolls.is_empty():
			var scroll := scrolls[0] as ScrollContainer
			await tree.process_frame
			scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value * 0.55)
		await tree.snap("meteo_catalogue_chic", 0.6)
		cat.close_catalogue()
	# La commande envoyée : « MERCI ! ».
	gs.send_agency_order()
	if board:
		var p2 := board.global_position
		var mid2 := p2 + Vector3(0, 1.45, 0)
		await tree.shot("meteo_affiche_merci", p2 + board.global_basis.z * 2.2, mid2)
		await tree.shot("meteo_cabine", p2 + board.global_basis.z * 5.0 + board.global_basis.x * 2.0, mid2)
