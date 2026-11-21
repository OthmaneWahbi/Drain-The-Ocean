extends TestCase
## Les modèles de la version 0.1.2 (palmiers, noix de coco, cabine, produits du catalogue) et la
## direction artistique de l'interface (polices, thème).


func test_palm_stands_on_its_foot_at_the_right_height() -> void:
	var palm := Models.palm(5.5, 1)
	var box := Models.bounds(Models.vertices(palm))
	assert_almost(box.position.y, 0.0, 0.25, "posé au sol")
	assert_true(box.end.y > 4.8 and box.end.y < 6.2, "hauteur : %f" % box.end.y)
	var foot: Array = Models.trunk_at(palm, 0.0)
	assert_true(Vector2(foot[0].x, foot[0].z).length() < 0.2, "le pied du tronc est au centre")
	var bulge := 0.0
	for sample: Array in palm.get_meta("trunk"):
		bulge = maxf(bulge, sample[1].x)
	assert_true(bulge > 0.1, "le tronc penche vers +X : %f" % bulge)
	var top: Array = Models.trunk_at(palm, 3.0)
	assert_true(float(top[1]) > 0.05 and float(top[1]) < 0.4, "rayon du tronc : %f" % top[1])
	palm.free()


func test_palm_crown_is_fuller_and_has_coconuts() -> void:
	var palm := Models.palm(5.0, 2)
	var leaves := 0
	var nuts := 0
	for mi: MeshInstance3D in Models.meshes_of(palm):
		if mi.has_meta("coconut"):
			nuts += 1
		elif mi.material_override and mi.material_override.albedo_color == Models.RECOLOR.leafsDark:
			leaves += 1
	assert_true(leaves >= 1, "une deuxième couronne de palmes")
	assert_true(nuts >= 3, "des noix de coco : %d" % nuts)
	palm.free()


func test_coconut_is_hairy_with_three_real_holes() -> void:
	var mesh := Models.coconut_mesh(0.15, 4)
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var cols: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var fibers := 0
	var hole := 0
	for i in range(0, verts.size(), 3):
		if cols[i].r > 0.5:
			fibers += 1
		if cols[i].r < 0.12:
			hole += 1
			# Le fond d'un trou est SOUS la surface de la coque (un vrai creux, pas un bouton).
			for k in 3:
				assert_true(verts[i + k].length() <= 0.15 * 1.1 + 1e-4)
	assert_true(fibers > 20, "des fibres : %d" % fibers)
	assert_eq(hole, 21, "trois trous de 7 facettes")
	var deepest := 1.0
	for i in verts.size():
		if cols[i].r < 0.12:
			deepest = minf(deepest, verts[i].length())
	assert_true(deepest < 0.15 * 0.9, "le fond des trous rentre dans la noix : %f" % deepest)


func test_downloaded_models_are_recolored_and_double_sided() -> void:
	var bush := Models.load_model("bush")
	for mi: MeshInstance3D in Models.meshes_of(bush):
		for i in mi.mesh.get_surface_count():
			var m := mi.get_surface_override_material(i) as StandardMaterial3D
			assert_true(m != null, "matériau remplacé")
			assert_eq(m.cull_mode, BaseMaterial3D.CULL_DISABLED)
	bush.free()


func test_coconut_is_a_faceted_ball() -> void:
	var nut := Models.coconut(0.16, 5)
	var box := Models.bounds(Models.vertices(nut))
	assert_true(box.size.x > 0.25 and box.size.x < 0.45, "taille : %s" % box.size)
	nut.free()


func test_phone_booth_has_its_parts() -> void:
	var booth := Models.phone_booth()
	for path in ["Shake", "Shake/Phone/Handset", "Shake/Catalogue"]:
		assert_true(booth.has_node(path), path)
	var box := Models.bounds(Models.vertices(booth))
	assert_true(box.size.y > 2.4 and box.size.y < 3.4, "hauteur : %f" % box.size.y)
	assert_true(box.size.x < 1.6, "la cabine tient dans son obstacle : %f" % box.size.x)
	booth.free()


func test_every_catalogue_item_has_its_own_picture() -> void:
	var unknown := ProductModels.build("???")
	assert_true(unknown.has_meta("unknown"))
	unknown.free()
	var catalog: CatalogDatabase = load("res://data/catalog.tres")
	for item in catalog.items:
		if item.hidden:
			continue
		var model := ProductModels.build(String(item.id))
		var box := Models.bounds(Models.vertices(model))
		assert_true(box.size.length() > 0.3, "%s a une forme" % item.id)
		assert_false(model.has_meta("unknown"), "%s a sa propre photo" % item.id)
		model.free()


func test_every_catalogue_item_has_a_pitch() -> void:
	var keys := {}
	var f := FileAccess.open("res://localization/strings.csv", FileAccess.READ)
	while not f.eof_reached():
		keys[f.get_csv_line()[0]] = true
	var catalog: CatalogDatabase = load("res://data/catalog.tres")
	for item in catalog.items:
		assert_true(keys.has(item.name_key + "_PITCH"), "slogan pour " + item.name_key)


func test_ui_theme_fonts_load_and_keep_symbols() -> void:
	for f: Font in [UiTheme.title_font(), UiTheme.body_font(), UiTheme.bold_font(), UiTheme.marker_font()]:
		assert_true(f != null)
		assert_true(f.has_char("é".unicode_at(0)), "accents")
		assert_false(f.fallbacks.is_empty(), "les symboles (♪, ▮) viennent d'une police de secours")
		for sym in "♪▮★✓→":
			assert_true(f.fallbacks[0].has_char(sym.unicode_at(0)), "symbole " + sym)
	assert_eq(ProjectSettings.get_setting("gui/theme/custom_font"), UiTheme.body_font().resource_path,
		"la police du texte est la police par défaut de tout le projet (Label3D compris)")
	var t := UiTheme.theme()
	assert_eq(t.default_font, UiTheme.body_font())
	assert_true(t.has_stylebox("normal", "Button"))
	assert_true(UiTheme.theme() == t, "un seul thème partagé")
