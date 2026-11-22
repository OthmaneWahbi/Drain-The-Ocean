extends RefCounted
## Plan de captures « puiser » (0.1.18) : le geste du seau image par image, à la 1re et à la
## 3e personne, puis avec la palanche (deux seaux).


func _select(gs: Node, tool: String) -> void:
	for i in gs.toolbar.slots.size():
		if gs.toolbar.slots[i] == tool:
			gs.select_tool(i)


## Un geste complet : on maintient le clic et on prend une image à chaque moment de `marks`.
func _scoop(tree: SceneTree, gs: Node, prefix: String, marks: Array) -> void:
	var player: Node3D = tree._player
	gs.bucket.water_l = 0.0
	gs.bucket_changed.emit()
	var t := 0.0
	Input.action_press(&"use_tool")
	var full_at := -1.0
	var stop_at: float = marks[-1] + 0.05
	while t < stop_at:
		await tree.process_frame
		t += tree.root.get_process_delta_time()
		if full_at < 0.0 and gs.bucket.is_full():
			full_at = t
			Input.action_release(&"use_tool")
		if not marks.is_empty() and t >= marks[0]:
			var m: float = marks.pop_front()
			tree.root.get_texture().get_image().save_png("%s/%s_%03d.png" % [tree._dir, prefix, int(m * 100)])
			print("shot %s %.2f s (dans l'eau : %s, p=%.2f)" % [prefix, t, player.is_in_water(), gs.bucket.fill_progress_ratio()])
	Input.action_release(&"use_tool")
	print("plein à %.2f s" % full_at)
	await tree.snap("%s_fin" % prefix, 0.6)


func run(tree: SceneTree, gs: Node) -> void:
	_select(gs, "seau")
	# Au bord de la crique (+Z), de l'eau aux genoux, face au large.
	var a := PI / 2.0
	var r: float = gs.terrain.coast_at(a) + 2.5
	var at := Vector3(cos(a) * r, 0.0, sin(a) * r)
	at.y = gs.terrain.height(at.x, at.z) + 0.05
	var look := at + Vector3(0, 1.2, 6)
	await tree.shot("depart", at, look)
	print("dans l'eau : ", tree._player.is_in_water(), " eau à ", gs.water_level_y(), " pieds à ", at.y)
	var marks := [0.05, 0.2, 0.3, 0.4, 0.55, 0.7, 0.85, 0.95, 1.1, 1.25, 1.5]
	await _scoop(tree, gs, "fp", marks.duplicate())
	await tree.shot("tp_depart", at, look, true)
	await _scoop(tree, gs, "tp", marks.duplicate())
	# Vu de côté (la caméra tournée autour du personnage), pour voir le seau et le corps.
	var arm: Node3D = tree._player.get_node("Head/SpringArm")
	arm.rotation.y = deg_to_rad(70.0)
	await tree.shot("cote_depart", at, look, true)
	await _scoop(tree, gs, "cote", marks.duplicate())
	arm.rotation.y = 0.0
	await tree.shot("fp_retour", at, look)
	# La palanche : deux seaux plongent ensemble.
	gs.bucket_count = 2
	gs.bucket.capacity_l = gs.bucket_unit_l * 2
	await tree.shot("palanche_depart", at, look)
	await _scoop(tree, gs, "palanche", [0.3, 0.55, 0.85, 1.25])
