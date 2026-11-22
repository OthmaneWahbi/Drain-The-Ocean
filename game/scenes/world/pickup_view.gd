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
			# La même noix de coco que sur les palmiers (Models.coconut), posée sur le sable.
			var nut := Models.coconut(0.15, int(absf(p.position.x * 13.0 + p.position.z * 7.0)))
			nut.position.y = 0.1
			nut.rotation = Vector3(0.6, p.position.x, 0.3)
			add_child(nut)
			add_child(Greybox.cylinder_collision(0.3, 0.4))
		"shell":
			# Une vraie coquille (Saint-Jacques ou conque, selon l'endroit), qui brille un peu pour
			# qu'on la repère sur le sable.
			var variant := int(absf(p.position.x * 3.0 + p.position.z * 5.0))
			var shell := Props.shell(variant, 0.22)
			var t := Props.on_sand(GameState.terrain, p.position, 0.12, p.position.x)
			t.origin -= p.position
			shell.transform = t
			add_child(shell)
			add_child(Greybox.cylinder_collision(0.3, 0.3))
		"bottle":
			# 0.1.23 : une bouteille à la mer échouée, à moitié dans le sable.
			var b := IslandGoods.bottle()
			b.rotation.y = p.position.x
			add_child(b)
			add_child(Greybox.cylinder_collision(0.3, 0.3))


func get_prompt(_player: Node) -> String:
	match pickup.kind:
		"coconut":
			# 0.1.23 : mains vides, un clic la garde (pour la planter) ; E la mange toujours.
			if GameState.current_tool() == "":
				return "%s · %s" % [tr("PROMPT_COCONUT"), tr("PROMPT_PICK_COCONUT")]
			return tr("PROMPT_COCONUT")
		"bottle":
			return tr("PROMPT_BOTTLE")
		"shell":
			if not GameState.has_slot_for("coquillages"):
				return tr("PROMPT_NO_SLOT") % tr("RES_COQUILLAGES")
			return tr("PROMPT_SHELL") if GameState.carry_space("coquillages") > 0 else tr("PROMPT_HANDS_FULL")
	return ""


func interact(_player: Node) -> void:
	GameState.take_pickup(pickup)


## Clic, mains vides, sur une noix de coco : elle va dans la barre (0.1.23).
func use(_player: Node) -> void:
	if pickup.kind == "coconut":
		GameState.pick_coconut(pickup)
