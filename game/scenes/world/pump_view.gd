extends StaticBody3D
## Une pompe (T2) : la pompe à bras (un levier qu'on actionne en maintenant le clic) ou le
## moulin-pompe (des pales qui tournent : il pompe tout seul, GameState._run_auto_pumps).
## La vue ne décide rien : elle lit le réseau de tuyaux et appelle GameState.run_pump().

var pump: Dictionary
var _lever: Node3D
var _blades: Node3D
var _phase: float = 0.0
## Vrai pendant les images où le joueur pompe (le levier bouge).
var _working: bool = false
var _last_ocean_removed: float = 0.0


func setup(p: Dictionary) -> void:
	pump = p
	position = p.position
	if GameState.is_auto_pump(pump):
		_build_windmill()
	else:
		_build_hand_pump()


func _build_hand_pump() -> void:
	add_child(Greybox.box(Vector3(0.7, 0.12, 0.7), Greybox.ROCK, Vector3(0, 0.06, 0)))
	add_child(Greybox.cylinder(0.14, 1.0, Color(0.25, 0.4, 0.55), Vector3(0, 0.6, 0), 10))
	add_child(Greybox.box(Vector3(0.08, 0.08, 0.45), Color(0.25, 0.4, 0.55), Vector3(0, 0.95, -0.25)))
	_lever = Node3D.new()
	_lever.position = Vector3(0, 1.12, 0.05)
	_lever.add_child(Greybox.box(Vector3(0.06, 0.06, 0.8), Greybox.WOOD, Vector3(0, 0, 0.4)))
	add_child(_lever)
	add_child(Greybox.box_collision(Vector3(0.7, 1.3, 0.9), Vector3(0, 0.65, 0)))


func _build_windmill() -> void:
	# Une tour en bois, une tête, et quatre pales qui tournent.
	for x in [-0.5, 0.5]:
		for z in [-0.5, 0.5]:
			var leg := Greybox.box(Vector3(0.12, 4.2, 0.12), Greybox.WOOD, Vector3(x * 0.8, 2.1, z * 0.8))
			leg.rotation_degrees = Vector3(-z * 8.0, 0, x * 8.0)
			add_child(leg)
	add_child(Greybox.box(Vector3(0.5, 0.5, 0.7), Color(0.6, 0.15, 0.12), Vector3(0, 4.3, 0)))
	add_child(Greybox.cylinder(0.12, 4.0, Color(0.25, 0.4, 0.55), Vector3(0, 2.0, 0), 8))
	_blades = Node3D.new()
	_blades.position = Vector3(0, 4.3, 0.45)
	for i in 4:
		var arm := Node3D.new()
		arm.rotation.z = i * PI / 2.0
		arm.add_child(Greybox.box(Vector3(0.28, 1.6, 0.04), Color(0.92, 0.9, 0.84), Vector3(0, 0.9, 0)))
		_blades.add_child(arm)
	add_child(_blades)
	add_child(Greybox.box_collision(Vector3(1.4, 4.6, 1.4), Vector3(0, 2.3, 0)))


func _process(delta: float) -> void:
	if _blades:
		# Les pales tournent quand de l'eau passe (le compteur des pompes automatiques monte).
		var turning := GameState.auto_pumped_l > _last_ocean_removed
		_last_ocean_removed = GameState.auto_pumped_l
		_blades.rotation.z -= delta * (2.5 if turning else 0.3)
		return
	if _working:
		_phase += delta * 6.0
	_lever.rotation.x = sin(_phase) * 0.35
	_working = false


func get_prompt(_player: Node) -> String:
	var targets := GameState.zones_for_pump(pump)
	if targets.is_empty():
		return tr("PUMP_NO_LINK") % [GameState.pipe_segments_used(), GameState.pipe_segments]
	var room := 0.0
	for z in targets:
		room += (z.logic as DryingLogic).free_space_l()
	if room <= 0.0:
		return tr("PUMP_FULL")
	if GameState.is_auto_pump(pump):
		return tr("WINDMILL_STATE") % targets.size()
	return tr("PROMPT_PUMP") % targets.size()


## Clic maintenu (voir player.gd) : on pompe pendant `delta` secondes. Le moulin, lui, n'en a pas besoin.
func hold_use(_player: Node, delta: float) -> void:
	if GameState.is_auto_pump(pump):
		return
	if GameState.run_pump(pump, delta) > 0.0:
		_working = true


func get_movable() -> Dictionary:
	return pump
