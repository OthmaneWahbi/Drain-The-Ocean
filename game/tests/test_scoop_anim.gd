extends TestCase
## Le geste de puiser (0.1.18) : la courbe du seau.


func test_rest_at_start_and_bucket_in_sea_in_the_middle() -> void:
	var a := ScoopAnim.pose(0.0)
	assert_almost(a.dip, 0.0)
	assert_almost(a.tilt, 0.0)
	var mid := ScoopAnim.pose(0.5)
	assert_almost(mid.dip, 1.0)
	assert_true(mid.sink > 0.04, "sous la surface au milieu du geste :")


func test_anticipation_lifts_and_tips_back_before_plunging() -> void:
	var a := ScoopAnim.pose(0.07)
	assert_true(a.lift > 0.03, "le seau se soulève :")
	assert_true(a.tilt < 0.0, "il bascule vers soi :")
	assert_almost(a.dip, 0.0)


func test_plunge_tips_the_mouth_forward_then_scoops_back() -> void:
	assert_true(ScoopAnim.pose(0.32).tilt > 60.0, "ouverture vers l'avant en entrant :")
	assert_true(ScoopAnim.pose(0.78).tilt < 20.0, "redressé en fin de ramassage :")
	assert_true(ScoopAnim.pose(0.78).pull > 0.95, "ramené vers soi :")


func test_motion_is_continuous() -> void:
	var prev := ScoopAnim.pose(0.0)
	for i in range(1, 201):
		var cur := ScoopAnim.pose(i / 200.0)
		for k in ["dip", "tilt", "lift", "pull", "sink"]:
			assert_true(absf(float(cur[k]) - float(prev[k])) < 4.0 if k == "tilt" else absf(float(cur[k]) - float(prev[k])) < 0.06, "saut de %s à %d :" % [k, i])
		prev = cur


func test_release_starts_where_the_scoop_ends_and_settles() -> void:
	var end := ScoopAnim.pose(1.0)
	var start := ScoopAnim.release(0.0)
	assert_almost(start.dip, end.dip)
	var last := ScoopAnim.release(ScoopAnim.RELEASE_S)
	for k in ["dip", "tilt", "lift"]:
		assert_almost(last[k], 0.0)
	assert_true(ScoopAnim.release(ScoopAnim.RELEASE_S * 0.4).lift < 0.0, "le seau plein s'affaisse :")


func test_water_only_enters_once_the_bucket_is_in_the_sea() -> void:
	assert_almost(ScoopAnim.water_in(0.2), 0.0)
	assert_almost(ScoopAnim.water_in(0.9), 1.0)
	assert_true(ScoopAnim.hits_water(0.25, 0.31))
	assert_false(ScoopAnim.hits_water(0.31, 0.4))
	assert_false(ScoopAnim.hits_water(0.0, 0.0))
