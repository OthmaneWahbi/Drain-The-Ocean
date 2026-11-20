extends RefCounted
## Plan de captures « pelle » : une terrasse aplanie sur la plage, un trou, une butte.


func run(tree: SceneTree, gs: Node) -> void:
	gs.select_tool(gs.toolbar.index_of("pelle"))
	# Une terrasse de 4 × 3 cases, aplanie sur la pente de la plage (au sud).
	for j in range(22, 25):
		for i in range(-8, -4):
			gs.work_cell(Vector2i(i, j), gs.Dig.FLATTEN, 0.75)
	# Un trou et une butte sur le plateau.
	for k in 2:
		gs.work_cell(Vector2i(-3, 12), gs.Dig.DIG)
	for k in 3:
		gs.work_cell(Vector2i(-1, 12), gs.Dig.RAISE)
	await tree.shot("pelle_terrasse", Vector3(-6, 0.6, 17), Vector3(-6, 0.6, 23))
	await tree.shot("pelle_trou_butte", Vector3(-2, 0.6, 16), Vector3(-2, 0.5, 12))
	await tree.shot("pelle_viser", Vector3(-2, 0.6, 15), Vector3(-2, 0.4, 12.6))
	await tree.shot("pelle_3e", Vector3(-6, 0.6, 19), Vector3(-6, 0.5, 23), true)
