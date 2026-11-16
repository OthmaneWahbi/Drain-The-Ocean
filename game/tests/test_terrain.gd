extends TestCase
## Le terrain low poly (0.1.1, agrandi de 50 % en 0.1.3) : plateau plat pour construire, plage toujours atteignable,
## dunes en terrasses ailleurs, fond marin au bon niveau, toujours la même île.

var t: TerrainLogic


func before_each() -> void:
	t = TerrainLogic.new(0.5, 24.0, -3.0)


func _slope_deg(a: Vector3, b: Vector3) -> float:
	return rad_to_deg(atan2(absf(b.y - a.y), Vector2(b.x - a.x, b.z - a.z).length()))


func test_build_plateau_stays_flat() -> void:
	for i in 400:
		var a := TAU * i / 400.0
		var r := 24.0 * float(i % 20) / 19.0
		var h := t.height(cos(a) * r, sin(a) * r)
		assert_true(absf(h - 0.5) <= 0.035, "plateau à %.1f m : %.3f" % [r, h])


func test_the_coast_is_always_beyond_the_plateau() -> void:
	for i in 72:
		var a := TAU * i / 72.0
		assert_true(t.coast_at(a) >= 27.0 - 1e-4)


func test_no_dunes_in_front_of_the_starting_beach() -> void:
	assert_almost(t.dune_amount(PI / 2.0), 0.0)
	assert_almost(t.dune_amount(PI / 2.0 + deg_to_rad(50.0)), 0.0)


func test_there_are_dunes_somewhere_and_they_are_terraced() -> void:
	var top := 0.0
	for i in 180:
		var a := TAU * i / 180.0
		for r in range(25, 38):
			top = maxf(top, t.height(cos(a) * r, sin(a) * r))
	assert_true(top > 1.4, "dunes : %.2f m" % top)
	# Les terrasses : des paliers plats, puis une rampe.
	assert_almost(TerrainLogic.terrace(0.6, 0.5), 0.5, 1e-4)
	assert_almost(TerrainLogic.terrace(0.7, 0.5), 0.5, 1e-4)
	assert_almost(TerrainLogic.terrace(1.0, 0.5), 1.0, 1e-4)
	assert_true(TerrainLogic.terrace(0.9, 0.5) > 0.5 and TerrainLogic.terrace(0.9, 0.5) < 1.0)


func test_you_can_walk_from_the_plateau_into_the_sea_at_the_beach() -> void:
	var prev := Vector3(0, t.height(0, 0), 0)
	var reached_water := false
	for k in range(1, 101):
		var z := k * 0.5
		var p := Vector3(0, t.height(0, z), z)
		if prev.y > -0.3:  # tant qu'on a pied : la pente doit rester douce
			assert_true(_slope_deg(prev, p) < 30.0, "pente à z=%.1f : %.1f°" % [z, _slope_deg(prev, p)])
		if p.y < -0.5:
			reached_water = true
		prev = p
	assert_true(reached_water)


func test_most_directions_lead_to_the_water() -> void:
	var open := 0
	for i in 36:
		var a := TAU * i / 36.0
		var ok := true
		var prev := Vector3(cos(a) * 24.0, t.height(cos(a) * 24.0, sin(a) * 24.0), sin(a) * 24.0)
		for k in range(1, 46):
			var r := 24.0 + k * 0.5
			var p := Vector3(cos(a) * r, t.height(cos(a) * r, sin(a) * r), sin(a) * r)
			if prev.y > 0.0 and _slope_deg(prev, p) > 40.0:
				ok = false
			prev = p
		if ok:
			open += 1
	assert_true(open >= 18, "directions praticables : %d / 36" % open)


func test_seabed_is_flat_far_away() -> void:
	for p in [Vector2(70, 0), Vector2(0, -80), Vector2(-60, 60)]:
		assert_almost(t.height(p.x, p.y), -3.0, 1e-3)


func test_same_island_every_time() -> void:
	var other := TerrainLogic.new(0.5, 24.0, -3.0)
	for i in 50:
		var x := -40.0 + i * 1.7
		assert_almost(other.height(x, x * 0.6), t.height(x, x * 0.6), 1e-6)


func test_colors_follow_height() -> void:
	var dry := t.color(0.5, 0.0, 0.0)
	var wet := t.color(-0.2, 0.0, 0.0)
	var deep := t.color(-3.0, 0.0, 0.0)
	assert_true(dry.v > wet.v and wet.v > deep.v, "plus sombre en descendant")
	var grass := t.color(2.0, 0.1, 0.0)
	assert_true(grass.g > grass.r, "herbe sur les dunes")


func test_island_is_half_again_as_big_with_a_cove_at_the_start() -> void:
	var total := 0.0
	for i in 72:
		total += t.coast_at(TAU * i / 72.0)
	assert_true(total / 72.0 > 35.0, "rayon moyen : %.1f m (25,5 avant)" % (total / 72.0))
	# La crique : l'eau reste près du camp, du côté de la plage de départ.
	assert_true(t.coast_at(PI / 2.0) < 32.0, "crique : %.1f m" % t.coast_at(PI / 2.0))
	assert_true(t.coast_at(PI / 2.0) < t.coast_at(-PI / 2.0) - 5.0)


func test_the_islet_sticks_out_of_the_water() -> void:
	var isl: Vector3 = t.islets[0]
	assert_true(t.height(isl.x, isl.y) > 0.4, "îlot au-dessus de l'eau")
	assert_true(t.height(isl.x + isl.z * 2.0, isl.y) < -1.0, "entouré d'eau")
