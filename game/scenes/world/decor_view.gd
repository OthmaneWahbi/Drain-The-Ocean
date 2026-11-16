extends Node3D
## Objets décoratifs (gags). Le « bateau » commandé arrive… en bouteille (Q-12, M-53).


func setup(decor: Dictionary) -> void:
	position = decor.position
	match decor.kind:
		"bateau_en_bouteille":
			var bottle := Greybox.cylinder(0.12, 0.5, Color(0.7, 0.9, 0.8, 0.35), Vector3(0, 0.12, 0), 12)
			bottle.rotation.z = PI / 2
			add_child(bottle)
			add_child(Greybox.box(Vector3(0.25, 0.05, 0.08), Greybox.WOOD, Vector3(0, 0.1, 0)))
			add_child(Greybox.box(Vector3(0.01, 0.12, 0.06), Color.WHITE, Vector3(0, 0.18, 0)))
