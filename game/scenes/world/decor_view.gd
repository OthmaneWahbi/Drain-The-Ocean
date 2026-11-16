extends StaticBody3D
## Objets décoratifs (gags). Le « bateau » commandé arrive… en bouteille (Q-12, M-53).
## C'est un corps physique pour qu'on puisse le viser et le déplacer (G).

var decor: Dictionary


func setup(p_decor: Dictionary) -> void:
	decor = p_decor
	position = decor.position
	match decor.kind:
		"bateau_en_bouteille":
			var bottle := Greybox.cylinder(0.12, 0.5, Color(0.7, 0.9, 0.8, 0.35), Vector3(0, 0.12, 0), 12)
			bottle.rotation.z = PI / 2
			add_child(bottle)
			add_child(Greybox.box(Vector3(0.25, 0.05, 0.08), Greybox.WOOD, Vector3(0, 0.1, 0)))
			add_child(Greybox.box(Vector3(0.01, 0.12, 0.06), Color.WHITE, Vector3(0, 0.18, 0)))
	add_child(Greybox.box_collision(Vector3(0.6, 0.3, 0.3), Vector3(0, 0.12, 0)))


func get_prompt(_player: Node) -> String:
	return ""  # le joueur ajoute « [G] Déplacer » tout seul


func get_movable() -> Dictionary:
	return decor
