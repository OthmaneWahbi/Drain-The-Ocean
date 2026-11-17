extends StaticBody3D
## Objets décoratifs (gags). Le « bateau » commandé arrive… en bouteille (Q-12, M-53).
## C'est un corps physique pour qu'on puisse le viser et le déplacer (G).

var decor: Dictionary


func setup(p_decor: Dictionary) -> void:
	decor = p_decor
	position = decor.position
	# Les mêmes modèles que les photos du catalogue (ProductModels), à la taille réelle.
	match decor.kind:
		"bateau_en_bouteille":
			var boat := ProductModels.build("bateau")
			boat.scale = Vector3.ONE * 0.5
			add_child(boat)
		"flamant":
			# Le flamant rose gonflable payé en perle : un gag qui ne sert à rien.
			var bird := ProductModels.build("flamant")
			bird.scale = Vector3.ONE * 0.8
			add_child(bird)
		"catalogue_papier":
			# Le catalogue papier du premier appel : un gros livret rouge et blanc.
			add_child(Greybox.box(Vector3(0.42, 0.06, 0.3), Color(0.95, 0.95, 0.9), Vector3(0, 0.03, 0)))
			add_child(Greybox.box(Vector3(0.43, 0.012, 0.31), Greybox.PHONE_RED, Vector3(0, 0.066, 0)))
	add_child(Greybox.box_collision(Vector3(0.6, 0.3, 0.3), Vector3(0, 0.12, 0)))


func get_prompt(_player: Node) -> String:
	return ""  # le joueur ajoute « [G] Déplacer » tout seul


func get_movable() -> Dictionary:
	return decor
