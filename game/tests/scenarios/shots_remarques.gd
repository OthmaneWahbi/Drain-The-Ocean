extends RefCounted
## Plan de captures « remarques » (0.1.10) : cuvette, tas dans leurs bacs, noix de coco, caisse,
## jauge, cabine, moulin, matériau en main.


func run(tree: SceneTree, gs: Node) -> void:
	var basin: Dictionary = gs.zones[0]
	basin.logic.water_l = basin.logic.capacity_l * 0.6
	basin.logic.deposit = {"sel": 12, "mineraux": 6, "mineraux_rares": 3}
	print("cuvette ", basin.position, " depot ", gs.depot.position if "depot" in gs else "")
	gs.stock = {"sel": 30, "mineraux": 12, "mineraux_rares": 5, "coquillages": 8, "perles": 2}
	gs.stock_changed.emit()
	var bp: Vector3 = basin.position
	await tree.shot("cuvette", bp + Vector3(0, 0.1, 3.6), bp + Vector3(0, 0.0, 0))
	await tree.shot("cuvette_haut", bp + Vector3(1.5, 1.5, 3.0), bp + Vector3(0, -0.6, 0))
	# Le dépôt (palette).
	for it in gs.movable_items():
		print("item ", it.get("id", ""), " ", it.get("kind", ""), " ", it.position)
	var dep: Dictionary = {}
	for it in gs.movable_items():
		if it.get("id", "") == "depot":
			dep = it
	if not dep.is_empty():
		await tree.shot("palette", dep.position + Vector3(0, 0.2, 3.2), dep.position)
	# Matériau en main.
	gs.add_carried({"sel": 6})
	gs.select_tool(gs.toolbar.index_of("sel"))
	await tree.shot("sel_en_main", bp + Vector3(-3, 0.1, 3), bp + Vector3(-3, 0.3, -3))
	gs.add_carried({"coquillages": 4})
	gs.select_tool(gs.toolbar.index_of("coquillages"))
	await tree.shot("coquillages_en_main", bp + Vector3(-3, 0.1, 3), bp + Vector3(-3, 0.3, -3))
	await tree.shot("ombre_3e", bp + Vector3(-3, 0.1, 3), bp + Vector3(-3, 0.3, -3), true)
	gs.select_tool(0)
	# La jauge et la cabine.
	await tree.shot("jauge", Vector3(3, 0.6, 24.2), Vector3(3, 1.7, 22))
	await tree.shot("cabine", Vector3(5, 0.6, 5.0), Vector3(5, 1.2, 1.5))
	# Les noix de coco sous un palmier.
	var p: Vector3 = gs.config.palms[0]
	await tree.shot("noix", Vector3(p.x + 1.4, 0.0, p.y + 1.4), Vector3(p.x, 0.2, p.y))
