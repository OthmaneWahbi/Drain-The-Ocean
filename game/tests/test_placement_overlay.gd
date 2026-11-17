extends TestCase
## 0.1.7 (Othmane : « en mode G, les graphismes clignotent ») : l'aperçu ne doit jamais se battre
## avec le sol, le rayon de visée ne doit jamais toucher l'objet déplacé, et l'objet ne doit pas
## sauter d'une case à l'autre au ras d'une ligne de la grille.

const GameStateScript := preload("res://core/game_state.gd")


func test_overlay_floats_above_the_ground_everywhere() -> void:
	var gs: Node = GameStateScript.new()
	gs.setup(load("res://data/game_config.tres").duplicate())
	var water: float = gs.water_level_y()
	var lifts := [PlacementController.LIFT_FOOT, PlacementController.LIFT_FILL, PlacementController.LIFT_GRID, PlacementController.LIFT_LINE]
	for i in range(1, lifts.size()):
		assert_true(float(lifts[i]) > float(lifts[i - 1]), "chaque couche au-dessus de la précédente")
	# Partout où l'on peut poser (plateau, plage, bord de l'eau, dunes), un pas de carreau à la fois.
	for x in range(-30, 31, 3):
		for z in range(-30, 31, 3):
			for dx in [0.0, PlacementController.DRAPE_STEP * 0.5]:
				var px: float = float(x) + float(dx)
				var ground: float = gs.terrain.height(px, float(z))
				var y := PlacementController.draped_y(gs.terrain, water, -INF, px, float(z), PlacementController.LIFT_FOOT)
				assert_true(y - maxf(ground, water) >= 0.05 - 1e-6, "(%f, %d) : %f au-dessus" % [px, z, y - ground])
	# Sur l'eau, une pompe : l'aperçu reste au niveau de sa plateforme, pas sur le fond.
	var y_pump := PlacementController.draped_y(gs.terrain, water, 0.5, 0.0, 34.0, PlacementController.LIFT_FOOT)
	assert_true(y_pump >= 0.5, "au niveau de la plateforme")
	gs.free()


func test_aim_ignores_every_body_of_the_moved_object() -> void:
	# Une zone de séchage a ses tas, qui sont des corps à part : le rayon ne doit pas les toucher.
	var root := StaticBody3D.new()
	var model := Node3D.new()
	root.add_child(model)
	var pile := StaticBody3D.new()
	model.add_child(pile)
	var other := Area3D.new()
	root.add_child(other)
	var rids := PlacementController.bodies_of(root)
	assert_eq(rids.size(), 3)
	assert_true(rids.has(root.get_rid()) and rids.has(pile.get_rid()) and rids.has(other.get_rid()))
	root.free()


func test_the_object_does_not_jitter_on_a_grid_line() -> void:
	var cur := Vector3(2.5, 0.5, 0.5)
	var next := Vector3(3.5, 0.5, 0.5)
	# Pile sur la ligne x = 3, ou à peine après : on garde la case.
	assert_true(PlacementController.keep_target(cur, next, Vector3(3.0, 0.5, 0.5), true))
	assert_true(PlacementController.keep_target(cur, next, Vector3(3.05, 0.5, 0.5), true))
	# Nettement dans la nouvelle case : on y va.
	assert_false(PlacementController.keep_target(cur, next, Vector3(3.2, 0.5, 0.5), true))
	# Après avoir tourné l'objet, ou pour un grand saut, on suit tout de suite.
	assert_false(PlacementController.keep_target(cur, next, Vector3(3.0, 0.5, 0.5), false))
	assert_false(PlacementController.keep_target(cur, Vector3(8.5, 0.5, 0.5), Vector3(8.4, 0.5, 0.5), true))
	assert_false(PlacementController.keep_target(cur, cur, Vector3(2.4, 0.5, 0.5), true))
