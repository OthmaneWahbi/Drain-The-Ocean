class_name EndingLogic
extends RefCounted
## La vraie fin (PRD §11, M-04), comme une suite de phases minutées, sans aucun affichage.
## La mise en scène (EndingDirector) lit `phase` et `progress()` à chaque image.
##
## DRAIN : la bonde apparaît, « plop » · GURGLE : le glouglou, l'océan descend dans le trou ·
## WALK : on traverse le fond à sec · PLANE : l'avion publicitaire passe · TIME : le temps de partie ·
## CREDITS : le générique · DONE : retour au menu principal.

enum Phase { DRAIN, GURGLE, WALK, PLANE, TIME, CREDITS, DONE }

## Durée de chaque phase, en secondes (DONE n'en a pas).
var durations: Dictionary
var phase: Phase = Phase.DRAIN
var _t: float = 0.0


func _init(p_durations: Dictionary) -> void:
	durations = p_durations


func is_done() -> bool:
	return phase == Phase.DONE


func duration(p: Phase) -> float:
	return maxf(float(durations.get(Phase.keys()[p].to_lower(), 1.0)), 0.01)


## Avancement de la phase en cours, de 0 à 1.
func progress() -> float:
	return 1.0 if is_done() else clampf(_t / duration(phase), 0.0, 1.0)


## Fait avancer le temps ; peut traverser plusieurs phases d'un coup. Renvoie vrai si la phase a changé.
func step(delta: float) -> bool:
	if is_done():
		return false
	var before := phase
	_t += delta
	while not is_done() and _t >= duration(phase):
		_t -= duration(phase)
		phase = (phase + 1) as Phase
	if is_done():
		_t = 0.0
	return phase != before


## Clic pendant le temps ou le générique : on passe à la suite.
func skip() -> void:
	if phase == Phase.TIME or phase == Phase.CREDITS:
		_t = 0.0
		phase = (phase + 1) as Phase


## Les traits sur le palmier (M-84, « calendrier de prisonnier ») : un trait par réveil après
## une noyade. Par paquets de 5 : 4 traits debout et un 5e en travers. Renvoie, pour chaque trait,
## {x, y, angle} : décalage horizontal et hauteur (m, sur l'écorce), angle en degrés.
static func tally_marks(count: int, spacing: float = 0.028, group_gap: float = 0.045, row_h: float = 0.16) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var per_row := 2  # 2 paquets de 5 par rangée (le tronc est fin), puis on descend
	for i in maxi(count, 0):
		var group := i / 5
		var k := i % 5
		var row := group / per_row
		var col := group % per_row
		var group_x := col * (4.0 * spacing + group_gap)
		var y := -row * row_h
		if k < 4:
			out.append({"x": group_x + k * spacing, "y": y, "angle": 0.0})
		else:
			out.append({"x": group_x + 1.5 * spacing, "y": y, "angle": 62.0})
	return out
