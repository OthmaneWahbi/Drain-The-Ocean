class_name MilestoneLogic
extends RefCounted
## Les jalons comparatifs (PRD §8, M-70) : « vous avez retiré une baignoire », etc.
## Une liste ordonnée de paliers en litres (dans GameConfig), chacun avec une petite récompense.
## Un jalon atteint le reste, même si l'eau retourne à l'océan ensuite.

## [{"id": "baignoire", "liters": 150.0, "reward": {"sel": 10}}, …], du plus petit au plus grand.
var list: Array = []
## Nombre de jalons atteints (les premiers de la liste).
var reached: int = 0


func _init(p_list: Array = []) -> void:
	list = p_list.duplicate(true)
	list.sort_custom(func(a, b): return float(a.liters) < float(b.liters))


## Met à jour avec le volume retiré. Renvoie les jalons franchis à l'instant (souvent aucun).
func update(removed_l: float) -> Array:
	var out := []
	while reached < list.size() and removed_l >= float(list[reached].liters):
		out.append(list[reached])
		reached += 1
	return out


## Le prochain jalon, ou {} si tout est atteint.
func next() -> Dictionary:
	return list[reached] if reached < list.size() else {}


## Avancement vers le prochain jalon (0 à 1), depuis le précédent.
func progress(removed_l: float) -> float:
	if reached >= list.size():
		return 1.0
	var from := float(list[reached - 1].liters) if reached > 0 else 0.0
	var to := float(list[reached].liters)
	return clampf((removed_l - from) / maxf(to - from, 0.001), 0.0, 1.0)


func to_dict() -> Dictionary:
	return {"reached": reached}


func load_dict(data: Dictionary) -> void:
	reached = clampi(int(data.get("reached", 0)), 0, list.size())
