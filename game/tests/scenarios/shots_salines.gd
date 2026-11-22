extends RefCounted
## Plan de captures « salines » (0.1.20) : un marais creusé (vide, plein, séché avec ses tas),
## les flaques à marée basse et à marée haute, le texte d'aide pour verser dans un trou.


func _dig(gs: Node, origin: Vector2i, w: int, h: int, depth: float) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var corners := []
	for j in h:
		for i in w:
			var c := origin + Vector2i(i, j)
			cells.append(c)
			corners.append_array(gs.terrain.set_cell(c, SaltMarsh.base_mean(gs.terrain, c) - depth))
	gs.terrain_changed.emit(corners)
	return cells


func _ground(gs: Node, x: float, z: float) -> Vector3:
	return Vector3(x, gs.terrain.height(x, z) + 0.05, z)


func run(tree: SceneTree, gs: Node) -> void:
	gs.day.time_s = gs.day.day_length_s * (12.0 / 24.0)
	var cells := _dig(gs, Vector2i(-12, -6), 4, 3, 0.4)
	var mid := Vector3(-10.0, 0.0, -4.5)
	mid.y = gs.terrain.height(mid.x, mid.z)
	gs.bucket.water_l = gs.bucket.capacity_l
	gs.select_tool(0)
	await tree.shot("salines_trou_verser", _ground(gs, -10.0, -0.2), mid)
	gs.pour_bucket_into_hole(mid)
	var m: Dictionary = gs.marsh_at_cell(cells[0])
	(m.logic as DryingLogic).water_l = (m.logic as DryingLogic).capacity_l
	await tree.shot("salines_marais_plein", _ground(gs, -10.0, 0.5), mid)
	await tree.shot("salines_marais_haut", _ground(gs, -7.0, -1.0) + Vector3(0, 3.0, 0), mid)
	(m.logic as DryingLogic).water_l = 6.0
	(m.logic as DryingLogic).deposit = {"sel": 14, "mineraux": 3, "mineraux_rares": 1}
	await tree.shot("salines_marais_sel", _ground(gs, -10.0, 0.5), mid)
	# Les flaques : marée basse puis haute.
	var pool: Dictionary = gs.tide_pools[0]
	var p: Vector3 = pool.position
	var dir := Vector3(p.x, 0, p.z).normalized()
	gs.day.time_s = gs.day.day_length_s * (9.0 / 24.0)
	gs.simulate(0.1)
	pool.items = ["etoile_de_mer", "oursin"]
	gs.tide_pools_changed.emit()
	var eye := _ground(gs, p.x - dir.x * 2.6, p.z - dir.z * 2.6)
	await tree.shot("salines_flaque_maree_basse", eye, p)
	gs.tide_pools[1].items = ["bernard_ermite", "coquillage"]
	gs.tide_pools_changed.emit()
	var p1: Vector3 = gs.tide_pools[1].position
	var dir1 := Vector3(p1.x, 0, p1.z).normalized()
	await tree.shot("salines_flaque_2", _ground(gs, p1.x - dir1.x * 2.4, p1.z - dir1.z * 2.4), p1)
	gs.day.time_s = gs.day.day_length_s * (15.0 / 24.0)
	gs.simulate(0.1)
	await tree.shot("salines_flaque_maree_haute", eye, p)
