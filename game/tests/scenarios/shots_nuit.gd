extends RefCounted
## Plan de captures « nuit » (0.1.21) : le hamac, la vitrine (à moitié remplie), la nuit
## (plancton, lucioles), le récif vu au masque.


func _ground(gs: Node, x: float, z: float) -> Vector3:
	return Vector3(x, gs.terrain.height(x, z) + 0.05, z)


func run(tree: SceneTree, gs: Node) -> void:
	gs.day.time_s = gs.day.day_length_s * (16.0 / 24.0)
	var hamac := _ground(gs, -6.0, 6.0)
	var vitrine := _ground(gs, -2.0, 7.5)
	gs.apply_item(gs.catalog.find(&"hamac"), hamac)
	gs.apply_item(gs.catalog.find(&"vitrine"), vitrine)
	for id in ["coq_petoncle", "coq_bigorneau", "coq_conque", "etoile_de_mer", "perle", "poisson_clown", "raie"]:
		gs.add_to_collection(id)
	await tree.shot("nuit_hamac_jour", _ground(gs, -6.0, 9.5), hamac + Vector3(0, 0.6, 0))
	await tree.shot("nuit_vitrine", _ground(gs, -2.0, 9.8), vitrine + Vector3(0, 0.7, 0))
	gs.day.time_s = gs.day.day_length_s * (22.5 / 24.0)
	gs.simulate(0.1)
	await tree.snap("nuit_hamac_nuit", 1.0)
	await tree.shot("nuit_hamac_lune", _ground(gs, -6.0, 9.5), hamac + Vector3(0, 0.6, 0))
	await tree.shot("nuit_plage", _ground(gs, 0.0, 0.0), Vector3(30, 0, 0))
	# Le récif, au masque.
	gs.day.time_s = gs.day.day_length_s * (11.0 / 24.0)
	gs.apply_item(gs.catalog.find(&"masque"), Vector3.ZERO)
	gs.simulate(0.1)
	if not gs.reef_shells.is_empty():
		var r: Vector3 = gs.reef_shells[0]
		var out := Vector3(r.x, 0, r.z).normalized()
		await tree.shot("nuit_recif_masque", r + out * 2.2 + Vector3(0, 1.0, 0), r)
