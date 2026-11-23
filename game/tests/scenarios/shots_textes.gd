extends RefCounted
## Plan de captures « textes peints » : chaque texte posé sur un objet, de face, de biais et
## au soir, pour vérifier qu'il a l'air peint dans la matière (éclairé, usé, sans contour).


func run(tree: SceneTree, gs: Node) -> void:
	var main: Node = tree.root.get_node("Main")
	gs.stock = {"sel": 30, "mineraux": 12, "mineraux_rares": 5, "coquillages": 0, "perles": 2}
	gs.stock_changed.emit()
	var crate := Props.crate(0.9)
	crate.position = Vector3(-8, 0.5, 2)
	crate.rotation.y = 0.35
	main.add_child(crate)
	var rations := Props.rations()
	rations.position = Vector3(-6.6, 0.5, 2.3)
	rations.rotation.y = -0.3
	main.add_child(rations)
	var slide := Props.slide()
	slide.position = Vector3(-12, 0.5, -2)
	main.add_child(slide)
	var plane := Props.plane()
	plane.position = Vector3(-18, 2.0, 4)
	plane.rotation.y = PI / 2
	main.add_child(plane)
	await tree._frames(5)
	await tree.shot("caisse_face", Vector3(-7.4, 0.2, 4.2), Vector3(-8, 0.9, 2))
	await tree.shot("caisse_biais", Vector3(-5.6, 0.4, 3.6), Vector3(-7.6, 0.8, 2))
	await tree.shot("rations", Vector3(-6.3, -0.4, 3.6), Vector3(-6.6, 0.7, 2.3))
	await tree.shot("toboggan", Vector3(-12, 1.6, 2.2), Vector3(-12, 2.7, -2))
	await tree.shot("toboggan_pres", Vector3(-12, 1.2, -0.2), Vector3(-12, 2.75, -1.7))
	await tree.shot("rations_pres", Vector3(-6.2, -0.7, 3.2), Vector3(-6.6, 0.75, 2.3))
	await tree.shot("avion_derive", Vector3(-21, 1.5, 7), Vector3(-18, 2.4, 6))
	await tree.shot("avion_derive_pres", Vector3(-16.4, 0.6, 6.2), Vector3(-16.05, 2.45, 4.0))
	for it in gs.movable_items():
		if it.get("id", "") == "depot":
			var d: Vector3 = it.position
			await tree.shot("palette_face", d + Vector3(0, 0.2, 2.6), d + Vector3(0, 0.6, 0))
			await tree.shot("palette_biais", d + Vector3(2.4, 0.3, 2.0), d + Vector3(0, 0.6, 0))
	await tree.shot("cabine_face", Vector3(5, 0.8, 5.0), Vector3(5, 2.0, 1.5))
	await tree.shot("cabine_biais", Vector3(8.0, 0.8, 4.0), Vector3(5, 2.0, 1.5))
	await tree.shot("jauge", Vector3(3, 0.4, 19.6), Vector3(3, 1.6, 22))
	await tree.shot("jauge_pres", Vector3(3.3, 0.0, 20.9), Vector3(3.75, 1.3, 22))
	# Le soir : la peinture s'assombrit avec l'objet (un Label3D restait allumé).
	gs.day.time_s = gs.day.day_length_s * 0.84
	await tree.shot("cabine_soir", Vector3(5, 0.8, 5.0), Vector3(5, 2.0, 1.5))
	await tree.shot("caisse_soir", Vector3(-7.4, 0.2, 4.2), Vector3(-8, 0.9, 2))
