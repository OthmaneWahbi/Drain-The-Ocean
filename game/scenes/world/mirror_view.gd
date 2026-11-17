extends StaticBody3D
## Le miroir solaire (T2) : un panneau brillant sur pied. Il ne fait rien lui-même :
## GameState.zone_boost() compte les miroirs proches de chaque zone.

var mirror: Dictionary


func setup(m: Dictionary) -> void:
	mirror = m
	position = m.position
	add_child(Props.mirror())  # un chevalet et un grand cadre jaune incliné
	# Le cercle d'effet, à peine visible au sol.
	var ring := Greybox.cylinder(GameState.config.mirror_radius_m, 0.01, Color(1, 0.95, 0.6, 0.12), Vector3(0, 0.02, 0), 32)
	add_child(ring)
	add_child(Greybox.box_collision(Vector3(1.2, 1.3, 0.9), Vector3(0, 0.65, 0)))


func get_prompt(_player: Node) -> String:
	return tr("MIRROR_STATE") % int(GameState.config.mirror_bonus * 100.0)


## Ce que la touche G déplace (voir placement_controller.gd).
func get_movable() -> Dictionary:
	return mirror
