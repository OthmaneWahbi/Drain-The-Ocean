class_name OceanModel
extends RefCounted
## Modèle numérique de l'océan (PRD §8.3).
## La variable de vérité est le volume RETIRÉ (et non le volume restant),
## pour éviter les erreurs d'arrondi quand on ajoute 10 L à un total de 10^18 L (PRD §16.3).

var total_volume_l: float
var removed_l: float = 0.0
var drain_threshold_ratio: float


func _init(total: float = 1.0, drain_threshold: float = 0.05) -> void:
	assert(total > 0.0, "Le volume total doit être positif")
	total_volume_l = total
	drain_threshold_ratio = drain_threshold


func remaining_l() -> float:
	return maxf(total_volume_l - removed_l, 0.0)


func remaining_ratio() -> float:
	return remaining_l() / total_volume_l


## Part retirée, calculée depuis le volume retiré : reste précise même quand
## remaining_ratio() vaut encore exactement 1.0 (10 L sur 10^18 L sont sous la précision d'un float).
func removed_ratio() -> float:
	return minf(removed_l / total_volume_l, 1.0)


## Retire de l'eau de l'océan (puisage). Renvoie la quantité réellement retirée.
func remove_water(liters: float) -> float:
	if liters <= 0.0:
		return 0.0
	var taken := minf(liters, remaining_l())
	removed_l += taken
	return taken


## Rend de l'eau à l'océan (versée dans la mer ou sur le sable, M-33/M-34).
func return_water(liters: float) -> void:
	if liters <= 0.0:
		return
	removed_l = maxf(removed_l - liters, 0.0)


## Baisse du niveau en mètres, pour une surface donnée (bassin à bords droits pour l'instant ;
## plus tard une table hauteur = f(volume) tirée de la forme du fond, PRD §8.3).
func level_drop_m(surface_m2: float) -> float:
	if surface_m2 <= 0.0:
		return 0.0
	return (removed_l / 1000.0) / surface_m2


func is_drain_visible() -> bool:
	return remaining_ratio() <= drain_threshold_ratio


func is_empty() -> bool:
	return remaining_l() <= 0.0


func to_dict() -> Dictionary:
	return {"removed_l": removed_l}


func load_dict(data: Dictionary) -> void:
	removed_l = clampf(float(data.get("removed_l", 0.0)), 0.0, total_volume_l)
