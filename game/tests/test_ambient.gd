extends TestCase
## La vie autour de l'île : calculs purs des mouettes, poissons, crabe et nuages.


func test_orbit_stays_on_the_circle() -> void:
	for i in 12:
		var a := TAU * i / 12.0
		var p := AmbientMotion.orbit(Vector3(1, 5, -2), 10.0, a)
		assert_almost(Vector2(p.x - 1, p.z + 2).length(), 10.0, 1e-4)
		assert_almost(p.y, 5.0)


func test_orbit_heading_is_tangent() -> void:
	var a := 0.7
	var p := AmbientMotion.orbit(Vector3.ZERO, 5.0, a)
	var h := AmbientMotion.orbit_heading(a, 1.0)
	assert_almost(Vector2(p.x, p.z).dot(Vector2(h.x, h.z)), 0.0, 1e-4)
	var p2 := AmbientMotion.orbit(Vector3.ZERO, 5.0, a + 0.01)
	assert_true((p2 - p).dot(h) > 0.0, "dans le sens du mouvement")


func test_fish_stay_under_the_surface_and_above_the_seabed() -> void:
	assert_almost(AmbientMotion.clamp_fish_y(5.0, 0.0, -3.0, 0.4), -0.4)
	assert_almost(AmbientMotion.clamp_fish_y(-10.0, 0.0, -3.0, 0.4), -2.6)
	assert_almost(AmbientMotion.clamp_fish_y(-1.0, 0.0, -3.0, 0.4), -1.0)


func test_fish_follow_the_water_down() -> void:
	# L'océan baisse : les poissons descendent avec lui.
	assert_almost(AmbientMotion.clamp_fish_y(-0.5, -1.5, -3.0, 0.4), -1.9)
	assert_true(AmbientMotion.has_room_for_fish(-1.5, -3.0, 0.4))
	assert_false(AmbientMotion.has_room_for_fish(-2.8, -3.0, 0.4), "plus assez d'eau")
	assert_almost(AmbientMotion.clamp_fish_y(0.0, -2.8, -3.0, 0.4), -2.9, 1e-4, "posé au milieu")


func test_ring_point_stays_in_the_ring() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 200:
		var p := AmbientMotion.ring_point(rng, 17.0, 19.0, 0.5)
		var r := Vector2(p.x, p.z).length()
		assert_true(r >= 17.0 - 1e-4 and r <= 19.0 + 1e-4, "r = %f" % r)
		assert_almost(p.y, 0.5)


func test_wrap_around() -> void:
	assert_almost(AmbientMotion.wrap_around(310.0, 0.0, 300.0), -290.0)
	assert_almost(AmbientMotion.wrap_around(-301.0, 0.0, 300.0), 299.0)
	assert_almost(AmbientMotion.wrap_around(12.0, 0.0, 300.0), 12.0)
	assert_almost(AmbientMotion.wrap_around(1010.0, 1000.0, 50.0), 1010.0)


func test_flap_is_bounded() -> void:
	for i in 50:
		assert_true(absf(AmbientMotion.flap(i * 0.13, 9.0, 0.6)) <= 0.6 + 1e-6)


func test_underwater_filter_turns_on_only_below_the_surface() -> void:
	assert_true(UnderwaterOverlay.is_camera_under(-0.5, 0.0))
	assert_false(UnderwaterOverlay.is_camera_under(0.5, 0.0))
	assert_false(UnderwaterOverlay.is_camera_under(-0.02, 0.0), "marge pour les vagues")
	# L'océan baisse : à la même hauteur, on finit par être au sec.
	assert_false(UnderwaterOverlay.is_camera_under(-0.5, -1.0))
