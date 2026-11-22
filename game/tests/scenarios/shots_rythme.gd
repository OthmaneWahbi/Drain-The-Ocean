extends RefCounted
## Plan de captures « rythme » (0.1.24) : « Sec dans … » sur une zone, le bonus « ×1,… » en
## mode déplacement, l'arrosoir et le seau percé en main (plein, qui goutte), un arrosage, le
## mode photo et ses quatre filtres, l'option Musique.


func _ground(gs: Node, x: float, z: float) -> Vector3:
	return Vector3(x, gs.terrain.height(x, z) + 0.05, z)


func run(tree: SceneTree, gs: Node) -> void:
	gs.day.time_s = gs.day.day_length_s * (11.0 / 24.0)
	var player: Node = tree.root.find_child("Player", true, false)
	var z: Dictionary = gs.zones[0]
	var c: Vector3 = z.position
	(z.logic as DryingLogic).water_l = 18.0
	# La zone visée : son texte d'aide dit quand elle sera sèche.
	await tree.shot("rythme_sec_dans", c + Vector3(0, 0, 3.0), c)
	# Le mode déplacement d'une zone : le bonus à l'endroit visé.
	gs.add_mirror(c + Vector3(-3, 0, -2))
	var pc: Node = null
	for n in tree.root.find_children("*", "Node", true, false):
		if n is PlacementController:
			pc = n
	if pc:
		var views := tree.root.find_children("*", "StaticBody3D", true, false)
		for v in views:
			if v.has_method(&"get_movable") and v.get_movable() == z:
				pc.start(v)
		await tree.shot("rythme_bonus_g", c + Vector3(0, 0, 4.0), c)
		pc.cancel()
	# L'arrosoir et le seau percé.
	for id in ["arrosoir", "seau_perce"]:
		gs.apply_item(gs.catalog.find(StringName(id)), Vector3.ZERO)
	gs.fill_vessel("arrosoir")
	gs.select_tool(gs.toolbar.index_of("arrosoir"))
	(z.logic as DryingLogic).water_l = 0.0
	await tree.shot("rythme_arrosoir", c + Vector3(0, 0, 2.6), c)
	player._pour_t = 0.6
	gs.pour_vessel("arrosoir", c)
	await tree.snap("rythme_arrosage", 0.25)
	gs.fill_vessel("seau_perce")
	gs.select_tool(gs.toolbar.index_of("seau_perce"))
	await tree.shot("rythme_seau_perce", c + Vector3(0, 0, 2.6), c + Vector3(0, -0.5, 0))
	await tree.snap("rythme_seau_perce_goutte", 0.5)
	await tree.shot("rythme_seau_perce_3p", c + Vector3(0, 0, 2.6), c, true)
	# Le mode photo : chaque filtre.
	var photo: Node = tree.root.find_child("PhotoMode", true, false)
	await tree.shot("rythme_avant_photo", _ground(gs, 4.0, 12.0), _ground(gs, 0.0, 0.0) + Vector3(0, 1.0, 0))
	if photo:
		photo.enter()
		for i in 4:
			photo.set_filter(i)
			await _paused_snap(tree, "rythme_photo_filtre_%d" % i)
		photo.leave()
	await tree.snap("rythme_apres_photo", 0.3)
	# Les options : le curseur Musique.
	var pause: Node = tree.root.find_child("PauseMenu", true, false)
	if pause and pause.has_method(&"open_options"):
		pause.open_options()
		await tree.snap("rythme_options", 0.3)


## Le jeu est en pause pendant le mode photo : on attend des images, pas du temps de jeu.
func _paused_snap(tree: SceneTree, name: String) -> void:
	for k in 8:
		await tree.process_frame
	var img := tree.root.get_texture().get_image()
	img.save_png("%s/%s.png" % [OS.get_environment("SHOTS_DIR"), name])
	print("shot ", name)
