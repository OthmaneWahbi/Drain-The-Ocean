class_name SurvivalLogic
extends RefCounted
## Faim et soif légères (M-26, N-02, N-03), sans aucun affichage.
##
## `food` et `water` vont de 1 (rassasié, désaltéré) à 0. Elles baissent doucement avec le temps.
## À zéro, on ne meurt pas : une PÉNALITÉ grandit petit à petit et réduit l'endurance maximale.
## Manger (ou boire) efface aussitôt la pénalité correspondante.

var food_empty_s: float
var water_empty_s: float
## Pénalité maximale par besoin (0,3 = l'endurance max perd 30 %), et temps pour l'atteindre.
var max_penalty: float
var penalty_time_s: float

var food: float = 1.0
var water: float = 1.0
var hunger_penalty: float = 0.0
var thirst_penalty: float = 0.0
## 0.1.22 : la canicule fait baisser la soif plus vite (1,5 : 1,5 fois plus vite).
var thirst_factor: float = 1.0


func _init(food_s: float = 900.0, water_s: float = 600.0, penalty: float = 0.3, penalty_s: float = 120.0) -> void:
	food_empty_s = food_s
	water_empty_s = water_s
	max_penalty = penalty
	penalty_time_s = penalty_s


func step(delta: float) -> void:
	# Seul le temps passé À ZÉRO fait grandir la pénalité (pas la partie du pas où il restait de quoi).
	var hungry_s := maxf(delta - food * food_empty_s, 0.0)
	var water_s := water_empty_s / maxf(thirst_factor, 0.01)
	var thirsty_s := maxf(delta - water * water_s, 0.0)
	food = maxf(food - delta / food_empty_s, 0.0)
	water = maxf(water - delta / water_s, 0.0)
	hunger_penalty = minf(hunger_penalty + max_penalty * hungry_s / penalty_time_s, max_penalty)
	thirst_penalty = minf(thirst_penalty + max_penalty * thirsty_s / penalty_time_s, max_penalty)


## Endurance maximale permise par la faim et la soif (entre 1 − 2 × pénalité max et 1).
func stamina_cap() -> float:
	return 1.0 - hunger_penalty - thirst_penalty


func eat(amount: float) -> void:
	if amount <= 0.0:
		return
	food = minf(food + amount, 1.0)
	hunger_penalty = 0.0


func drink(amount: float) -> void:
	if amount <= 0.0:
		return
	water = minf(water + amount, 1.0)
	thirst_penalty = 0.0


func to_dict() -> Dictionary:
	return {"food": food, "water": water, "hunger_penalty": hunger_penalty, "thirst_penalty": thirst_penalty}


func load_dict(data: Dictionary) -> void:
	food = clampf(float(data.get("food", 1.0)), 0.0, 1.0)
	water = clampf(float(data.get("water", 1.0)), 0.0, 1.0)
	hunger_penalty = clampf(float(data.get("hunger_penalty", 0.0)), 0.0, max_penalty)
	thirst_penalty = clampf(float(data.get("thirst_penalty", 0.0)), 0.0, max_penalty)
