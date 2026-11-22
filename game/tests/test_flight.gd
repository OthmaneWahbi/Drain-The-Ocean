extends TestCase
## 0.1.17 : l'avion de livraison passe en ligne droite, à altitude et vitesse constantes, et la
## caisse descend en parachute à vitesse constante après une courte chute libre (FlightPath).

const DeliveryPlane := preload("res://scenes/world/delivery_plane.gd")


func _cfg() -> GameConfig:
	return load("res://data/game_config.tres") as GameConfig


func _path(pallet := Vector3(0, 0.3, 0), drop := Vector3(5, 0.5, 9)) -> FlightPath:
	return FlightPath.make(pallet, drop, _cfg())


func test_speed_is_constant_all_along() -> void:
	var f := _path()
	var dt := 1.0 / 60.0
	var t := 0.0
	var last := f.position(0.0)
	while t + dt < f.duration():
		t += dt
		var p := f.position(t)
		assert_almost((p - last).length() / dt, _cfg().plane_speed_m_s, 1e-2, "vitesse à t=%.2f" % t)
		last = p


func test_altitude_never_changes() -> void:
	var f := _path()
	for i in 50:
		var t := f.duration() * i / 49.0
		assert_almost(f.position(t).y, f.altitude_y, 1e-5)
	assert_almost(f.altitude_y, 0.5 + _cfg().plane_altitude_m, 1e-5, "au-dessus du plus haut des deux points")


func test_it_flies_a_straight_line_over_the_pallet_and_the_drop() -> void:
	var pallet := Vector3(1, 0.3, -2)
	var drop := Vector3(-6, 0.4, 7)
	var f := _path(pallet, drop)
	# Au largage, l'avion est à la verticale du point de livraison.
	var at_drop := f.position(f.drop_time())
	assert_almost(Vector2(at_drop.x - drop.x, at_drop.z - drop.z).length(), 0.0, 1e-3)
	# Tous les points sont sur la même droite horizontale.
	var a := f.position(0.0)
	var b := f.position(f.duration())
	for i in 20:
		var p := f.position(f.duration() * i / 19.0)
		var ab := Vector2(b.x - a.x, b.z - a.z).normalized()
		var ap := Vector2(p.x - a.x, p.z - a.z)
		assert_almost(ab.cross(ap), 0.0, 1e-3, "sur la ligne")


func test_hook_reaches_the_pallet_when_it_passes_over_it() -> void:
	var pallet := Vector3(2, 0.3, 3)
	var f := _path(pallet, Vector3(8, 0.3, 12))
	var th := f.hook_time()
	var plane := f.position(th)
	var len_m := f.rope_length(th)
	assert_almost(len_m, f.rope_reach, 1e-3, "corde déroulée au moment du ramassage")
	# Le crochet traîne derrière l'avion, d'un angle `rope_trail`.
	var tip := plane - f.dir * len_m * sin(f.rope_trail) - Vector3(0, len_m * cos(f.rope_trail), 0)
	assert_almost(Vector2(tip.x - pallet.x, tip.z - pallet.z).length(), 0.0, 1e-3, "au-dessus de la palette")
	assert_almost(tip.y, pallet.y + 0.25, 1e-3, "le crochet touche le dessus de la palette")


func test_rope_is_reeled_in_far_from_the_pallet() -> void:
	var f := _path()
	assert_almost(f.rope_length(0.0), f.rope_rest, 1e-4, "repliée en arrivant")
	assert_almost(f.rope_length(f.duration()), f.rope_rest, 1e-4, "repliée en repartant")
	# Le treuil ne fait pas de saut d'une image à l'autre.
	var last := f.rope_length(0.0)
	var dt := 1.0 / 60.0
	var t := 0.0
	while t < f.duration():
		t += dt
		var l := f.rope_length(t)
		assert_true(absf(l - last) < 0.6, "pas de saut de corde à t=%.2f" % t)
		last = l


func test_drop_comes_after_the_hook_when_the_drop_is_ahead() -> void:
	var f := _path(Vector3.ZERO, Vector3(0, 0, -12))
	assert_true(f.drop_time() > f.hook_time())
	assert_true(f.hook_time() > 2.5, "l'avion arrive de loin (il ne surgit pas au-dessus de l'île)")
	assert_true(f.duration() > f.drop_time() + 5.0, "et repart au loin")


func test_same_point_for_pallet_and_drop_is_fine() -> void:
	var f := _path(Vector3(3, 0.3, 3), Vector3(3, 0.3, 3))
	assert_almost(f.dir.length(), 1.0, 1e-5)
	assert_true(f.duration() > 0.0)


func test_fall_is_free_then_constant() -> void:
	var ff := 0.45
	var v := 3.6
	assert_almost(FlightPath.fall_distance(0.0, ff, v), 0.0)
	assert_almost(FlightPath.fall_distance(ff, ff, v), 0.5 * 9.8 * ff * ff, 1e-4)
	# Continu à l'ouverture de la voile.
	assert_almost(FlightPath.fall_distance(ff + 1e-4, ff, v), FlightPath.fall_distance(ff, ff, v), 1e-3)
	# Puis vitesse constante (la voile a freiné).
	var d1 := FlightPath.fall_distance(3.0, ff, v)
	var d2 := FlightPath.fall_distance(4.0, ff, v)
	assert_almost(d2 - d1, v, 1e-3, "descente à vitesse constante")
	# Toujours en descente.
	var last := -1.0
	for i in 100:
		var d := FlightPath.fall_distance(i * 0.05, ff, v)
		assert_true(d > last)
		last = d


func test_fall_time_inverts_fall_distance() -> void:
	for h in [1.0, 5.0, 13.0, 30.0]:
		var t := FlightPath.fall_time(h, 0.45, 3.6)
		assert_almost(FlightPath.fall_distance(t, 0.45, 3.6), h, 1e-3)


func test_canopy_opens_with_a_small_overshoot() -> void:
	assert_almost(FlightPath.canopy_open(0.2, 0.45), 0.0, 1e-6, "pliée pendant la chute libre")
	assert_almost(FlightPath.canopy_open(0.45 + 0.45, 0.45), 1.0, 1e-4, "gonflée")
	var peak := 0.0
	for i in 50:
		peak = maxf(peak, FlightPath.canopy_open(0.45 + i * 0.01, 0.45))
	assert_true(peak > 1.02 and peak < 1.2, "petit rebond à l'ouverture (%.3f)" % peak)


func test_swing_starts_still_and_settles() -> void:
	assert_almost(FlightPath.swing(0.3, 0.45), 0.0)
	assert_almost(FlightPath.swing(0.45, 0.45), 0.0, 1e-6, "pas de saut à l'ouverture")
	for i in 200:
		assert_true(absf(FlightPath.swing(i * 0.05, 0.45)) < 0.25)


func test_plane_view_follows_the_path_at_constant_speed() -> void:
	var plane: Node3D = DeliveryPlane.new()
	plane._ready()
	var f := _path(Vector3(0, 0.3, 0), Vector3(4, 0.3, 8))
	plane.fly(f)
	var hooked := [false]
	var dropped := [false]
	plane.hooked.connect(func(): hooked[0] = true)
	plane.dropped.connect(func(): dropped[0] = true)
	var last := plane.position
	var dt := 1.0 / 30.0
	var heading := -plane.transform.basis.z
	for i in int(f.drop_time() / dt) + 2:
		plane._process(dt)
		var p: Vector3 = plane.position
		assert_almost((p - last).length() / dt, f.speed, 1e-2, "vitesse constante")
		assert_almost(p.y, f.altitude_y, 1e-5, "altitude constante")
		assert_true((-plane.transform.basis.z).is_equal_approx(heading), "le cap ne change pas")
		last = p
	assert_true(hooked[0], "le crochet a attrapé le paiement")
	assert_true(dropped[0], "la caisse est partie")
	assert_true(heading.dot(f.dir) > 0.999, "le nez dans le sens du vol")
	plane.free()


func test_crate_model_has_rings_and_a_closed_lid() -> void:
	var crate := Props.crate(0.9)
	var box := Models.bounds(Models.vertices(crate))
	assert_true(box.size.x < 1.05 and box.size.z < 1.05, "pas plus large qu'une case (%s)" % box.size)
	assert_almost(box.position.y, 0.0, 0.02, "posée au sol")
	assert_true(box.end.y < 1.02, "rien ne flotte au-dessus du couvercle (%.3f)" % box.end.y)
	assert_eq(Props.crate_rings(0.9).size(), 4)
	crate.free()


func test_parachute_has_canopy_and_slings() -> void:
	var chute := Props.parachute(1.3, 0.9, 1.0)
	var canopy := chute.get_node_or_null("Canopy") as Node3D
	assert_true(canopy != null and chute.get_node_or_null("Slings") != null)
	assert_almost(canopy.position.y, 1.0, 1e-5, "la voile pivote à la confluence")
	chute.free()


func test_seagull_banks_into_its_turn_and_glides() -> void:
	assert_true(AmbientMotion.bank_angle(30.0, 7.5) > 0.1)
	assert_true(AmbientMotion.bank_angle(1.0, 100.0) <= 0.6, "plafonnée")
	var gliding := 0
	for i in 400:
		var t := i * 0.01
		if absf(AmbientMotion.glide_flap(t, 9.0, 0.6) - 0.12) < 1e-4:
			gliding += 1
	assert_true(gliding > 150, "elle plane la plupart du temps (%d/400)" % gliding)


func test_clouds_fade_at_the_edge() -> void:
	assert_almost(AmbientMotion.edge_fade(0.0, 450.0), 1.0)
	assert_almost(AmbientMotion.edge_fade(450.0, 450.0), 0.0)
	assert_true(AmbientMotion.edge_fade(420.0, 450.0) < 0.5)
