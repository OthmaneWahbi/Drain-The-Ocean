extends StaticBody3D
## Le téléphone rouge. Interagir (E) ouvre le catalogue de l'agence.


func _ready() -> void:
	add_child(Greybox.box(Vector3(0.9, 2.2, 0.9), Greybox.PHONE_RED, Vector3(0, 1.1, 0)))
	add_child(Greybox.box(Vector3(0.35, 0.12, 0.12), Color(0.1, 0.1, 0.1), Vector3(0, 1.4, 0.5)))
	add_child(Greybox.box_collision(Vector3(0.9, 2.2, 0.9), Vector3(0, 1.1, 0)))


func get_prompt(_player: Node) -> String:
	return tr("PROMPT_PHONE")


func interact(_player: Node) -> void:
	get_tree().call_group(&"catalogue", &"open_catalogue")
