extends TestCase
## 0.1.8 : les bugs trouvés en faisant jouer un robot (tests/scenarios/playtest.gd).


## La jauge de faim ou de soif envoyait à Godot un polygone avec des points en double : erreur
## « triangulation failed » à chaque image dès qu'elle bougeait. Son contour doit se trianguler
## à tous les niveaux et à tout moment de la vague.
func test_need_gauge_liquid_always_triangulates() -> void:
	var c := Vector2(40, 40)
	var r := 36.0
	var bad := []
	for k in 201:
		var level := k / 200.0
		for t in [0.0, 0.37, 1.1, 2.9]:
			var pts := NeedGauge.liquid_polygon(c, r, level, t)
			if pts.is_empty():
				continue
			if Geometry2D.triangulate_polygon(pts).is_empty():
				bad.append("%.3f@%.2f" % [level, t])
			for p in pts:
				if p.distance_to(c) > r + 0.01:
					bad.append("hors du cercle %.3f" % level)
					break
	assert_eq(bad.size(), 0, "niveaux qui ne se triangulent pas : %s" % str(bad.slice(0, 8)))


func test_need_gauge_liquid_follows_level() -> void:
	var c := Vector2(40, 40)
	assert_true(NeedGauge.liquid_polygon(c, 36.0, 0.0, 0.0).is_empty(), "vide : rien")
	var half := NeedGauge.liquid_polygon(c, 36.0, 0.5, 0.0)
	var top := INF
	for p in half:
		top = minf(top, p.y)
	assert_true(absf(top - 40.0) < 3.0, "à moitié : la surface passe au centre (%.1f)" % top)


## 0.1.8 (Othmane : les coquillages « dans le sol ») : un coquillage posé sur une pente ne s'enfonce
## nulle part. On vérifie sur toute la plage que chaque bord est au-dessus du sable.
func test_shells_sit_on_the_sand_not_in_it() -> void:
	var cfg: GameConfig = load("res://data/game_config.tres")
	var terrain := TerrainLogic.new(cfg.ground_y, cfg.build_radius_m, cfg.seabed_y)
	var sunk := 0
	var tested := 0
	for k in 60:
		var a := TAU * k / 60.0
		var r: float = terrain.coast_at(a) - 2.0
		var pos := Vector3(cos(a) * r, 0, sin(a) * r)
		var t := Props.on_sand(terrain, pos, 0.12, a)
		for j in 8:
			var b := TAU * j / 8.0
			var edge := t * (Vector3(cos(b), 0, sin(b)) * 0.12)
			tested += 1
			if edge.y < terrain.height(edge.x, edge.z) - 0.03:
				sunk += 1
	assert_eq(sunk, 0, "bords de coquillage sous le sable : %d / %d" % [sunk, tested])


func test_shells_are_closed_underneath() -> void:
	# Fermés dessous : on ne voit plus à travers une coquille posée.
	var s := Props.scallop(0.22, Color.WHITE)
	var box := Models.bounds(Models.vertices(s))
	assert_almost(box.position.y, 0.0, 0.01, "le dessous touche le sol")
	assert_true(s.get_child_count() >= 3, "dessus clair, dessus foncé, dessous")
	s.free()
