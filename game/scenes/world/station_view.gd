extends StaticBody3D
## Vue d'un objet à portions : bâche de condensation (eau douce) ou caisse de rations.
## Lit son StationLogic à chaque image ; E appelle GameState.use_station.

var station: Dictionary
var _drops: Array[MeshInstance3D] = []
var _t := 0.0


func setup(st: Dictionary) -> void:
	station = st
	position = st.position
	match st.kind:
		"condenseur":
			_build_condenser()
		"rations":
			_build_rations()


func _build_condenser() -> void:
	# Une bâche transparente sur quatre piquets, des pierres et une gamelle (Props.condenser) ;
	# une goutte par portion d'eau douce, dans la gamelle.
	add_child(Props.condenser())
	for i in GameState.config.condenser_capacity:
		var drop := Props.droplet(0.06)
		drop.position = Vector3(-0.14 + i * 0.14, 0.2, 0.45)
		_drops.append(drop)
		add_child(drop)
	add_child(Greybox.box_collision(Vector3(1.8, 0.9, 1.4), Vector3(0, 0.45, 0)))


func _build_rations() -> void:
	add_child(Props.rations())
	add_child(Greybox.box_collision(Vector3(0.7, 0.5, 0.5), Vector3(0, 0.25, 0)))


func _process(delta: float) -> void:
	_t += delta
	var amount := (station.logic as StationLogic).amount
	for i in _drops.size():
		_drops[i].visible = i < amount
		_drops[i].position.y = 0.2 + absf(sin(_t * 2.0 + i)) * 0.03  # elles tremblotent


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
