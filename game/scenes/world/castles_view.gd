class_name CastlesView
extends Node3D
## Les tours de sable (0.1.25, PRD §19.32) : une tour par entrée de GameState.castles, refaite
## quand elles changent (posée, un étage de plus, effacée par la marée ou par la pelle). Aucune
## collision : on passe au travers, et on vise le sable dessous.

var _towers: Dictionary = {}  # id -> [Node3D, étages]


func _ready() -> void:
	GameState.castles_changed.connect(_refresh)
	GameState.game_reset.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var keep := {}
	for c in GameState.castles:
		keep[c.id] = true
		var have: Array = _towers.get(c.id, [])
		if not have.is_empty() and int(have[1]) == int(c.floors):
			continue
		if not have.is_empty():
			(have[0] as Node3D).queue_free()
		var t := LaterGoods.sand_tower(int(c.floors))
		t.position = (c.position as Vector3) - Vector3(0, 0.02, 0)  # un peu enfoncée dans le sable
		t.rotation.y = float(hash(c.id) % 628) / 100.0
		add_child(t)
		_towers[c.id] = [t, int(c.floors)]
	for id in _towers.keys():
		if not keep.has(id):
			(_towers[id][0] as Node3D).queue_free()
			_towers.erase(id)
