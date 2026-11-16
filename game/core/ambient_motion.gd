class_name AmbientMotion
extends RefCounted
## Les petits calculs de la vie autour de l'île (mouettes, poissons, crabe, nuages), sans
## aucun affichage : on peut les tester sans scène.


## Point sur un cercle horizontal (une mouette qui tourne, un banc de poissons).
static func orbit(center: Vector3, radius: float, angle: float) -> Vector3:
	return center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)


## Direction de déplacement le long d'un cercle parcouru dans le sens `direction` (+1 / -1).
static func orbit_heading(angle: float, direction: float) -> Vector3:
	return Vector3(-sin(angle), 0.0, cos(angle)) * signf(direction)


## Hauteurs où un poisson peut nager : entre le fond + marge et la surface - marge.
## Renvoie (min, max) ; min > max veut dire « plus assez d'eau ».
static func fish_depth_range(water_y: float, seabed_y: float, margin: float) -> Vector2:
	return Vector2(seabed_y + margin, water_y - margin)


static func has_room_for_fish(water_y: float, seabed_y: float, margin: float) -> bool:
	var r := fish_depth_range(water_y, seabed_y, margin)
	return r.x <= r.y


## Garde un poisson dans l'eau, même quand le niveau baisse.
static func clamp_fish_y(y: float, water_y: float, seabed_y: float, margin: float) -> float:
	var r := fish_depth_range(water_y, seabed_y, margin)
	if r.x > r.y:
		return (r.x + r.y) * 0.5
	return clampf(y, r.x, r.y)


## Un point au hasard dans un anneau (le crabe choisit où aller sur le bord de la plage).
static func ring_point(rng: RandomNumberGenerator, r_min: float, r_max: float, y: float) -> Vector3:
	var a := rng.randf_range(0.0, TAU)
	# Racine pour répartir uniformément sur la surface de l'anneau.
	var r := sqrt(rng.randf_range(r_min * r_min, r_max * r_max))
	return Vector3(cos(a) * r, y, sin(a) * r)


## Ramène `x` dans [center - half, center + half[ (un nuage sorti d'un côté revient de l'autre).
static func wrap_around(x: float, center: float, half: float) -> float:
	return center - half + fposmod(x - (center - half), half * 2.0)


## Battement d'ailes : angle en radians, entre -amplitude et +amplitude.
static func flap(t: float, speed: float, amplitude: float) -> float:
	return sin(t * speed) * amplitude
