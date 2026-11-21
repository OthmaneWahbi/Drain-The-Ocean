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


## Inclinaison (rad) d'un oiseau qui tourne en rond : tan(angle) = v² / (g·r), plafonnée.
static func bank_angle(radius: float, speed_m_s: float, max_rad := 0.6) -> float:
	if radius <= 0.0:
		return 0.0
	return minf(atan(speed_m_s * speed_m_s / (9.8 * radius)), max_rad)


## Battement d'une mouette (rad) : de courtes séries de battements (~1,2 s toutes les 4 s),
## le reste du temps elle plane, ailes un peu relevées. Passe en douceur de l'un à l'autre.
static func glide_flap(t: float, speed: float, amplitude: float, cycle_s := 4.0, flap_s := 1.2) -> float:
	var u := fposmod(t, cycle_s)
	var on := smoothstep(0.0, 0.25, u) * (1.0 - smoothstep(flap_s - 0.25, flap_s, u))
	var glide := 0.12  # ailes relevées en planant
	return lerpf(glide, sin(t * speed) * amplitude, on)


## 1 loin du bord, 0 au bord de la zone où les nuages reviennent de l'autre côté (fondu).
static func edge_fade(distance: float, half: float, fade_part := 0.2) -> float:
	return 1.0 - smoothstep(half * (1.0 - fade_part), half, distance)
