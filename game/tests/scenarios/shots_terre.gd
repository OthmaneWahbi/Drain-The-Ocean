extends RefCounted
## Plan de captures « terre » (0.1.16) : une zone verte (de la terre), creusée, avec de la terre
## posée sur le sable et du sable posé sur l'herbe ; un lot aplani dans le sable et dans la terre.


## Un sommet d'herbe sur une large plaque verte, que la pelle peut travailler.
func _grass_vertex(gs: Node) -> Vector2i:
	var best := Vector2i(52, -14)
	var best_n := -1
	for j in range(-60, 60, 3):
		for i in range(-60, 60, 3):
			var v := Vector2i(i, j)
			if not gs.terrain.grassy(v) or gs.scoop_reason(v, true) != "":
				continue
			var n := 0
			for dj in range(-6, 7, 2):
				for di in range(-6, 7, 2):
					if gs.terrain.grassy(v + Vector2i(di, dj)):
						n += 1
			if n > best_n:
				best_n = n
				best = v
	print("herbe ", best, " (", best_n, "/49)")
	return best


func run(tree: SceneTree, gs: Node) -> void:
	gs.has_shovel = true
	gs._sync_toolbar()
	gs.select_tool(gs.toolbar.index_of("pelle"))
	gs.shovel_sand = 0.0
	var g := _grass_vertex(gs)
	var gp := TerrainLogic.vertex_xz(g)
	var gy: float = gs.terrain.height(gp.x, gp.y)
	var cam := Vector3(gp.x - 2.0, gy, gp.y - 4.0)
	cam.y = gs.terrain.height(cam.x, cam.z)
	var look := Vector3(gp.x + 1.0, gy - 0.5, gp.y + 1.0)
	await tree.shot("te_avant", cam, look)
	# Creuser la terre : la pelle porte de la terre.
	var cnt := [0, 0]
	for k: Vector2i in SandPhysics.brush(g, gs.config.dig_brush_radius_m):
		cnt[gs.terrain.soil(k)] += 1
	print("brosse sable/terre ", cnt, " plan ", gs._cut_soil(gs._plan_scoop(g, true, gs._sand_context()).heights))
	gs.shovel_sand = 0.0
	for k in 3:
		gs.shovel_scoop(g, true)
	print("pelle : ", gs.shovel_sand, " ", "terre" if gs.shovel_soil == TerrainLogic.Soil.EARTH else "sable")
	await tree.snap("te_attente", 0.6)
	await tree.shot("te_trou", cam, look)
	# La terre posée sur le sable, un peu plus loin.
	var sand_v := g
	for d in range(4, 40, 2):
		var v := g + Vector2i(-d, d)
		if gs.terrain.soil(v) == TerrainLogic.Soil.SAND and gs.scoop_reason(v, false) == "":
			sand_v = v
			break
	for k in 3:
		gs.shovel_scoop(sand_v, false)
	# Du sable posé sur l'herbe.
	gs.shovel_sand = 3.0
	gs.shovel_soil = TerrainLogic.Soil.SAND
	for k in 3:
		gs.shovel_scoop(g + Vector2i(5, 3), false)
	await tree.snap("te_attente2", 0.8)
	await tree.shot("te_melange", cam, look)
	var sp := TerrainLogic.vertex_xz(sand_v)
	await tree.shot("te_terre_sur_sable", Vector3(sp.x - 2.5, gs.terrain.height(sp.x - 2.5, sp.y - 3.0), sp.y - 3.0), Vector3(sp.x, gs.terrain.height(sp.x, sp.y), sp.y))
	# Aplanir un carré dans la terre (sillons) et un dans le sable (dalles).
	gs.config.shovel_capacity_scoops = 1000
	gs.shovel_sand = 0.0
	var gc := TerrainLogic.cell_of(gp.x + 3.0, gp.y + 3.0)
	var lv: Array = gs.auto_level(gc)
	print("aplanir terre ", lv, " -> ", gs.level_plan(gc, float(lv[0]))[2])
	gs.flatten_area(gc, float(lv[0]))
	await tree.snap("te_attente3", 0.6)
	var cp := Vector3(gc.x + 0.5, float(lv[0]), gc.y + 0.5)
	await tree.shot("te_terre_aplanie", Vector3(cp.x - 1.5, cp.y, cp.z - 3.5), cp + Vector3(0, -0.6, 0.5))
	# Un lot de sable aplani, de près (le plateau, devant le camp).
	gs.shovel_sand = 500.0
	gs.shovel_soil = TerrainLogic.Soil.SAND
	var sc := Vector2i(3, 9)
	for j in range(0, 16):
		for i in range(-10, 10):
			var c := Vector2i(i, j)
			if (gs.level_plan(c, 0.25)[0] as Array).size() == 9 and (gs.level_plan(c + Vector2i(3, 0), 0.25)[0] as Array).size() == 9:
				sc = c
				break
		if sc != Vector2i(3, 9):
			break
	var sl := float(gs.auto_level(sc)[0])
	for d in [Vector2i(0, 0), Vector2i(3, 0)]:
		print("aplanir sable ", sc + d, " ", gs.level_plan(sc + d, sl - 0.25), " ", gs.flatten_area(sc + d, sl - 0.25))
	await tree.snap("te_attente4", 0.6)
	var sp2 := Vector3(sc.x + 2.0, sl, sc.y + 0.5)
	await tree.shot("te_sable_aplani", Vector3(sp2.x - 1.0, sl, sp2.z - 3.5), sp2 + Vector3(0, -0.6, 0.5))
