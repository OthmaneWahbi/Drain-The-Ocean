extends RefCounted
## Plan de captures « crabe » (0.1.19) : Pinçon, le crabe de compagnie, dans chacune de ses
## animations (repos, salut, marche, content, mange, refuse, boude, dort), avec ses accessoires,
## et ses articles au catalogue.


func _crab(tree: SceneTree) -> PetCrab:
	return tree.root.get_node("Main").find_children("PetCrab", "", true, false)[0] as PetCrab


## Une caméra de portrait à `dist` m du crabe, à hauteur de crabe (le joueur, lui, est loin :
## ni son ombre ni son seau ne gênent).
var _cam: Camera3D


func _look_at_crab(tree: SceneTree, gs: Node, crab: PetCrab, dist: float, side := 0.6, height := 0.45) -> void:
	if _cam == null:
		_cam = Camera3D.new()
		_cam.fov = 45.0
		tree.root.add_child(_cam)
	_cam.current = true
	var c := crab.global_position
	var away := Vector3(side, 0, 1.0).normalized() * dist
	_cam.global_position = c + away + Vector3(0, height, 0)
	_cam.look_at(c + Vector3(0, 0.15, 0), Vector3.UP)
	await tree.snap("_cadrage", 0.05)


func _pose(tree: SceneTree, crab: PetCrab, anim: int, name: String, wait_s: float) -> void:
	crab.react(anim)
	crab._reaction_left = 30.0
	await tree.snap(name, wait_s)
	crab._reaction_left = 0.0


func run(tree: SceneTree, gs: Node) -> void:
	var crab := _crab(tree)
	# On le pose sur la plage, devant la caméra (plage sud, près du départ).
	var spot := Vector3(3.0, 0.0, 19.5)
	spot.y = gs.terrain.height(spot.x, spot.z)
	crab.position = spot
	crab._target = spot
	crab._rest = 999.0
	crab._greeted = true
	gs.pet.affection = 30.0
	# Le joueur se tient derrière la caméra (le crabe le regarde), sans son seau en main.
	var player: Node3D = tree._player
	player.global_position = spot + Vector3(0.6, 0.3, 2.6)
	gs.select_tool(1)
	await _look_at_crab(tree, gs, crab, 1.1)
	await tree.snap("crabe_repos", 0.6)
	crab._greeted = false
	await tree.snap("crabe_salut", 0.5)
	await _pose(tree, crab, CrabPose.Anim.HAPPY, "crabe_content", 0.35)
	gs.pet.hunger = 0.2
	gs.interact_pet()
	crab._reaction_left = 30.0
	await tree.snap("crabe_mange", 0.55)
	crab._reaction_left = 0.0
	gs.pet.hunger = 1.0
	await _pose(tree, crab, CrabPose.Anim.REFUSE, "crabe_refuse", 0.3)
	gs.pet.hunger = 0.1
	gs.pet.treats = 0
	await tree.snap("crabe_boude", 0.8)
	gs.pet.hunger = 1.0
	# De près, vu de dessus en biais, pour voir les articulations.
	await _look_at_crab(tree, gs, crab, 0.75, 1.4, 0.55)
	await tree.snap("crabe_pres", 0.3)
	# La marche : il ne vient plus saluer, il part de côté.
	gs.config.pet_greet_distance_m = 0.2
	crab._rest = 0.0
	crab._target = spot + Vector3(-3.0, 0, 0)
	await _look_at_crab(tree, gs, crab, 1.4, 0.0, 0.35)
	await tree.snap("crabe_marche", 0.25)
	await tree.snap("crabe_marche_2", 0.19)
	gs.config.pet_greet_distance_m = 4.0
	crab.position = spot
	crab._target = spot
	crab._rest = 999.0
	crab._greeted = true
	# Les accessoires.
	gs.apply_item(gs.catalog.find(&"chapeau_crabe"), Vector3.ZERO)
	gs.apply_item(gs.catalog.find(&"lunettes_crabe"), Vector3.ZERO)
	crab._reaction_left = 0.0
	await _look_at_crab(tree, gs, crab, 0.95)
	await tree.snap("crabe_chapeau_lunettes", 0.5)
	await _pose(tree, crab, CrabPose.Anim.HAPPY, "crabe_chapeau_content", 0.4)
	gs.pet.affection = 100.0
	gs.interact_pet()
	await tree.snap("crabe_coeurs", 0.55)
	print("invite : ", crab.get_prompt(null))
	# En jeu, en 1re personne : le texte d'aide quand on le vise.
	_cam.current = false
	(player.get_node("Head/FirstPersonCamera") as Camera3D).current = true
	var c := crab.global_position
	await tree.shot("crabe_en_jeu", Vector3(c.x + 0.4, c.y, c.z + 1.6), c)
	_cam.current = true
	# La nuit, il dort.
	gs.day.time_s = gs.day.day_length_s * 0.95
	await tree.snap("crabe_dort", 1.0)
	gs.day.time_s = gs.day.day_length_s * 0.42
	# Le catalogue : ses trois articles.
	var cat: Node = tree.get_first_node_in_group(&"catalogue")
	if cat:
		gs.owned.erase("chapeau_crabe")
		gs.owned.erase("lunettes_crabe")
		cat.open_catalogue()
		await tree.process_frame
		var scrolls := cat.find_children("*", "ScrollContainer", true, false)
		if not scrolls.is_empty():
			var scroll := scrolls[0] as ScrollContainer
			await tree.process_frame
			scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value * 0.42)
		await tree.snap("crabe_catalogue", 0.6)
		cat.close_catalogue()
