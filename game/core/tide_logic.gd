class_name TideLogic
extends RefCounted
## Les marées (0.1.20, PRD §19.27) : deux marées hautes et deux basses par jour de jeu.
## La surface VISIBLE monte et descend autour du niveau honnête ; le volume ne change pas (Q-27).
## Logique pure : tout se déduit de l'heure (0-24) et du jour.

const PERIOD_H := 12.0


## Le décalage de la surface (m) à cette heure : +amplitude à marée haute, −amplitude à marée basse.
static func offset(hour: float, amplitude: float, high_hour: float) -> float:
	return amplitude * cos(TAU * (hour - high_hour) / PERIOD_H)


## Entre 0 (marée basse) et 1 (marée haute).
static func ratio(hour: float, high_hour: float) -> float:
	return 0.5 + 0.5 * cos(TAU * (hour - high_hour) / PERIOD_H)


## Vrai pendant la marée basse : le tiers le plus bas du cycle.
static func is_low(hour: float, high_hour: float) -> bool:
	return ratio(hour, high_hour) < 0.25


## Vrai pendant la marée haute (le tiers le plus haut).
static func is_high(hour: float, high_hour: float) -> bool:
	return ratio(hour, high_hour) > 0.75


## Le numéro de la marée basse en cours (ou de la dernière) depuis le début de la partie :
## change une fois par marée basse, pour regarnir les flaques une seule fois.
static func low_index(day_index: int, hour: float, high_hour: float) -> int:
	var low_hour := high_hour + PERIOD_H / 2.0
	var total := day_index * 24.0 + hour - low_hour + PERIOD_H / 2.0
	return floori(total / PERIOD_H)
