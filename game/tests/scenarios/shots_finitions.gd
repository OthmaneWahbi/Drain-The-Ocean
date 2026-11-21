extends RefCounted
## Plan de captures « finitions » (0.1.13) : le tas sur la pelle, le compteur de la barre, une
## zone nivelée qui se fond dans le sable, un trou près du niveau de la mer (pas d'eau dedans).


func run(tree: SceneTree, gs: Node) -> void:
	gs.has_shovel = true
	gs._sync_toolbar()
	gs.select_tool(gs.toolbar.index_of("pelle"))
	gs.shovel_sand = 1.5
	gs.shovel_changed.emit()
	await tree.shot("fin_pelle_moitie", Vector3(3, 0.6, 12), Vector3(3, 0.0, 14.5))
	gs.shovel_sand = 3.0
	gs.shovel_changed.emit()
	await tree.shot("fin_pelle_pleine", Vector3(3, 0.6, 12), Vector3(3, 0.0, 14.5))
	await tree.shot("fin_pelle_pleine_3e", Vector3(3, 0.6, 12), Vector3(3, 0.0, 14.5), true)
	# Une terrasse nivelée sur la pente de la plage.
	gs.config.shovel_capacity_scoops = 99
	gs.shovel_sand = 40.0
	for j in range(22, 25):
		for i in range(-8, -4):
			gs.flatten_cell(Vector2i(i, j), 0.75)
	await tree.shot("fin_terrasse", Vector3(-6, 0.6, 17), Vector3(-6, 0.6, 23))
	await tree.shot("fin_terrasse_haut", Vector3(-3, 2.5, 20), Vector3(-6.5, 0.6, 23.5))
	# Des trous jusqu'au plancher, près de la mer et sur le plateau.
	for k in 10:
		gs.shovel_scoop(Vector2i(4, 58), true)
		gs.shovel_scoop(Vector2i(8, 24), true)
	await tree.snap("fin_attente", 1.0)
	# (sommets (4, 58) et (8, 24) = points (2, 29) et (4, 12) en mètres ; vus d'en haut.)
	await tree.shot("fin_trou_plage", Vector3(2, 2.6, 26.5), Vector3(2, 0.0, 29))
	await tree.shot("fin_trou_plateau", Vector3(4, 3.0, 9.5), Vector3(4, 0.3, 12))
