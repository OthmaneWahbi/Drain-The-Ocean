class_name BucketLogic
extends RefCounted
## Le seau : contenance, eau transportée, temps de remplissage (M-29, M-30).

var capacity_l: float
var fill_time_s: float
var water_l: float = 0.0
var fill_progress_s: float = 0.0


func _init(capacity: float = 10.0, fill_time: float = 1.0) -> void:
	capacity_l = capacity
	fill_time_s = fill_time


func is_empty() -> bool:
	return water_l <= 0.0


func is_full() -> bool:
	return water_l >= capacity_l


func missing_l() -> float:
	return maxf(capacity_l - water_l, 0.0)


## Appelé chaque image tant que le joueur maintient le clic dans l'eau.
## Renvoie vrai à l'instant où le remplissage est terminé (le reste du travail est fait par GameState).
func hold_fill(delta: float) -> bool:
	if is_full():
		fill_progress_s = 0.0
		return false
	fill_progress_s += delta
	if fill_progress_s >= fill_time_s:
		fill_progress_s = 0.0
		return true
	return false


func cancel_fill() -> void:
	fill_progress_s = 0.0


func fill_progress_ratio() -> float:
	return clampf(fill_progress_s / fill_time_s, 0.0, 1.0)


## Vide le seau et renvoie la quantité versée.
func empty_out() -> float:
	var poured := water_l
	water_l = 0.0
	return poured


func to_dict() -> Dictionary:
	return {"capacity_l": capacity_l, "water_l": water_l}


func load_dict(data: Dictionary) -> void:
	capacity_l = maxf(float(data.get("capacity_l", capacity_l)), 0.1)
	water_l = clampf(float(data.get("water_l", 0.0)), 0.0, capacity_l)
