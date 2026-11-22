extends RefCounted
## Plan de captures « polices » (0.1.17) : tous les écrans où il y a du texte, pour comparer les
## polices. HUD en jeu, palette (Label3D), cabine, catalogue, dialogue, menu pause, menu principal.


func _close_all(tree: SceneTree, main: Node) -> void:
	tree.call_group(&"catalogue", &"close_catalogue")
	tree.call_group(&"dialogue", &"hang_up")
	for n in ["PauseMenu", "MainMenu"]:
		var m: Node = main.get_node_or_null(n)
		if m and m.has_method("is_open") and m.is_open():
			m.get("_root").visible = false
	tree.paused = false
	await tree._frames(5)


func run(tree: SceneTree, gs: Node) -> void:
	var main: Node = tree._main
	gs.stock = {"sel": 30, "mineraux": 12, "mineraux_rares": 5, "coquillages": 8, "perles": 2}
	gs.stock_changed.emit()
	gs.add_carried({"sel": 6})
	var basin: Dictionary = gs.zones[0]
	basin.logic.deposit = {"sel": 12, "mineraux": 6}
	var bp: Vector3 = basin.position
	await tree.shot("hud", bp + Vector3(0, 0.1, 3.2), bp)
	for it in gs.movable_items():
		if it.get("id", "") == "depot":
			await tree.shot("palette", it.position + Vector3(0, 0.6, 3.0), it.position + Vector3(0, 0.6, 0))
	await tree.shot("cabine", Vector3(5, 0.6, 5.0), Vector3(5, 1.2, 1.5))
	tree.call_group(&"catalogue", &"open_catalogue")
	await tree.snap("catalogue", 0.5)
	await _close_all(tree, main)
	tree.call_group(&"dialogue", &"start", "offer")
	await tree.snap("dialogue", 0.8)
	await _close_all(tree, main)
	main.get_node("PauseMenu").open_menu()
	await tree.snap("pause", 0.3)
	await _close_all(tree, main)
	main.get_node("MainMenu").open_menu()
	await tree.snap("menu", 0.3)
