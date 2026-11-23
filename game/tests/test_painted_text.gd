extends TestCase
## Les textes peints dans la matière (PaintedText) : plus de Label3D posés sur les objets.


func _all_nodes(n: Node, out: Array) -> Array:
	out.append(n)
	for c in n.get_children():
		_all_nodes(c, out)
	return out


func test_world_objects_have_no_label3d_left() -> void:
	for model: Node in [Props.crate(0.9), Props.plane(), Props.slide(), Props.rations(), Models.phone_booth()]:
		var painted := 0
		for n in _all_nodes(model, []):
			assert_false(n is Label3D, "%s : un Label3D est resté sur l'objet" % n.name)
			if n is PaintedText:
				painted += 1
		assert_true(painted > 0, "l'objet a bien son texte peint")
		model.free()


func test_painted_text_is_lit_shadowless_and_without_outline() -> void:
	var t := PaintedText.new("CRATE_STAMP", Color.RED, PaintedText.Style.STENCIL)
	assert_eq(t.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "ne projette pas d'ombre")
	var mat := t.material_override as ShaderMaterial
	assert_true(mat != null and mat.shader != null, "matériau de peinture")
	assert_false(mat.shader.code.contains("unshaded"), "éclairé comme l'objet qui le porte")
	assert_true(t.mesh != null, "toujours un maillage (les outils de modèles les parcourent)")
	t.free()


func test_long_text_is_shrunk_to_fit_its_place() -> void:
	var root := Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(root)
	var t := PaintedText.new("BOOTH_SIGN", Color.RED)
	t.font = UiTheme.title_font()
	t.font_size = 46
	t.max_width = 0.5
	root.add_child(t)
	assert_true(t.painted_size().x <= 0.5 + 0.03, "tient dans sa place (marge transparente comprise) : %f" % t.painted_size().x)
	assert_true(t.painted_size().y > 0.02, "pas écrasé : %f" % t.painted_size().y)
	assert_eq(t.shown_text(), tr("BOOTH_SIGN"), "texte traduit")
	root.free()


func test_dynamic_text_follows_its_value() -> void:
	var root := Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(root)
	var t := PaintedText.new("", Color.BLACK, PaintedText.Style.PRINT)
	t.dynamic = true
	root.add_child(t)
	assert_eq(t.painted_size(), Vector2.ZERO, "vide : rien de peint")
	t.text = "12"
	assert_eq(t.shown_text(), "12")
	var w12 := t.painted_size().x
	t.text = "12345"
	assert_true(t.painted_size().x > w12, "plus de chiffres, plus large")
	root.free()
