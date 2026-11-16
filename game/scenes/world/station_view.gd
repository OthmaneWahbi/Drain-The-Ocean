extends StaticBody3D
## Vue d'un objet à portions : bâche de condensation (eau douce) ou caisse de rations.
## Lit son StationLogic à chaque image ; E appelle GameState.use_station.

var station: Dictionary
var _drops: Array[MeshInstance3D] = []


func setup(st: Dictionary) -> void:
	station = st
	position = st.position
	match st.kind:
		"condenseur":
			_build_condenser()
		"rations":
			_build_rations()


func _build_condenser() -> void:
	# Une bâche transparente tendue en pente au-dessus d'un bac, avec quatre piquets.
	for x in [-0.8, 0.8]:
		for z in [-0.6, 0.6]:
			add_child(Greybox.cylinder(0.04, 0.9, Greybox.WOOD, Vector3(x, 0.45, z), 6))
	var sheet := Greybox.box(Vector3(1.8, 0.03, 1.4), Color(0.75, 0.9, 1.0, 0.5), Vector3(0, 0.75, 0))
	sheet.rotation_degrees.x = 12.0
	add_child(sheet)
	add_child(Greybox.box(Vector3(0.9, 0.2, 0.5), Greybox.ROCK, Vector3(0, 0.1, 0.45)))
	for i in GameState.config.condenser_capacity:
		var drop := Greybox.cylinder(0.08, 0.05, Greybox.WATER, Vector3(-0.25 + i * 0.25, 0.22, 0.45), 8)
		_drops.append(drop)
		add_child(drop)
	add_child(Greybox.box_collision(Vector3(1.8, 0.9, 1.4), Vector3(0, 0.45, 0)))


func _build_rations() -> void:
	add_child(Greybox.box(Vector3(0.7, 0.45, 0.5), Color(0.35, 0.45, 0.25), Vector3(0, 0.23, 0)))
	add_child(Greybox.box(Vector3(0.72, 0.06, 0.52), Greybox.WOOD, Vector3(0, 0.47, 0)))
	add_child(Greybox.box_collision(Vector3(0.7, 0.5, 0.5), Vector3(0, 0.25, 0)))


func _process(_delta: float) -> void:
	var amount := (station.logic as StationLogic).amount
	for i in _drops.size():
		_drops[i].visible = i < amount


func get_prompt(_player: Node) -> String:
	var amount := (station.logic as StationLogic).amount
	match station.kind:
		"condenseur":
			return tr("PROMPT_DRINK") % amount if amount > 0 else tr("CONDENSER_EMPTY")
		"rations":
			return tr("PROMPT_RATION") % amount
	return ""


func interact(_player: Node) -> void:
	GameState.use_station(station)


## Ce que la touche G déplace (voir placement_controller.gd).
func get_movable() -> Dictionary:
	return station
