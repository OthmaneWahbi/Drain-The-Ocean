extends SceneTree
## Scénario anti-blocage, avec le vrai moteur physique (pas un test unitaire) :
##   godot --headless --path game -s res://tests/scenarios/softlock.gd
## 1. Enfermé dans un anneau de tuyaux (solides depuis 0.1.6, deux blocs de haut), on en ressort
##    tout seul en essayant d'avancer.
## 2. Enfermé dans une cage de murs solides, on en ressort tout seul en essayant d'avancer.
## 3. « Me débloquer » ramène sur la plage, même si un objet bloque le point de retour.
## Code de sortie 0 si tout passe, 1 sinon.

var _t := 0.0
var _step := 0
var _player: CharacterBody3D
var _gs: Node
var _mark := Vector3.ZERO
var _fails: Array[String] = []
var _cage: Array[Node] = []


func _initialize() -> void:
	OS.set_environment("DTO_SKIP_MENU", "1")
	root.add_child((load("res://scenes/main.tscn") as PackedScene).instantiate())


func _check(ok: bool, what: String) -> void:
	print(("  ok    " if ok else "  ÉCHEC ") + what)
	if not ok:
		_fails.append(what)


func _wall(pos: Vector3, size: Vector3) -> Node:
	var body := StaticBody3D.new()
	body.add_child(Greybox.box_collision(size))
	body.position = pos
	root.get_node("Main").add_child(body)
	return body


func _process(delta: float) -> bool:
	_t += delta
	match _step:
		0:
			if _t < 1.0:
				return false
			_gs = root.get_node("GameState")
			_player = root.get_node("Main/Player")
			_gs.new_game()
			# Un endroit dégagé sur l'île, loin de la cuvette.
			var here := Vector3(-5.5, 0.6, 2.5)  # au milieu de la case (-6, 2)
			_player.global_position = here
			_player.rotation.y = 0.0
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			# Un anneau de tuyaux tout autour, sur deux niveaux : trop haut pour sauter par-dessus.
			for dx in [-1, 0, 1]:
				for dz in [-1, 0, 1]:
					if dx != 0 or dz != 0:
						for level in [0, 1]:
							_gs.pipes[Vector3i(-6 + dx, level, 2 + dz)] = true
			_gs.network_changed.emit()
			_mark = here
			Input.action_press(&"move_forward")
			_step = 1
			_t = 0.0
		1:
			if _t < 3.0:
				return false
			Input.action_release(&"move_forward")
			var moved := Vector2(_player.global_position.x - _mark.x, _player.global_position.z - _mark.z).length()
			_check(moved > 1.4, "sorti de l'anneau de tuyaux tout seul (%.2f m)" % moved)
			_gs.pipes.clear()
			_gs.network_changed.emit()
			_check(_player.collision_mask & PhysicsLayers.WALK_THROUGH == 0, "le joueur ne se cogne pas aux petits objets")
			# 2. Une cage de murs solides, collée au joueur.
			var p := _player.global_position + Vector3(0, 0.0, 0)
			_mark = p
			for w in [[Vector3(0, 1, -0.65), Vector3(1.6, 3, 0.2)], [Vector3(0, 1, 0.65), Vector3(1.6, 3, 0.2)], [Vector3(-0.65, 1, 0), Vector3(0.2, 3, 1.6)], [Vector3(0.65, 1, 0), Vector3(0.2, 3, 1.6)], [Vector3(0, 2.4, 0), Vector3(1.6, 0.2, 1.6)]]:
				_cage.append(_wall(p + w[0], w[1]))
			Input.action_press(&"move_forward")
			_step = 2
			_t = 0.0
		2:
			if _t < 3.0:
				return false
			Input.action_release(&"move_forward")
			var off := Vector2(_player.global_position.x - _mark.x, _player.global_position.z - _mark.z)
			_check(absf(off.x) > 0.7 or absf(off.y) > 0.7, "sorti de la cage tout seul (%.2f, %.2f)" % [off.x, off.y])
			_check(not _player.is_trapped(), "plus coincé")
			# 3. Un mur sur le point de retour, puis « Me débloquer ».
			_cage.append(_wall(_gs.config.respawn_position + Vector3(0, 0.5, 0), Vector3(1.2, 2, 1.2)))
			_step = 3
			_t = 0.0
		3:
			if _t < 0.3:
				return false
			root.get_node("Main/PauseMenu").open_menu()
			root.get_node("Main/PauseMenu").unstuck()
			_step = 4
			_t = 0.0
		4:
			if _t < 0.5:
				return false
			var home: Vector3 = _gs.config.respawn_position
			var d := Vector2(_player.global_position.x - home.x, _player.global_position.z - home.z).length()
			_check(d < 4.5 and d > 0.5, "retour près de la plage, à côté du mur (%.2f m)" % d)
			_check(not paused, "le jeu reprend")
			_check(not _player.is_trapped(), "pas coincé au retour")
			print("%d échec(s)" % _fails.size())
			quit(0 if _fails.is_empty() else 1)
	return false
