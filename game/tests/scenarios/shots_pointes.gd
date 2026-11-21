extends RefCounted
## Plan de captures « pointes » (0.1.15) : un trou de quelques pelletées vu comme Othmane
## (les pointes triangulaires autour), et un tas.


func run(tree: SceneTree, gs: Node) -> void:
	gs.has_shovel = true
	gs._sync_toolbar()
	gs.select_tool(gs.toolbar.index_of("pelle"))
	var hv := Vector2i(-15, -37)
	var hp := TerrainLogic.vertex_xz(hv)
	for k in 12:
		gs.shovel_sand = 0.0
		gs.shovel_scoop(hv, true)
	var tv := hv + Vector2i(14, 0)
	for k in 12:
		gs.shovel_sand = 3.0
		gs.shovel_scoop(tv, false)
	gs.day.time_s = gs.day.day_length_s * 0.66  # soleil plus bas, comme sur la capture d'Othmane
	await tree.snap("pt_attente", 1.5)
	await tree.shot("pt_trou", Vector3(hp.x, 2.6, hp.y - 2.0), Vector3(hp.x, -0.3, hp.y + 0.3))
	await tree.shot("pt_trou_loin", Vector3(hp.x + 1, 2.5, hp.y - 6.0), Vector3(hp.x, -0.3, hp.y))
	# Un grand trou creusé en glissant (comme sur la capture d'Othmane), vu de haut.
	var bv := hv + Vector2i(0, 24)
	var bp := TerrainLogic.vertex_xz(bv)
	for r in 4:
		for dy in range(-4, 5, 2):
			for dx in range(-4, 5, 2):
				gs.shovel_sand = 0.0
				gs.shovel_scoop(bv + Vector2i(dx, dy), true)
	await tree.snap("pt_attente2", 1.0)
	await tree.shot("pt_grand", Vector3(bp.x + 0.5, 9.0, bp.y - 5.0), Vector3(bp.x, -1.0, bp.y + 0.5))
	await tree.shot("pt_tas", Vector3(hp.x + 7, 2.5, hp.y - 5.0), Vector3(hp.x + 7, 0.5, hp.y))
