extends Node
## État global de la partie en cours (autoload « GameState »).

signal ocean_changed

const CONFIG_PATH := "res://data/game_config.tres"
const RESOURCES: Array[StringName] = [&"sel", &"mineraux", &"mineraux_rares", &"coquillages", &"perles"]

var config: GameConfig
var ocean: OceanModel
var stock: Dictionary = {}
var play_time_s: float = 0.0
var current_slot: int = 1

var _autosave_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	config = load(CONFIG_PATH) as GameConfig
	new_game()


func new_game() -> void:
	ocean = OceanModel.new(config.total_ocean_volume_l, config.drain_threshold_ratio)
	stock = {}
	for r in RESOURCES:
		stock[r] = 0
	play_time_s = 0.0
	_autosave_timer = 0.0
	ocean_changed.emit()


func _process(delta: float) -> void:
	# Chronomètre de partie : ne tourne que quand le jeu n'est pas en pause (PRD §11).
	play_time_s += delta
	_autosave_timer += delta
	if _autosave_timer >= config.autosave_interval_s:
		_autosave_timer = 0.0
		save_game()


func remove_water(liters: float) -> float:
	var taken := ocean.remove_water(liters)
	ocean_changed.emit()
	return taken


func return_water(liters: float) -> void:
	ocean.return_water(liters)
	ocean_changed.emit()


func to_dict() -> Dictionary:
	return {
		"ocean": ocean.to_dict(),
		"stock": stock.duplicate(),
		"play_time_s": play_time_s,
	}


func load_dict(data: Dictionary) -> void:
	new_game()
	ocean.load_dict(data.get("ocean", {}))
	var saved_stock: Dictionary = data.get("stock", {})
	for r in RESOURCES:
		stock[r] = int(saved_stock.get(String(r), saved_stock.get(r, 0)))
	play_time_s = float(data.get("play_time_s", 0.0))
	ocean_changed.emit()


func save_game() -> Error:
	return SaveSystem.write(current_slot, to_dict())


func load_game(slot: int) -> bool:
	var data := SaveSystem.read(slot)
	if data.is_empty():
		return false
	current_slot = slot
	load_dict(data)
	return true


func _notification(what: int) -> void:
	# Sauvegarde en quittant (M-77).
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
