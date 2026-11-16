class_name DayCycleLogic
extends RefCounted
## Cycle jour/nuit (M-40) : une journée dure `day_length_s` secondes réelles.
## L'heure va de 0 à 24. Le jour va de 6 h à 20 h.

const DAY_START_H := 6.0
const DAY_END_H := 20.0

var day_length_s: float
var time_s: float
var day_index: int = 0


func _init(day_length: float = 1200.0, start_hour: float = 7.0) -> void:
	day_length_s = day_length
	time_s = start_hour / 24.0 * day_length_s


func hour() -> float:
	return time_s / day_length_s * 24.0


func is_day() -> bool:
	var h := hour()
	return h >= DAY_START_H and h < DAY_END_H


func evaporation_multiplier(night_factor: float) -> float:
	return 1.0 if is_day() else night_factor


## Hauteur du soleil en degrés : 0 au lever (6 h), 90 à midi-ish (13 h), 0 au coucher (20 h), négatif la nuit.
func sun_elevation_deg() -> float:
	var h := hour()
	if is_day():
		return sin((h - DAY_START_H) / (DAY_END_H - DAY_START_H) * PI) * 70.0
	var night_len := 24.0 - (DAY_END_H - DAY_START_H)
	var t := fposmod(h - DAY_END_H, 24.0) / night_len
	return -sin(t * PI) * 30.0


## Avance le temps. Renvoie vrai si on vient de passer 6 h du matin (nouvelle journée).
func step(delta: float) -> bool:
	var before := hour()
	time_s = fposmod(time_s + delta, day_length_s)
	var after := hour()
	var crossed := (before < DAY_START_H and after >= DAY_START_H) or (after < before and after >= DAY_START_H)
	if crossed:
		day_index += 1
	return crossed


func to_dict() -> Dictionary:
	return {"time_s": time_s, "day_index": day_index}


func load_dict(data: Dictionary) -> void:
	time_s = fposmod(float(data.get("time_s", time_s)), day_length_s)
	day_index = int(data.get("day_index", 0))
