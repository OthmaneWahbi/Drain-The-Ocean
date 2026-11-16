class_name PipeNetwork
extends RefCounted
## Les tuyaux qui relient les pompes aux zones de séchage (T2, PRD §7), sans aucun affichage.
##
## On possède un nombre de TRONÇONS (achetés au catalogue), chacun de `segment_m` mètres.
## Les liaisons se font toutes seules : chaque pompe, dans l'ordre, se relie à ses zones de la
## plus proche à la plus lointaine, tant qu'il reste assez de tronçons. Déplacer un objet ou
## acheter des tuyaux refait le réseau.


## Liaisons : liste de {pump, zone, segments, from: Vector3, to: Vector3}.
## `pumps` / `zones` : dictionnaires {position, …} ; `zone_radius` : Callable(zone) -> rayon,
## car le tuyau s'arrête au bord de la zone.
static func links(pumps: Array, zones: Array, segments: int, segment_m: float, zone_radius: Callable) -> Array:
	var out := []
	var left := segments
	for pump in pumps:
		var pp: Vector3 = pump.position
		var sorted := zones.duplicate()
		sorted.sort_custom(func(a, b): return _flat(pp, a.position) < _flat(pp, b.position))
		for zone in sorted:
			var need := segments_needed(pp, zone.position, float(zone_radius.call(zone)), segment_m)
			if need > left:
				continue
			left -= need
			out.append({"pump": pump, "zone": zone, "segments": need, "from": pp, "to": edge_point(pp, zone.position, float(zone_radius.call(zone)))})
	return out


## Nombre de tronçons pour aller du centre de la pompe au bord de la zone (au moins 1).
static func segments_needed(from: Vector3, zone_pos: Vector3, zone_radius: float, segment_m: float) -> int:
	var length := maxf(_flat(from, zone_pos) - zone_radius, 0.0)
	return maxi(int(ceil(length / segment_m - 1e-6)), 1)


## Le point du bord de la zone le plus proche de la pompe.
static func edge_point(from: Vector3, zone_pos: Vector3, zone_radius: float) -> Vector3:
	var d := Vector3(from.x - zone_pos.x, 0.0, from.z - zone_pos.z)
	if d.length() < 1e-6:
		return zone_pos
	return zone_pos + d.normalized() * minf(zone_radius, d.length())


## Verse `liters` dans les zones, dans l'ordre donné (la plus proche d'abord). Renvoie ce qui
## a été accepté : le reste n'est jamais pompé.
static func distribute(liters: float, zones: Array) -> float:
	var poured := 0.0
	for zone in zones:
		if poured >= liters:
			break
		poured += (zone.logic as DryingLogic).add_water(liters - poured)
	return poured


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
