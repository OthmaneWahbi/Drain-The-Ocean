extends TestCase
## La grille de placement de 0.1.5 : chaque objet occupe un rectangle de cases qui colle à son
## modèle (ni plus petit, ni une case de trop), qui tourne avec lui, et rien d'autre ne s'y pose.
## (Othmane : « les objets prennent bien plus de place que ce qu'on voit, placer est pénible ».)

const GameStateScript := preload("res://core/game_state.gd")
const DecorView := preload("res://scenes/world/decor_view.gd")
## Ce qu'un modèle peut dépasser de son emprise (le bord arrondi d'un bac, la girouette en l'air).
const OVERHANG := 0.12

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e6
	gs.setup(cfg)
	gs.pickups.clear()  # les coquillages tombent au hasard : placements reproductibles


func after_each() -> void:
	gs.free()


## Ce que la vue d'un objet montre au sol, à sa plus grande taille (tas pleins, pilotis…).
func _model(kind: String) -> Node3D:
	var root := Node3D.new()
	match kind:
		"cuvette", "bache", "bassin_bois":
			root.add_child(Props.drying_zone(kind))
			for res in gs.config.pile_slots:
				var pile := Props.pile(res, 1)
				pile.scale = Vector3.ONE * 1.1  # le plus gros tas (drying_zone_view)
				pile.position = gs.pile_offset({"kind": kind}, res)
				root.add_child(pile)
		"condenseur":
			root.add_child(Props.condenser())
		"rations":
			root.add_child(Props.rations())
		"miroir":
			root.add_child(Props.mirror())
		"toboggan":
			root.add_child(Props.slide())
		"pompe_bras":
			root.add_child(Props.hand_pump())
			root.add_child(Props.stilts(Props.PUMP_STILTS))
		"moulin_pompe":
			root.add_child(Props.windmill())
			root.add_child(Props.stilts(Props.WINDMILL_STILTS))
		"palette":
			root.add_child(Props.pallet(Vector3(3.6, 0.15, 1.6)))
		"caisse":
			root.add_child(Props.crate(0.9))
		"bateau_en_bouteille":
			var boat := ProductModels.build("bateau")
			boat.scale = Vector3.ONE * 0.5
			root.add_child(boat)
		"flamant":
			var bird := ProductModels.build("flamant")
			bird.scale = Vector3.ONE * 0.8
			root.add_child(bird)
		"catalogue_papier":
			root.add_child(Props.box(Vector3(0.43, 0.07, 0.31), Props.RED, Vector3(0, 0.035, 0)))
		"coquillage":
			root.add_child(Props.shell(0, 0.22))
		"hamac":
			root.add_child(IslandLife.hammock())
		"vitrine":
			root.add_child(IslandLife.shelf(5, 3))
		"parasol", "flamant_sel", "saliere", "bouee_canard", "nain_coquillages":
			root.add_child(DecorView.model(kind))
	return root


func _model_rect(kind: String) -> Rect2:
	var n := _model(kind)
	var box := Models.bounds(Models.vertices(n))
	n.free()
	return Rect2(box.position.x, box.position.z, box.size.x, box.size.z)


func test_every_footprint_is_whole_cells() -> void:
	var cell: float = gs.config.grid_cell_m
	for kind: String in gs.config.footprints:
		var r: Rect2 = gs.footprint_of(kind)
		if kind == "coquillage":
			continue  # un coquillage ramassable n'occupe qu'un bout de case
		assert_almost(fposmod(r.size.x, cell), 0.0, 1e-6, "%s : largeur %f" % [kind, r.size.x])
		assert_almost(fposmod(r.size.y, cell), 0.0, 1e-6, "%s : profondeur %f" % [kind, r.size.y])
		assert_almost(fposmod(r.position.x * 2.0, cell), 0.0, 1e-6, "%s : bord sur une demi-case" % kind)
		assert_almost(fposmod(r.position.y * 2.0, cell), 0.0, 1e-6, "%s : bord sur une demi-case" % kind)


func test_footprint_covers_the_model_and_nothing_more() -> void:
	var cell: float = gs.config.grid_cell_m
	for kind: String in gs.config.footprints:
		var foot: Rect2 = gs.footprint_of(kind)
		var model := _model_rect(kind)
		assert_true(model.size.x > 0.1, "%s : un modèle" % kind)
		# Le modèle tient dans l'emprise (à un rebord près)…
		assert_true(foot.grow(OVERHANG).encloses(model), "%s : le modèle %s dépasse de l'emprise %s" % [kind, model, foot])
		if kind == "coquillage":
			continue
		# … et aucun côté ne pourrait reculer d'une case sans couper le modèle.
		assert_true(model.position.x < foot.position.x + cell - OVERHANG, "%s : une colonne vide à gauche (%s / %s)" % [kind, model, foot])
		assert_true(model.end.x > foot.end.x - cell + OVERHANG, "%s : une colonne vide à droite (%s / %s)" % [kind, model, foot])
		assert_true(model.position.y < foot.position.y + cell - OVERHANG, "%s : une rangée vide devant (%s / %s)" % [kind, model, foot])
		assert_true(model.end.y > foot.end.y - cell + OVERHANG, "%s : une rangée vide derrière (%s / %s)" % [kind, model, foot])


func test_footprints_are_much_smaller_than_the_old_circles() -> void:
	# Avant 0.1.5 : la cuvette bloquait un disque de 3 m de rayon (28 m², 6 m de diamètre).
	var cuvette: Rect2 = gs.footprint_of("cuvette")
	assert_true(cuvette.get_area() <= 12.0 + 1e-6, "cuvette : %f m²" % cuvette.get_area())
	assert_eq(gs.footprint_of("condenseur").get_area(), 4.0)
	assert_eq(gs.footprint_of("miroir").get_area(), 2.0)
	assert_eq(gs.footprint_of("rations").get_area(), 1.0)


func test_two_basins_fit_side_by_side_but_not_one_cell_closer() -> void:
	var a: Dictionary = gs.zones[0]
	assert_true(gs.move_item(a, Vector3(0.5, 0.5, -12.5)))
	var b: Dictionary = gs.add_zone("cuvette", Vector3(-9.5, 0.5, 0.5))
	# La cuvette A va de x = -1 à 3 (bac + tas) ; B peut commencer au bord, en x = 3.
	assert_true(gs.can_place(b, Vector3(4.5, 0.5, -12.5)), "case contre case")
	assert_false(gs.can_place(b, Vector3(3.5, 0.5, -12.5)), "une case en commun")
	# Juste devant (en z), le bac fait 3 cases.
	assert_true(gs.can_place(b, Vector3(0.5, 0.5, -15.5)))
	assert_false(gs.can_place(b, Vector3(0.5, 0.5, -14.5)))


func test_small_things_pack_tightly() -> void:
	# Quatre miroirs (2 × 1 cases) en carré 4 × 2 : aucun chevauchement, aucun trou.
	var spots := [Vector3(-6, 0.5, -4.5), Vector3(-4, 0.5, -4.5), Vector3(-6, 0.5, -3.5), Vector3(-4, 0.5, -3.5)]
	for p in spots:
		var m: Dictionary = gs.add_mirror(Vector3(-15, 0.5, -15))
		assert_true(gs.move_item(m, p), "miroir en %s" % p)
	var rations: Dictionary = gs.add_station("rations", Vector3(-15, 0.5, 5))
	assert_true(gs.move_item(rations, Vector3(-2.5, 0.5, -4.5)), "les rations juste à côté")
	assert_false(gs.move_item(rations, Vector3(-4.5, 0.5, -4.5)), "pas sur un miroir")


func test_rotation_turns_the_footprint() -> void:
	# Le toboggan : 1 case de large, 3 de long. Contre un mur de rations, il passe dans un sens
	# et pas dans l'autre.
	var sl: Dictionary = gs.add_slide("toboggan", Vector3(-15.5, 0.5, 5.5))
	gs.add_station("rations", Vector3(-4.5, 0.5, -6.5))
	assert_true(gs.can_place(sl, Vector3(-5.5, 0.5, -6.5), 0.0), "vers +Z : la case des rations est à côté")
	assert_false(gs.can_place(sl, Vector3(-5.5, 0.5, -6.5), 90.0), "vers +X : il passe sur les rations")
	assert_true(gs.can_place(sl, Vector3(-5.5, 0.5, -6.5), 270.0), "vers -X : libre")
	# Tourner sur place est vérifié aussi : move_item refuse une rotation qui chevauche.
	assert_true(gs.move_item(sl, Vector3(-5.5, 0.5, -6.5), 0.0))
	assert_false(gs.move_item(sl, Vector3(-5.5, 0.5, -6.5), 90.0))
	assert_almost(gs.item_rotation(sl), 0.0)


func test_even_sized_things_snap_to_grid_lines_and_follow_rotation() -> void:
	var m: Dictionary = gs.add_mirror(Vector3(-15, 0.5, -15))
	assert_true(gs.move_item(m, Vector3(-6.2, 0.5, -4.4), 0.0))
	assert_almost(m.position.x, -6.0, 1e-6, "2 cases de large : centre sur une ligne")
	assert_almost(m.position.z, -4.5, 1e-6, "1 case de profondeur : centre de case")
	assert_true(gs.move_item(m, Vector3(-6.2, 0.5, -4.4), 90.0))
	assert_almost(m.position.x, -6.5, 1e-6)
	assert_almost(m.position.z, -4.0, 1e-6)
	var r: Rect2 = gs.item_rect(m)
	assert_eq(r, Rect2(-7, -5, 1, 2))


func test_found_spots_are_aligned_valid_and_close() -> void:
	for kind: String in ["cuvette", "bache", "bassin_bois", "condenseur", "rations", "miroir", "toboggan", "palette", "caisse", "flamant"]:
		for rot in [0.0, 90.0]:
			var p: Vector3 = gs.find_free_spot(kind, Vector3(-3, 0.5, -5), rot)
			var r: Rect2 = gs.footprint_rect(kind, p, rot)
			assert_almost(fposmod(r.position.x, 1.0), 0.0, 1e-4, "%s/%d : bord sur une ligne" % [kind, rot])
			assert_almost(fposmod(r.position.y, 1.0), 0.0, 1e-4, "%s/%d : bord sur une ligne" % [kind, rot])
			assert_true(gs.spot_ok(kind, p, rot, gs.blockers_for({})), "%s/%d : valide" % [kind, rot])
			assert_true(Vector2(p.x + 3, p.z + 5).length() < 8.0, "%s/%d : pas loin (%s)" % [kind, rot, p])


func test_a_crowded_island_holds_many_more_basins() -> void:
	# Avec les grands cercles, une douzaine de bassins remplissaient l'île. Avec les rectangles,
	# on en pose bien plus, sans aucun chevauchement.
	gs.player_position = Vector3(0, 0.5, 40)
	var placed := 0
	for i in 40:
		var p: Vector3 = gs.find_free_spot("cuvette", Vector3.ZERO)
		if not gs.spot_ok("cuvette", p, 0.0, gs.blockers_for({})):
			break
		gs.add_zone("cuvette", p)
		placed += 1
	assert_eq(placed, 40)
	for i in gs.zones.size():
		for j in range(i + 1, gs.zones.size()):
			assert_false(gs.item_rect(gs.zones[i]).intersects(gs.item_rect(gs.zones[j])), "zones %d et %d" % [i, j])


func test_pipes_go_right_next_to_things_but_not_into_them() -> void:
	var st: Dictionary = gs.add_station("condenseur", Vector3(-6, 0.5, -6))  # cases x -7..-5, z -7..-5
	gs.pipe_stock = 10
	assert_false(gs.can_place_pipe(Vector3i(-7, 0, -7)), "dans le condenseur")
	assert_false(gs.can_place_pipe(Vector3i(-6, 0, -6)), "dans le condenseur")
	assert_true(gs.can_place_pipe(Vector3i(-5, 0, -6)), "la case juste à côté")
	assert_true(gs.can_place_pipe(Vector3i(-8, 0, -7)), "la case juste à côté")
	# Par-dessus, en hauteur, à partir d'une pièce voisine : oui (on enjambe l'objet).
	assert_true(gs.place_pipe(Vector3i(-5, 0, -6)))
	assert_true(gs.place_pipe(Vector3i(-5, 1, -6)))
	assert_true(gs.can_place_pipe(Vector3i(-6, 1, -6)))
	assert_true(st.position.is_finite())


func test_a_windmill_takes_pipes_on_every_side() -> void:
	gs.config.pump_min_depth_m = -100.0
	var w: Dictionary = gs.add_pump("moulin_pompe", Vector3(-0.5, 0.5, 30.5))  # cases x -2..0, z 29..31
	assert_eq(gs.pump_cells(w), Rect2i(-2, 29, 3, 3))
	for port in [Vector3i(-1, 0, 28), Vector3i(1, 0, 30), Vector3i(-3, 0, 29), Vector3i(0, 0, 32), Vector3i(-1, 1, 30)]:
		var cells := {port: true}
		var reach := PipeNetwork.reach(PipeNetwork.cell_of(w.position), cells, gs.pump_cells(w))
		assert_true(reach.has(port), "le tuyau en %s touche le moulin" % port)
	var corner := {Vector3i(1, 0, 28): true}
	assert_false(PipeNetwork.reach(PipeNetwork.cell_of(w.position), corner, gs.pump_cells(w)).has(Vector3i(1, 0, 28)), "en diagonale : non")
	assert_false(gs.can_place_pipe(Vector3i(-1, 0, 29)), "pas dans le moulin")


func test_slide_reach_counts_from_the_zone_edge() -> void:
	var basin: Dictionary = gs.zones[0]
	assert_true(gs.move_item(basin, Vector3(0.5, 0.5, -12.5)))  # x de -1 à 3
	var sl: Dictionary = gs.add_slide("toboggan", Vector3(-15.5, 0.5, 5.5))
	assert_true(gs.config.slide_reach_m >= 2.5 and gs.config.slide_reach_m < 4.5)
	assert_true(gs.move_item(sl, Vector3(5.5, 0.5, -14.5), 0.0))
	assert_true(gs.zones_for_slide(sl).has(basin), "à 2,5 m du bord")
	assert_true(gs.move_item(sl, Vector3(7.5, 0.5, -14.5), 0.0))
	assert_false(gs.zones_for_slide(sl).has(basin), "à 4,5 m du bord")


func test_rotated_footprint_survives_save_and_load() -> void:
	var sl: Dictionary = gs.add_slide("toboggan", Vector3(-15.5, 0.5, 5.5))
	assert_true(gs.move_item(sl, Vector3(-5.5, 0.5, -6.5), 90.0))
	var before: Rect2 = gs.item_rect(sl)
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_eq(other.item_rect(other.slides[0]), before)
	other.free()
