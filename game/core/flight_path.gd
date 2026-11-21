class_name FlightPath
extends RefCounted
## Le passage de l'avion de livraison et la chute de la caisse (0.1.17), sans aucun affichage.
##
## Références : un largage réel se fait en palier, cap et vitesse constants ; le ramassage
## au vol des avions postaux (« All American », années 1940) aussi : l'avion passe bas et droit,
## seul le crochet au bout de sa corde descend chercher le sac. Ici l'avion suit donc UNE ligne
## droite, à altitude fixe et vitesse constante, qui passe au-dessus de la palette puis du point
## de largage ; c'est la corde (un treuil) qui descend chercher le paiement et remonte.
##
## Tout se mesure en « distance parcourue » `s` le long de la ligne, comptée depuis la verticale
## de la palette (négative avant). Le temps se déduit de la vitesse : t = (s - s_start) / v.

var speed: float
var altitude_y: float
var dir: Vector3
var pallet: Vector3
## Où commence et finit le passage (distances le long de la ligne).
var s_start: float
var s_end: float
## Le paiement est accroché quand le crochet, qui traîne derrière l'avion, passe la palette.
var s_hook: float
## La caisse part quand l'avion est à la verticale du point de largage.
var s_drop: float
## Corde : longueur repliée, longueur pour toucher la palette, angle de traîne (rad).
var rope_rest: float
var rope_reach: float
var rope_trail: float
## Temps (s) pour dérouler ou enrouler la corde.
var winch_s: float


## `pallet` : le dessus de la palette ; `drop` : le sol au point de largage. `cfg` : GameConfig
## (vitesse, altitude, distances d'arrivée et de départ, corde).
static func make(p_pallet: Vector3, drop: Vector3, cfg: GameConfig) -> FlightPath:
	var f := FlightPath.new()
	f.speed = maxf(cfg.plane_speed_m_s, 1.0)
	f.pallet = p_pallet
	f.altitude_y = maxf(p_pallet.y, drop.y) + cfg.plane_altitude_m
	var flat := Vector3(drop.x - p_pallet.x, 0.0, drop.z - p_pallet.z)
	f.dir = flat.normalized() if flat.length() > 0.5 else Vector3.FORWARD
	f.s_drop = flat.dot(f.dir)
	f.rope_rest = cfg.plane_rope_rest_m
	f.rope_trail = cfg.plane_rope_trail_rad
	# Le crochet touche le dessus de la palette : la corde, penchée de `rope_trail`, doit
	# couvrir la hauteur de l'avion au-dessus d'elle.
	f.rope_reach = (f.altitude_y - p_pallet.y - 0.25) / cos(f.rope_trail)
	f.s_hook = f.rope_reach * sin(f.rope_trail)
	f.winch_s = cfg.plane_winch_s
	f.s_start = -cfg.plane_approach_m
	f.s_end = maxf(f.s_drop, f.s_hook) + cfg.plane_leave_m
	return f


func duration() -> float:
	return (s_end - s_start) / speed


func s_at(t: float) -> float:
	return s_start + speed * t


func time_at(s: float) -> float:
	return (s - s_start) / speed


func hook_time() -> float:
	return time_at(s_hook)


func drop_time() -> float:
	return time_at(s_drop)


## Position de l'avion au temps `t` : toujours à la même hauteur, sur la même ligne.
func position(t: float) -> Vector3:
	var p := pallet + dir * s_at(t)
	p.y = altitude_y
	return p


## Longueur de la corde au temps `t` : repliée, puis déroulée pour arriver pile à la palette,
## tendue le temps du ramassage, puis enroulée. Le treuil démarre et s'arrête en douceur.
func rope_length(t: float) -> float:
	var th := hook_time()
	var k := 0.0
	if t < th:
		k = smoothstep(th - winch_s - 0.4, th - 0.4, t)
	else:
		k = 1.0 - smoothstep(th + 0.3, th + 0.3 + winch_s, t)
	return lerpf(rope_rest, rope_reach, k)


# --- La chute de la caisse --------------------------------------------------------------------

## Hauteur parcourue (m) depuis le largage après `t` secondes : chute libre pendant
## `freefall_s`, puis la voile s'ouvre et freine (en ~0,3 s) jusqu'à la vitesse de descente.
static func fall_distance(t: float, freefall_s: float, descent_m_s: float, gravity := 9.8) -> float:
	if t <= freefall_s:
		return 0.5 * gravity * t * t
	var v0 := gravity * freefall_s
	var d0 := 0.5 * gravity * freefall_s * freefall_s
	var u := t - freefall_s
	# Vitesse v(u) = descent + (v0 - descent)·e^(−u/τ) : on l'intègre.
	var tau := 0.12
	return d0 + descent_m_s * u + (v0 - descent_m_s) * tau * (1.0 - exp(-u / tau))


## Le temps qu'il faut pour tomber de `height` mètres (inverse de fall_distance).
static func fall_time(height: float, freefall_s: float, descent_m_s: float, gravity := 9.8) -> float:
	var lo := 0.0
	var hi := 1.0
	while fall_distance(hi, freefall_s, descent_m_s, gravity) < height and hi < 600.0:
		hi *= 2.0
	for i in 40:
		var mid := (lo + hi) * 0.5
		if fall_distance(mid, freefall_s, descent_m_s, gravity) < height:
			lo = mid
		else:
			hi = mid
	return hi


## Ouverture de la voile (0 = pliée, 1 = gonflée), avec un petit dépassement à l'ouverture.
static func canopy_open(t: float, freefall_s: float, open_s := 0.45) -> float:
	if t <= freefall_s:
		return 0.0
	var u := clampf((t - freefall_s) / open_s, 0.0, 1.0)
	# Easing « back out » : dépasse légèrement 1 puis revient.
	var c := 1.6
	var x := u - 1.0
	return 1.0 + (c + 1.0) * x * x * x + c * x * x


## Balancement de la caisse sous la voile (rad) : un pendule qui s'amortit après l'ouverture.
static func swing(t: float, freefall_s: float, amplitude := 0.16, period_s := 2.2) -> float:
	if t <= freefall_s:
		return 0.0
	var u := t - freefall_s
	return amplitude * exp(-u / 4.0) * sin(TAU * u / period_s) + amplitude * 0.25 * sin(TAU * u / (period_s * 1.7))
