extends SceneTree
## Mesure de performance (pas un test qui échoue) : charge la vraie scène, puis une île bien
## remplie (12 zones, 8 pompes, 40 tuyaux), et relève pendant ~5 s : images/s, temps de calcul,
## appels de dessin, primitives, nœuds, mémoire. Écrit le rapport dans $PERF_OUT (ou l'affiche).
##   xvfb-run godot --path game --rendering-driver opengl3 -s res://tests/scenarios/perf.gd

var _t := 0.0
var _step := 0
var _rows: Array[Dictionary] = []
var _report := ""


func _initialize() -> void:
	OS.set_environment("DTO_SKIP_MENU", "1")
	root.add_child((load("res://scenes/main.tscn") as PackedScene).instantiate())


func _sample() -> Dictionary:
	return {
		"fps": Engine.get_frames_per_second(),
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
	}


func _summary(label: String) -> void:
	var keys := ["fps", "process_ms", "physics_ms", "draw_calls", "primitives", "nodes", "memory_mb"]
	var line := "%-14s" % label
	for k in keys:
		var total := 0.0
		var worst := 0.0
		for r in _rows:
			total += float(r[k])
			worst = maxf(worst, float(r[k]))
		var avg := total / maxf(_rows.size(), 1.0)
		line += "  %s=%.1f (max %.1f)" % [k, avg, worst]
	_report += line + "\n"
	_rows.clear()


func _process(delta: float) -> bool:
	_t += delta
	var gs = root.get_node_or_null("GameState")
	match _step:
		0:
			if _t > 2.0:
				_step = 1
				_t = 0.0
		1:
			_rows.append(_sample())
			if _t > 5.0:
				_summary("île de départ")
				# Une île bien remplie.
				gs.unlocked_tier = 2
				for i in 12:
					gs.add_zone(["bache", "bassin_bois", "cuvette"][i % 3], gs.find_free_spot("bassin_bois", Vector3(0, 0, 0)))
				for i in 40:
					gs.pipes[Vector3i(-8 + i % 10, 0, 8 + i / 10)] = true
				gs.network_changed.emit()
				_step = 2
				_t = 0.0
		2:
			if _t > 1.0:
				_step = 3
				_t = 0.0
		3:
			_rows.append(_sample())
			if _t > 5.0:
				_summary("île remplie")
				var out := OS.get_environment("PERF_OUT")
				var head := "Godot %s · %s · %s\n" % [Engine.get_version_info().string, RenderingServer.get_video_adapter_name(), DisplayServer.screen_get_size()]
				_report = head + _report
				print(_report)
				if out != "":
					var f := FileAccess.open(out, FileAccess.WRITE)
					f.store_string(_report)
				quit()
	return false
