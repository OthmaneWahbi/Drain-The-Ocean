extends TestCase
## Les modèles de la version 0.1.4 (Props) : chaque objet du jeu a un vrai modèle, posé au sol,
## et les pièces animées que les vues retrouvent par leur nom.


func _height(n: Node3D) -> float:
	return Models.bounds(Models.vertices(n)).size.y


func test_each_resource_pile_looks_like_its_content() -> void:
	for r in Economy.RESOURCES:
		var pile := Props.pile(r, 3)
		assert_true(pile.get_child_count() > 5, "%s : un monticule et des morceaux" % r)
		var box := Models.bounds(Models.vertices(pile))
		assert_almost(box.position.y, 0.0, 0.08, "%s posé au sol" % r)
		assert_true(box.size.y > 0.25 and box.size.y < 0.7, "%s : hauteur %f" % [r, box.size.y])
		pile.free()


func test_shells_are_scallops_and_conchs() -> void:
	for v in 4:
		var s := Props.shell(v, 0.22)
		var box := Models.bounds(Models.vertices(s))
		assert_true(box.size.x > 0.1 and box.size.x < 0.5, "taille d'un coquillage : %s" % box.size)
		s.free()


func test_bucket_water_rises_with_fill() -> void:
	var b := Props.bucket(false, 0.26)
	var water: MeshInstance3D = b.get_node("Water")
	Props.set_bucket_fill(b, 0.0)
	assert_false(water.visible, "seau vide : pas d'eau")
	Props.set_bucket_fill(b, 0.3)
	var low := water.position.y
	Props.set_bucket_fill(b, 1.0)
	assert_true(water.visible)
	assert_true(water.position.y > low, "l'eau monte")
	assert_true(water.position.y < 0.26, "sous le bord")
	b.free()


func test_animated_parts_have_their_names() -> void:
	var pump := Props.hand_pump()
	assert_true(pump.get_node_or_null("Lever") != null)
	var mill := Props.windmill()
	assert_true(mill.get_node_or_null("Blades") != null)
	assert_true(_height(mill) > 4.0, "un moulin haut")
	var plane := Props.plane()
	assert_true(plane.get_node_or_null("Propeller") != null)
	assert_true(plane.get_node_or_null("Cockpit") != null)
	for kind in ["cuvette", "bache", "bassin_bois"]:
		var z := Props.drying_zone(kind)
		assert_true(z.get_node_or_null("Water") != null, kind)
		assert_true(float(z.get_meta("water_max")) > float(z.get_meta("water_min")), kind)
		z.free()
	for n in [pump, mill, plane]:
		n.free()


func test_animated_characters_are_measured_in_their_pose() -> void:
	# Les personnages CC0 sont animés : leur taille se lit avec les os, pas sur le maillage brut.
	var c := Props.character("mini_male_a", 1.75, "walk")
	var h := _height(c)
	assert_true(h > 1.6 and h < 1.9, "hauteur du joueur : %f" % h)
	c.free()
	var crab := Props.character("crab", 0.3)
	assert_true(_height(crab) < 0.4, "un petit crabe : %f" % _height(crab))
	crab.free()


func test_catalogue_photos_use_the_real_models() -> void:
	for id in ["grand_seau", "rateau", "pompe_bras", "moulin_pompe", "miroir", "toboggan", "condenseur", "rations", "bache", "bassin_bois"]:
		var n := ProductModels.build(id)
		assert_false(n.has_meta("unknown"), id)
		assert_true(n.get_child_count() > 0, id)
		n.free()
