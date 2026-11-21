extends RefCounted
## Plan de captures « profond » (0.1.14) : un trou de 3 m dans l'île (pas de mer dedans), un
## grand tas (plus d'herbe dessus), et une terrasse nivelée au fond du trou.


func run(tree: SceneTree, gs: Node) -> void:
	gs.has_shovel = true
	gs._sync_toolbar()
	gs.select_tool(gs.toolbar.index_of("pelle"))
	gs.config.shovel_capacity_scoops = 9999
	# Un trou profond dans l'île, loin de tout objet.
	var hv := _clear_spot(gs)
	var hp := TerrainLogic.vertex_xz(hv)
	print("trou en ", hv, " ", hp)
	for k in 200:
		gs.shovel_sand = 0.0
		gs.shovel_scoop(hv, true)
	print("fond : %.2f" % gs.terrain.vertex(hv.x, hv.y).y)
	# Un grand tas plus loin (sommet (-24, 20) = point (-12, 10)).
	for k in 160:
		gs.shovel_sand = 3.0
		gs.shovel_scoop(Vector2i(-24, 20), false)
	gs.shovel_sand = 1.0
	gs.shovel_changed.emit()
	await tree.snap("prof_attente", 1.5)
	await tree.shot("prof_trou", Vector3(hp.x, 4.5, hp.y - 7.5), Vector3(hp.x, -1.5, hp.y))
	await tree.shot("prof_trou_bord", Vector3(hp.x + 4.0, 1.5, hp.y - 4.0), Vector3(hp.x, -2.0, hp.y))
	await tree.shot("prof_tas", Vector3(-12, 2.0, 2.0), Vector3(-12, 2.0, 10))
	await tree.shot("prof_tas_haut", Vector3(-6, 6.0, 4.0), Vector3(-12, 1.5, 10))
	# Une terrasse au fond du trou.
	var y: float = gs.terrain.vertex(hv.x, hv.y).y
	var hc := TerrainLogic.cell_of(hp.x, hp.y)
	for j in range(hc.y - 1, hc.y + 2):
		for i in range(hc.x - 1, hc.x + 2):
			gs.shovel_sand = 0.0
			gs.flatten_cell(Vector2i(i, j), gs.dig_snap(y + 0.25))
	await tree.snap("prof_attente2", 1.5)
	await tree.shot("prof_terrasse_fond", Vector3(hp.x, 4.5, hp.y - 7.5), Vector3(hp.x, -1.5, hp.y))
	# On descend dans le trou : pas de mer, pas de nage.
	await tree.shot("prof_dans_le_trou", Vector3(hp.x, y + 1.9, hp.y - 1.5), Vector3(hp.x, y + 1.0, hp.y + 6.0))


## Un sommet de l'intérieur de l'île sans objet à 7 m à la ronde.
func _clear_spot(gs: Node) -> Vector2i:
	var ctx: Dictionary = gs._sand_context()
	for r in range(10, 60, 2):
		for a in 16:
			var p := Vector2(cos(TAU * a / 16.0), sin(TAU * a / 16.0)) * r
			var v := TerrainLogic.nearest_vertex(p.x, p.y)
			if not gs.terrain.inland(p.x, p.y):
				continue
			var ok := true
			for dj in range(-14, 15, 2):
				for di in range(-14, 15, 2):
					var q := TerrainLogic.vertex_xz(v + Vector2i(di, dj))
					if not gs._vertex_movable(v + Vector2i(di, dj), ctx) or not gs.terrain.inland(q.x, q.y):
						ok = false
						break
				if not ok:
					break
			if ok:
				return v
	return Vector2i(20, 24)
