extends RefCounted
## Plan de captures « cuvette » : la cuvette de départ sous plusieurs angles, peu remplie et
## pleine (remarque d'Othmane : bord coupé, eau visible de travers).


func run(tree: SceneTree, gs: Node) -> void:
	gs.day.time_s = gs.day.day_length_s * (12.0 / 24.0)
	var z: Dictionary = gs.zones[0]
	var c: Vector3 = z.position
	var look := c + Vector3(0, 0.1, 0)
	for fill in [0.15, 1.0]:
		(z.logic as DryingLogic).water_l = (z.logic as DryingLogic).capacity_l * fill
		for k in 4:
			var a := TAU * k / 4.0 + 0.4
			var eye := c + Vector3(cos(a) * 3.2, 0.0, sin(a) * 3.2)
			eye.y = gs.terrain.height(eye.x, eye.z) + 0.35
			await tree.shot("cuvette_%d_bas_%d" % [int(fill * 100), k], eye, look)
		await tree.shot("cuvette_%d_haut" % int(fill * 100), c + Vector3(2.0, 2.2, 2.0), look)
