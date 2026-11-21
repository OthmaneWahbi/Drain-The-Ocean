extends RefCounted
## Plan de captures « aplanir » (0.1.15) : un lot de 6 × 6 m préparé en 4 gestes sur la plage
## (carré de 3 × 3 m, niveau choisi tout seul), puis un carré voisin qui se raccorde.


func _center(gs: Node) -> Vector2i:
	for j in range(18, 40):
		for i in range(-12, 12):
			var c := Vector2i(i, j)
			var ok := true
			for dj in range(-4, 8):
				for di in range(-4, 11):
					if not is_nan(gs.terrain.cell_level(c + Vector2i(di, dj))):
						ok = false
			if not ok:
				continue
			var blockers: Array = gs._dig_blockers()
			for dj in range(-1, 5):
				for di in range(-1, 8):
					if gs._cell_reason(c + Vector2i(di, dj), 0.5, blockers) != "":
						ok = false
			if ok:
				return c
	return Vector2i(-6, 25)


func run(tree: SceneTree, gs: Node) -> void:
	gs.has_shovel = true
	gs._sync_toolbar()
	gs.select_tool(gs.toolbar.index_of("pelle"))
	gs.config.shovel_capacity_scoops = 1000
	gs.shovel_sand = 500.0
	var c := _center(gs)
	print("centre ", c)
	var m := Vector3(c.x + 2.0, 0.0, c.y + 2.0)
	m.y = gs.terrain.height(m.x, m.z)
	var at := Vector3(m.x - 5.5, 0.0, m.z - 5.0)
	at.y = gs.terrain.height(at.x, at.z)
	await tree.shot("ap_avant", at, m, true)
	var auto: Array = gs.auto_level(c)
	print("niveau ", auto)
	var y := float(auto[0])
	gs.flatten_area(c, y)
	await tree.snap("ap_anim", 0.06)
	for d in [Vector2i(3, 0), Vector2i(0, 3), Vector2i(3, 3)]:
		gs.flatten_area(c + d, y)
	await tree.snap("ap_attente", 0.6)
	await tree.shot("ap_apres", at, m, true)
	var nb := c + Vector2i(6, 0)
	var auto2: Array = gs.auto_level(nb)
	print("voisin ", auto2, " (le lot est à ", y, ")")
	gs.flatten_area(nb, float(auto2[0]))
	await tree.snap("ap_attente2", 0.6)
	await tree.shot("ap_voisin", at, m + Vector3(2, 0, 0), true)
	await tree.shot("ap_pres", Vector3(m.x - 1.0, m.y, m.z - 3.5), Vector3(m.x, m.y - 0.5, m.z + 0.5))
