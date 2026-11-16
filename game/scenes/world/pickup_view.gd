extends StaticBody3D
## Un petit objet à ramasser avec E (noix de coco, coquillage). Aucune règle ici :
## `interact` demande à GameState, qui décide (manger, mettre dans les bras…).

var pickup: Dictionary


func setup(p: Dictionary) -> void:
	pickup = p
	PhysicsLayers.make_walk_through(self)  # petits objets : on passe à travers
	position = p.position
	match p.kind:
		"coconut":
			var nut := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.16
			sphere.height = 0.3
			sphere.radial_segments = 8
			sphere.rings = 5
			sphere.material = Greybox.material(Color(0.4, 0.27, 0.15))
			nut.mesh = sphere
			add_child(nut)
			add_child(Greybox.cylinder_collision(0.3, 0.4))
		"shell":
			var shell := Greybox.cylinder(0.1, 0.04, Color(0.95, 0.8, 0.75), Vector3.ZERO, 7)
			shell.scale = Vector3(1.0, 1.0, 0.7)
			add_child(shell)
			add_child(Greybox.cylinder_collision(0.3, 0.3))


func get_prompt(_player: Node) -> String:
	match pickup.kind:
		"coconut":
			return tr("PROMPT_COCONUT")
		"shell":
			if not GameState.has_slot_for("coquillages"):
				return tr("PROMPT_NO_SLOT") % tr("RES_COQUILLAGES")
			return tr("PROMPT_SHELL") if GameState.carry_space() > 0 else tr("PROMPT_HANDS_FULL")
	return ""


func interact(_player: Node) -> void:
	GameState.take_pickup(pickup)
