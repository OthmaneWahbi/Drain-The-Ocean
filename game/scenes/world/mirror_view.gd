extends StaticBody3D
## Le miroir solaire (T2) : un panneau brillant sur pied. Il ne fait rien lui-même :
## GameState.zone_boost() compte les miroirs proches de chaque zone.

var mirror: Dictionary


func setup(m: Dictionary) -> void:
	mirror = m
	position = m.position
	add_child(Greybox.cylinder(0.05, 1.0, Greybox.ROCK, Vector3(0, 0.5, 0), 6))
	var panel := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.2, 0.04, 0.9)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.92, 1.0)
	mat.metallic = 1.0
	mat.roughness = 0.05
	box.material = mat
	panel.mesh = box
	panel.position = Vector3(0, 1.05, 0)
	panel.rotation_degrees = Vector3(35, 0, 0)
	add_child(panel)
	# Le cercle d'effet, à peine visible au sol.
	var ring := Greybox.cylinder(GameState.config.mirror_radius_m, 0.01, Color(1, 0.95, 0.6, 0.12), Vector3(0, 0.02, 0), 32)
	add_child(ring)
	add_child(Greybox.box_collision(Vector3(1.2, 1.3, 0.9), Vector3(0, 0.65, 0)))


func get_prompt(_player: Node) -> String:
	return tr("MIRROR_STATE") % int(GameState.config.mirror_bonus * 100.0)


## Ce que la touche G déplace (voir placement_controller.gd).
func get_movable() -> Dictionary:
	return mirror
