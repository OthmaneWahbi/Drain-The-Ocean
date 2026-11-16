class_name StaminaLogic
extends RefCounted
## L'endurance du personnage (M-26, N-05), sans aucun affichage.
##
## Une valeur entre 0 et 1. Courir la vide en `run_s` secondes, nager en `swim_s` secondes.
## Elle ne remonte qu'à l'ARRÊT et sur la TERRE FERME ; dans l'eau, elle ne remonte jamais.
## Vidée en courant, on est « essoufflé » : plus de course tant qu'elle n'est pas remontée
## à `exhausted_ratio` (comme dans Zelda: Breath of the Wild).

const EPSILON := 1e-6

enum Activity { REST_ON_LAND, WALK_ON_LAND, RUN, SWIM }

var run_s: float
var swim_s: float
var regen_s: float
var exhausted_ratio: float
var value: float = 1.0
var exhausted: bool = false
## Plafond imposé par la faim et la soif (N-03) : 1 quand on est bien nourri.
var max_value: float = 1.0


func _init(run: float = 20.0, swim: float = 60.0, regen: float = 5.0, exhausted_at: float = 0.25) -> void:
	run_s = run
	swim_s = swim
	regen_s = regen
	exhausted_ratio = exhausted_at


## Avance le temps selon ce que fait le personnage.
func step(delta: float, activity: Activity) -> void:
	match activity:
		Activity.RUN:
			value -= delta / run_s
		Activity.SWIM:
			value -= delta / swim_s
		Activity.REST_ON_LAND:
			value += delta / regen_s
		Activity.WALK_ON_LAND:
			pass  # ni perte ni gain : il faut s'arrêter pour souffler
	value = clampf(value, 0.0, max_value)
	if value < EPSILON:
		value = 0.0  # évite qu'une poussière d'arrondi laisse 0,000001 d'endurance
	if value <= 0.0:
		exhausted = true
	elif exhausted and value >= exhausted_ratio:
		exhausted = false


## Change le plafond (faim, soif) ; l'endurance au-dessus est ramenée dessous.
func set_max(cap: float) -> void:
	max_value = clampf(cap, 0.05, 1.0)
	value = minf(value, max_value)


func can_run() -> bool:
	return not exhausted and value > 0.0


func is_empty() -> bool:
	return value <= 0.0


func is_full() -> bool:
	return value >= max_value - EPSILON


func refill() -> void:
	value = max_value
	exhausted = false
