extends StaticBody3D
## La pompe à bras (T2) : un corps, un bec, et un levier qui monte et descend quand on pompe.
## Elle ne décide rien : maintenir le clic appelle GameState.run_pump() à chaque image.

var pump: Dictionary
var _lever: Node3D
var _phase: float = 0.0
## Vrai pendant les images où le joueur pompe (le levier bouge).
var _working: bool = false


func setup(p: Dictionary) -> void:
	pump = p
	position = p.position
	add_child(Greybox.box(Vector3(0.7, 0.12, 0.7), Greybox.ROCK, Vector3(0, 0.06, 0)))
	add_child(Greybox.cylinder(0.14, 1.0, Color(0.25, 0.4, 0.55), Vector3(0, 0.6, 0), 10))
	add_child(Greybox.box(Vector3(0.08, 0.08, 0.45), Color(0.25, 0.4, 0.55), Vector3(0, 0.95, -0.25)))
	_lever = Node3D.new()
	_lever.position = Vector3(0, 1.12, 0.05)
	_lever.add_child(Greybox.box(Vector3(0.06, 0.06, 0.8), Greybox.WOOD, Vector3(0, 0, 0.4)))
	add_child(_lever)
	add_child(Greybox.box_collision(Vector3(0.7, 1.3, 0.9), Vector3(0, 0.65, 0)))


func _process(delta: float) -> void:
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
	return tr("PROMPT_PUMP") % targets.size()


## Clic maintenu (voir player.gd) : on pompe pendant `delta` secondes.
func hold_use(_player: Node, delta: float) -> void:
	if GameState.run_pump(pump, delta) > 0.0:
		_working = true


func get_movable() -> Dictionary:
	return pump
