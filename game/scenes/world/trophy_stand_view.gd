class_name TrophyStandView
extends StaticBody3D
## Le socle des trophées près de la cabine (0.1.25, PRD §19.32) : pas de fenêtre de succès, une
## petite statue dorée apparaît sur un plot pour chaque succès gagné (config.trophies, dans
## l'ordre), avec un carillon (SoundBoard) et un petit saut. Le texte d'aide nomme les statues.

var _statues: Dictionary = {}  # id -> Node3D
var _pop: Dictionary = {}  # id -> temps depuis l'apparition


func _ready() -> void:
	collision_layer = PhysicsLayers.SOLID
	var cfg := GameState.config
	var y := GameState.terrain.lowest_height(cfg.trophy_stand_position.x, cfg.trophy_stand_position.z, 1.0)
	position = Vector3(cfg.trophy_stand_position.x, y, cfg.trophy_stand_position.z)
	add_child(LaterGoods.trophy_stand(cfg.trophies.size()))
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.9, 0.6, 0.7)
	shape.shape = box
	shape.position = Vector3(0, 0.3, 0)
	add_child(shape)
	GameState.trophy_won.connect(_on_won)
	GameState.game_reset.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for id in _statues:
		(_statues[id] as Node3D).queue_free()
	_statues.clear()
	for id in GameState.trophies:
		_add(String(id))


func _add(id: String) -> Node3D:
	var cfg := GameState.config
	var i := cfg.trophies.find(id)
	if i < 0 or _statues.has(id):
		return null
	var s := LaterGoods.statue(id)
	s.position = LaterGoods.slot_position(i, cfg.trophies.size())
	add_child(s)
	_statues[id] = s
	return s


func _on_won(id: String) -> void:
	if _add(id):
		_pop[id] = 0.0


func _process(delta: float) -> void:
	for id in _pop.keys():
		_pop[id] += delta
		var t: float = _pop[id]
		var s := _statues.get(id) as Node3D
		if s == null or t > 0.8:
			if s:
				s.scale = Vector3.ONE
			_pop.erase(id)
			continue
		s.scale = Vector3.ONE * (1.0 + 0.4 * sin(t / 0.8 * PI))


func get_prompt(_player: Node) -> String:
	return tr("TROPHY_STAND") % [GameState.trophies.size(), GameState.config.trophies.size()]
