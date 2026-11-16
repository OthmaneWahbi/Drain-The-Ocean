extends TestCase
## Anti-blocage : petits objets traversables, détection « coincé », places de secours.
## Le vrai moteur physique est testé à part : tests/scenarios/softlock.gd.

const PickupView := preload("res://scenes/world/pickup_view.gd")


func test_small_objects_are_walk_through_but_aimable() -> void:
	var body := StaticBody3D.new()
	PhysicsLayers.make_walk_through(body)
	assert_eq(body.collision_layer, PhysicsLayers.WALK_THROUGH)
	assert_eq(body.collision_mask, 0)
	assert_true(PhysicsLayers.AIM & PhysicsLayers.WALK_THROUGH != 0, "le rayon de visée les touche")
	assert_eq(PhysicsLayers.SOLID & PhysicsLayers.WALK_THROUGH, 0)
	body.free()


func test_shells_and_coconuts_do_not_block() -> void:
	for kind in ["shell", "coconut"]:
		var v: StaticBody3D = PickupView.new()
		v.setup({"kind": kind, "position": Vector3.ZERO})
		assert_eq(v.collision_layer, PhysicsLayers.WALK_THROUGH, kind)
		v.free()


func test_detection_needs_a_full_second_of_pushing_without_moving() -> void:
	var u := UnstuckLogic.new(1.0)
	for i in 9:
		assert_false(u.update(0.1, true, 0.0))
	assert_true(u.update(0.1, true, 0.0), "1 s sans bouger en voulant avancer")
	assert_false(u.update(0.1, true, 0.0), "le compteur repart")


func test_moving_or_standing_still_resets_detection() -> void:
	var u := UnstuckLogic.new(1.0)
	for i in 8:
		u.update(0.1, true, 0.0)
	u.update(0.1, true, 0.5)  # on a avancé
	for i in 8:
		assert_false(u.update(0.1, true, 0.0))
	u.update(0.1, false, 0.0)  # on lâche les touches
	for i in 9:
		assert_false(u.update(0.1, true, 0.0))


func test_trapped_only_when_every_direction_is_blocked() -> void:
	assert_true(UnstuckLogic.is_trapped([false, false, false, false, false, false, false, false]))
	assert_false(UnstuckLogic.is_trapped([false, false, false, true, false, false, false, false]), "contre un mur : on peut repartir")
	assert_eq(UnstuckLogic.probe_directions(0.8).size(), 8)
	for d in UnstuckLogic.probe_directions(0.8):
		assert_almost(d.length(), 0.8, 1e-5)
		assert_almost(d.y, 0.0)


func test_rescue_spots_go_from_near_to_far() -> void:
	var origin := Vector3(3, 1, -2)
	var spots := UnstuckLogic.candidates(origin, 0.5, 2.0)
	assert_eq(spots.size(), 8 + 16 + 24 + 32)
	var last := 0.0
	for s in spots:
		var d := Vector2(s.x - origin.x, s.z - origin.z).length()
		assert_true(d + 1e-5 >= last, "triées par distance")
		assert_true(d <= 2.0 + 1e-5)
		assert_almost(s.y, origin.y)
		last = d
