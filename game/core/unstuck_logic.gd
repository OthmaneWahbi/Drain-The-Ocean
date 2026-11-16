class_name UnstuckLogic
extends RefCounted
## Détecter qu'on est coincé, et trouver où se remettre (anti-blocage), sans moteur physique.
##
## Le joueur appelle `update()` à chaque pas physique. Quand on veut avancer mais qu'on ne bouge
## presque plus depuis `check_after_s`, la fonction rend vrai : le joueur teste alors les 8
## directions. S'il est bloqué partout (vraiment coincé, pas juste contre un mur), il essaie les
## places de `candidates()`, de la plus proche à la plus lointaine, et se pose sur la première libre.

## Déplacement minimum (m/s) pour dire qu'on avance.
const MIN_SPEED := 0.15
## Distance qu'on doit pouvoir parcourir dans au moins une direction pour ne pas être coincé
## (plus que la largeur du personnage : un recoin minuscule compte comme une prison).
const ESCAPE_M := 0.8

var check_after_s: float
var _still_s: float = 0.0


func _init(p_check_after_s: float = 1.0) -> void:
	check_after_s = p_check_after_s


## Renvoie vrai quand il faut vérifier si on est coincé (une fois par période d'immobilité).
func update(delta: float, wants_move: bool, moved_m: float) -> bool:
	if not wants_move or delta <= 0.0 or moved_m / delta >= MIN_SPEED:
		_still_s = 0.0
		return false
	_still_s += delta
	if _still_s >= check_after_s - 1e-6:
		_still_s = 0.0
		return true
	return false


## Les 8 directions à tester (vecteurs horizontaux de longueur `length`).
static func probe_directions(length: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for i in 8:
		var a := TAU * i / 8.0
		out.append(Vector3(cos(a), 0.0, sin(a)) * length)
	return out


## Coincé si aucune des 8 directions n'est libre.
static func is_trapped(free_directions: Array) -> bool:
	return not free_directions.has(true)


## Places à essayer autour de `origin` : des cercles tous les `step_m`, jusqu'à `max_m`,
## les plus proches d'abord (8, puis 16, puis 24 points…).
static func candidates(origin: Vector3, step_m: float, max_m: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var ring := 1
	while ring * step_m <= max_m + 1e-6:
		var r := ring * step_m
		var n := 8 * ring
		for i in n:
			var a := TAU * i / n
			out.append(origin + Vector3(cos(a) * r, 0.0, sin(a) * r))
		ring += 1
	return out
