extends RefCounted
## Plan de captures « modèles » (0.1.10) : moulin-pompe, caisse, condenseur, palette, noix.


func run(tree: SceneTree, gs: Node) -> void:
	var main: Node = tree.root.get_node("Main")
	var mill := Props.windmill()
	mill.position = Vector3(-12, 0.5, 0)
	main.add_child(mill)
	var crate := Props.crate(0.9)
	crate.position = Vector3(-8, 0.5, 2)
	crate.rotation.y = 0.4
	main.add_child(crate)
	var cond := Props.condenser()
	cond.position = Vector3(-8, 0.5, -2)
	main.add_child(cond)
	var nut := Models.coconut(0.15, 5)
	nut.position = Vector3(-6, 0.65, 0.5)
	main.add_child(nut)
	var nut2 := Models.coconut(0.15, 9)
	nut2.position = Vector3(-6.3, 0.62, 0.9)
	nut2.rotation.x = 1.2
	main.add_child(nut2)
	gs.stock = {"sel": 30, "mineraux": 12, "mineraux_rares": 5, "coquillages": 8, "perles": 2}
	gs.stock_changed.emit()
	await tree.shot("moulin", Vector3(-12, 0.6, 7), Vector3(-12, 2.6, 0))
	await tree.shot("caisse_condenseur", Vector3(-4.5, 0.6, 0), Vector3(-8, 0.4, 0))
	await tree.shot("noix_pres", Vector3(-5.0, -0.3, 1.0), Vector3(-6, 0.6, 0.6))
	await tree.shot("palette", Vector3(9, 0.8, 11.6), Vector3(9, 0.3, 9))
