extends SceneTree
## Mesure (pas un test qui échoue) : le coût des gestes de pelle dans la vraie scène (0.1.14).
## Pour chaque geste : le temps passé dans l'appel (logique + vues qui écoutent les signaux), puis
## l'image la plus lente pendant l'animation qui suit. Et le coût des morceaux seuls.
##   xvfb-run godot --path game --rendering-driver opengl3 -s res://tests/scenarios/perf_sable.gd

var _gs: Node
var _frame_us: Array[int] = []
var _last := 0
var _times := {}
var _tv: Node
var _gesture_us := 0


func _initialize() -> void:
	OS.set_environment("DTO_SKIP_MENU", "1")
	root.add_child((load("res://scenes/main.tscn") as PackedScene).instantiate())
	_run.call_deferred()


func _process(delta: float) -> bool:
	# Le terrain est mis à jour d'ici (son _process coupé) pour chronométrer chaque image : le
	# rendu logiciel (llvmpipe) dessine trop lentement pour juger le temps total d'une image.
	if _tv != null:
		var t := Time.get_ticks_usec()
		_tv._process(delta)
		_frame_us.append(Time.get_ticks_usec() - t + _gesture_us)
		_gesture_us = 0
	return false


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _ms(us: int) -> String:
	return "%.1f ms" % (us / 1000.0)


func _gesture(label: String, f: Callable) -> void:
	_frame_us.clear()
	var t0 := Time.get_ticks_usec()
	var ok: bool = f.call()
	var dt := Time.get_ticks_usec() - t0
	await _frames(40)
	var worst := 0
	for x in _frame_us:
		worst = maxi(worst, x)
	print("%-28s ok=%s  appel=%s  pire calcul d'image ensuite=%s" % [label, ok, _ms(dt), _ms(worst)])


func _run() -> void:
	await _frames(30)
	_gs = root.get_node("GameState")
	_gs.has_shovel = true
	_gs._sync_toolbar()
	_gs.config.shovel_capacity_scoops = 1000
	_gs.shovel_sand = 500.0
	var TV: Script = load("res://scenes/world/terrain_view.gd")
	_tv = root.find_children("*", "StaticBody3D", true, false).filter(func(n): return n.get_script() == TV)[0]
	_tv.set_process(false)
	# Les morceaux seuls.
	var t0 := Time.get_ticks_usec()
	var mesh: ArrayMesh = TV.build_rect_mesh(_gs.terrain, Rect2i(-16, 32, TV.CHUNK, TV.CHUNK), null)
	var t1 := Time.get_ticks_usec()
	var shape := mesh.create_trimesh_shape()
	var t2 := Time.get_ticks_usec()
	print("un morceau : maillage=%s  collision=%s" % [_ms(t1 - t0), _ms(t2 - t1)])
	var rect := Rect2i(-16, 32, TV.CHUNK, TV.CHUNK)
	var data: Dictionary = TV.new_arrays(rect, true)
	TV.fill(_gs.terrain, rect, rect, [], {}, data)
	t0 = Time.get_ticks_usec()
	TV.fill(_gs.terrain, rect, Rect2i(-10, 36, 14, 14), [], {}, data)
	t1 = Time.get_ticks_usec()
	var m: ArrayMesh = TV.make_mesh(data, null)
	t2 = Time.get_ticks_usec()
	var cps := ConcavePolygonShape3D.new()
	cps.set_faces(data.faces[0])
	var t3 := Time.get_ticks_usec()
	print("14x14 cases : fill=%s  make_mesh=%s  set_faces=%s" % [_ms(t1 - t0), _ms(t2 - t1), _ms(t3 - t2)])
	var ctx_t := Time.get_ticks_usec()
	for i in 10:
		_gs.scoop_reason(Vector2i(4, 30), true)
	print("scoop_reason (x1) = %s" % _ms((Time.get_ticks_usec() - ctx_t) / 10))
	# Chaque écouteur, chronométré.
	for sig_name in ["sand_moved", "terrain_changed", "shovel_changed", "item_moved"]:
		var sig: Signal = _gs.get(sig_name)
		for con in sig.get_connections():
			var cb: Callable = con.callable
			sig.disconnect(cb)
			var label := "%s -> %s.%s" % [sig_name, cb.get_object().get_class() if cb.get_object() else "?", cb.get_method()]
			var timed := func(a = null, b = null, c = null, d = null) -> void:
				var t := Time.get_ticks_usec()
				var args := [a, b, c, d].slice(0, cb.get_argument_count())
				cb.callv(args)
				_times[label] = int(_times.get(label, 0)) + Time.get_ticks_usec() - t
			sig.connect(timed)
	for k in 4:
		await _gesture("creuser %d" % k, func() -> bool: return _gs.shovel_scoop(Vector2i(6, 30), true))
	for k in 3:
		await _gesture("poser %d" % k, func() -> bool: return _gs.shovel_scoop(Vector2i(-6, 30), false))
	await _gesture("lisser", func() -> bool: return _gs.smooth_sand(Vector2i(-6, 30)))
	for k in 4:
		await _gesture("niveler %d" % k, func() -> bool: return _gs.flatten_cell(Vector2i(-4 + k, 20), 0.75))
	# Comme en jeu : clic maintenu, une pelletée toutes les dig_repeat_s, au fond d'un trou.
	for phase in 2:
		_frame_us.clear()
		var t_end := Time.get_ticks_msec() + 6000
		var next := 0
		var n := 0
		while Time.get_ticks_msec() < t_end:
			if Time.get_ticks_msec() >= next:
				_gs.shovel_sand = 0.0 if phase == 0 else 3.0
				var tg := Time.get_ticks_usec()
				_gs.shovel_scoop(Vector2i(20, 24) if phase == 0 else Vector2i(-24, 20), phase == 0)
				_gesture_us += Time.get_ticks_usec() - tg
				next = Time.get_ticks_msec() + int(_gs.config.dig_repeat_s * 1000)
				n += 1
			await process_frame
		_frame_us.sort()
		print("%s maintenu, %d pelletées : geste + terrain par image, médiane %s, 95 %% %s, pire %s" % ["creuser" if phase == 0 else "poser", n, _ms(_frame_us[_frame_us.size() / 2]), _ms(_frame_us[int(_frame_us.size() * 0.95)]), _ms(_frame_us[-1])])
	# Un trou profond et un gros tas (0.1.14 : on creuse jusqu'à 3 m sous la mer).
	var worst := 0
	var total := 0
	for k in 120:
		_gs.shovel_sand = 0.0
		var t := Time.get_ticks_usec()
		_gs.shovel_scoop(Vector2i(2, 12), true)
		var dt := Time.get_ticks_usec() - t
		worst = maxi(worst, dt)
		total += dt
		await process_frame
	print("trou profond, 120 pelletées : moyenne %s, pire %s, fond %.2f m" % [_ms(total / 120), _ms(worst), _gs.terrain.vertex(2, 12).y])
	worst = 0
	total = 0
	for k in 120:
		_gs.shovel_sand = 3.0
		var t := Time.get_ticks_usec()
		_gs.shovel_scoop(Vector2i(-12, 10), false)
		var dt := Time.get_ticks_usec() - t
		worst = maxi(worst, dt)
		total += dt
		await process_frame
	print("gros tas, 120 pelletées : moyenne %s, pire %s, sommet %.2f m" % [_ms(total / 120), _ms(worst), _gs.terrain.vertex(-12, 10).y])
	# Au bord d'un morceau (deux à quatre morceaux à refaire).
	await _gesture("creuser au coin de morceaux", func() -> bool: return _gs.shovel_scoop(Vector2i(16, 48), true))
	for l in _times:
		print("  %-60s %s au total" % [l, _ms(_times[l])])
	quit(0)
