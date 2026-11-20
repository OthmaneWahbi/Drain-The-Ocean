extends RefCounted
## Plan de captures « sable » (0.1.11) : le sable de près et de loin, une terrasse et un trou
## faits à la pelle, un coup de pelle en pleine animation.


func run(tree: SceneTree, gs: Node) -> void:
	if "has_shovel" in gs:
		gs.has_shovel = true
		gs._sync_toolbar()
		gs.config.shovel_capacity_scoops = 99
		gs.shovel_sand = 40
	gs.select_tool(gs.toolbar.index_of("pelle"))
	await tree.shot("sable_plage", Vector3(0, 0.6, 16), Vector3(0, 0.2, 26))
	await tree.shot("sable_pres", Vector3(3, 0.6, 12), Vector3(3, 0.0, 14.5))
	await tree.shot("sable_dunes", Vector3(-22, 0.6, -2), Vector3(-30, 1.5, -6))
	# Une terrasse de 4 × 3 cases sur la pente de la plage, un trou et une butte sur le plateau.
	for j in range(22, 25):
		for i in range(-8, -4):
			gs.work_cell(Vector2i(i, j), gs.Dig.FLATTEN, 0.75)
	for k in 2:
		gs.work_cell(Vector2i(-3, 12), gs.Dig.DIG)
	for k in 3:
		gs.work_cell(Vector2i(-1, 12), gs.Dig.RAISE)
	await tree.shot("sable_terrasse", Vector3(-6, 0.6, 17), Vector3(-6, 0.6, 23))
	await tree.shot("sable_trou_butte", Vector3(-2, 0.6, 16), Vector3(-2, 0.5, 12))
	await tree.shot("sable_3e", Vector3(-6, 0.6, 19), Vector3(-6, 0.5, 23), true)
	# Un coup de pelle saisi en plein vol (creuser, puis remblayer), au ralenti.
	await tree.shot("sable_avant_coup", Vector3(2, 0.6, 9), Vector3(2, 0.3, 6.5))
	gs.work_cell(Vector2i(2, 6), gs.Dig.DIG)
	await tree.snap("sable_coup_creuser", 0.06)
	await tree.snap("sable_coup_creuser_2", 0.1)
	await tree.snap("sable_coup_creuser_fin", 0.6)
	gs.work_cell(Vector2i(3, 6), gs.Dig.RAISE)
	await tree.snap("sable_coup_remblayer", 0.08)
	await tree.snap("sable_coup_remblayer_2", 0.14)
	await tree.snap("sable_coup_remblayer_fin", 0.6)
	# Le catalogue : la pelle est en vente dès le début.
	var cat: Node = tree.get_first_node_in_group(&"catalogue")
	if cat:
		gs.has_shovel = false
		gs.owned.erase("pelle")
		cat.open_catalogue()
		await tree.snap("sable_catalogue", 0.5)
		cat.close_catalogue()
