extends RefCounted
## Plan de captures « livraison » (0.1.17) : la caisse posée vue de plusieurs côtés, la caisse
## sous son parachute, et l'avion qui passe (sa trajectoire est aussi mesurée et imprimée).


func _ground(gs: Node, x: float, z: float) -> Vector3:
	return Vector3(x, gs.terrain.height(x, z), z)


func run(tree: SceneTree, gs: Node) -> void:
	var main: Node = tree.root.get_node("Main")
	var depot: Node3D = main.get_node("Depot")
	# Une caisse posée tout de suite, près du point de livraison.
	var crate: Dictionary = gs._new_crate(["tongs"], 0.0)
	gs.crate_added.emit(crate, false)
	await tree.snap("attente", 0.3)
	var c: Vector3 = crate.position
	var look := c + Vector3(0, 0.45, 0)
	var k := 0
	for a in [0.0, 90.0, 180.0, 270.0]:
		var d := Vector3(sin(deg_to_rad(a)), 0, cos(deg_to_rad(a)))
		await tree.shot("caisse_%d" % k, _ground(gs, c.x + d.x * 2.6, c.z + d.z * 2.6), look)
		k += 1
	await tree.shot("caisse_dessus", _ground(gs, c.x + 1.0, c.z + 1.2), c)
	await tree.shot("caisse_pres", _ground(gs, c.x + 0.9, c.z + 1.6), look)
	# L'avion : on suit une livraison, la caméra au bord de la palette, et on mesure la vitesse.
	var crate2: Dictionary = gs._new_crate(["tongs"], 0.0)
	crate2["paid"] = {"sel": 3, "coquillages": 1}
	var cam := _ground(gs, depot.global_position.x - 7.0, depot.global_position.z + 8.0)
	await tree.shot("ciel", cam, depot.global_position + Vector3(0, 5, 0))
	gs.crate_added.emit(crate2, true)
	await tree.process_frame
	var plane: Node3D = null
	for n in main.find_children("*", "Node3D", true, false):
		if n.get_script() == preload("res://scenes/world/delivery_plane.gd"):
			plane = n
	var path: FlightPath = plane.path
	print("passage : crochet à %.2f s, largage à %.2f s, durée %.2f s, altitude %.1f m" % [path.hook_time(), path.drop_time(), path.duration(), path.altitude_y])
	var t := 0.0
	var last := plane.global_position
	var marks := [path.hook_time() - 1.2, path.hook_time() - 0.15, path.hook_time() + 0.6, path.drop_time() + 0.3, path.drop_time() + 1.0, path.drop_time() + 2.0, path.drop_time() + 3.0]
	var names := ["avion_arrive", "avion_crochet", "avion_paiement", "largage", "parachute_ouvert", "parachute_descente", "parachute_bas"]
	var next_print := 0.0
	var last_t := 0.0
	var crate_view: Node3D = main._crate_views.get(crate2.id)
	var landed_at := -1.0
	while t < 16.0:
		await tree.process_frame
		var dt := tree.root.get_process_delta_time()
		t += dt
		if is_instance_valid(plane):
			var p := plane.global_position
			if t >= next_print:
				# Vitesse moyenne depuis la dernière mesure (une image seule dépend du rythme d'affichage).
				print("avion t=%.2f pos=(%.1f, %.1f, %.1f) vitesse=%.1f m/s haut=%.1f" % [t, p.x, p.y, p.z, (p - last).length() / maxf(t - last_t, 0.0001), p.y - depot.global_position.y])
				next_print += 0.5
				last = p
				last_t = t
		if landed_at < 0.0 and crate_view.landed:
			landed_at = t
			print("caisse posée à t=%.2f" % t)
		if not marks.is_empty() and t >= marks[0]:
			marks.pop_front()
			var nm: String = names.pop_front()
			# La caméra suit l'action : l'avion, puis la caisse.
			var target: Vector3 = plane.global_position if nm.begins_with("avion") and is_instance_valid(plane) else crate_view.global_position + Vector3(0, 1.5, 0)
			var player: Node3D = tree._player
			var eye := player.global_position + Vector3(0, 1.6, 0)
			var flat := Vector3(target.x - eye.x, 0, target.z - eye.z)
			player.rotation.y = atan2(-flat.x, -flat.z)
			(player.get_node("Head") as Node3D).rotation.x = atan2(target.y - eye.y, flat.length())
			await tree.process_frame
			t += tree.root.get_process_delta_time()  # cette image compte aussi dans le temps de vol
			var img := tree.root.get_texture().get_image()
			img.save_png("%s/%s.png" % [tree._dir, nm])
			print("shot ", nm)
	print("fin du suivi à t=%.2f" % t)
	var c2: Vector3 = crate2.position
	await tree.shot("caisse_posee", _ground(gs, c2.x + 2.2, c2.z + 2.0), c2 + Vector3(0, 0.45, 0))
	# La voile qui s'affaisse : une autre caisse, regardée de près pendant l'atterrissage.
	var crate3: Dictionary = gs._new_crate(["tongs"], 0.0)
	var c3: Vector3 = crate3.position
	await tree.shot("vide", _ground(gs, c3.x + 4.0, c3.z + 4.5), c3 + Vector3(0, 1.0, 0))
	gs.crate_added.emit(crate3, false)
	var v3: Node3D = main._crate_views.get(crate3.id)
	v3.landed = false
	v3.visible = true
	v3._chute.visible = true
	v3.drop_from_y(c3.y + 4.0)
	var ft := FlightPath.fall_time(4.0 - 0.0, gs.config.chute_freefall_s, gs.config.chute_descent_m_s)
	await tree.snap("atterrissage_avant", ft - 0.25)
	await tree.snap("atterrissage_voile", 0.45)
	await tree.snap("atterrissage_fin", 1.2)
