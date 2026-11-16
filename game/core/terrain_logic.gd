class_name TerrainLogic
extends RefCounted
## La forme de l'île (version 0.1.1 : le terrain low poly), sans aucun affichage.
##
## `height(x, z)` donne la hauteur du sol partout :
##  - le **plateau** de construction (rayon `build_radius`) reste plat à `ground_y` (± quelques mm
##    de relief) : tout ce qu'on pose dessus garde les pieds sur le sable ;
##  - autour, un **rivage irrégulier** (rayon modulé par un bruit selon l'angle) ;
##  - par endroits, des **dunes en terrasses** (sable à plusieurs niveaux), jamais du côté de la
##    plage de départ (+Z), pour qu'on rejoigne toujours l'eau à pied ;
##  - ailleurs, une **plage en pente douce** qui entre dans l'eau, puis le **fond marin** qui
##    descend jusqu'à `seabed_y` et y reste (la bonde de la fin est posée là).
## `color(...)` choisit la couleur d'une facette (sable sec, sable mouillé, fond, herbe des dunes).
## Tout est déterministe (bruit à graine fixe) : la même île à chaque lancement.

var ground_y: float
var build_radius: float
var seabed_y: float
var coast_radius: float = 25.5
## Variation du rayon du rivage (± m).
var coast_wobble: float = 3.0
## Largeur de la plage sous l'eau avant la descente vers le fond (m).
var shelf_width: float = 4.0
## Hauteur max des dunes au-dessus du plateau, et hauteur d'une terrasse.
var dune_height: float = 2.6
var terrace_step: float = 0.5
## Relief du plateau (m) : assez pour des facettes, trop peu pour qu'un objet flotte.
var plateau_relief: float = 0.03

var _angle_noise := FastNoiseLite.new()
var _dune_noise := FastNoiseLite.new()
var _detail_noise := FastNoiseLite.new()


func _init(p_ground_y: float = 0.5, p_build_radius: float = 19.5, p_seabed_y: float = -3.0, seed: int = 7) -> void:
	ground_y = p_ground_y
	build_radius = p_build_radius
	seabed_y = p_seabed_y
	for n: FastNoiseLite in [_angle_noise, _dune_noise, _detail_noise]:
		n.seed = seed
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_angle_noise.frequency = 0.9
	_dune_noise.frequency = 0.8
	_dune_noise.seed = seed + 11
	_detail_noise.frequency = 0.35
	_detail_noise.seed = seed + 23


## Rayon du rivage dans la direction `angle` (radians, atan2(z, x)). Toujours au-delà du plateau.
func coast_at(angle: float) -> float:
	var n := _angle_noise.get_noise_2d(cos(angle) * 2.0, sin(angle) * 2.0)
	return maxf(coast_radius + n * coast_wobble, build_radius + 2.0)


## Force des dunes (0..1) dans la direction `angle`. Nulle autour de la plage de départ (+Z).
func dune_amount(angle: float) -> float:
	var n := _dune_noise.get_noise_2d(cos(angle) * 2.0, sin(angle) * 2.0)
	var base := smoothstep(-0.3, 0.15, n)
	# Pas de dune face à la plage de départ (angle +90°, vers +Z), sur ±60°.
	var to_beach := absf(angle_difference(angle, PI / 2.0))
	return base * smoothstep(deg_to_rad(60.0), deg_to_rad(85.0), to_beach)


func height(x: float, z: float) -> float:
	var r := Vector2(x, z).length()
	var angle := atan2(z, x)
	var detail := _detail_noise.get_noise_2d(x, z)
	if r <= build_radius:
		return ground_y + detail * plateau_relief
	var coast := coast_at(angle)
	var dunes := dune_amount(angle)
	# La plage : du plateau jusqu'au rivage, puis sous l'eau jusqu'au bord de la plateforme.
	var beach := _beach(r, coast) + detail * 0.12 * (1.0 - smoothstep(coast + shelf_width, coast + shelf_width + 5.0, r))
	if dunes <= 0.0:
		return beach
	# Les dunes : une bosse entre le plateau et le rivage, découpée en terrasses.
	var mid := (build_radius + coast) * 0.5 + 0.8
	var half := (coast - build_radius) * 0.5 + 1.0
	var bump := maxf(0.0, 1.0 - pow((r - mid) / half, 2.0))
	var raw := dune_height * dunes * bump * (0.8 + 0.4 * (detail * 0.5 + 0.5))
	return beach + terrace(raw, terrace_step)


func _beach(r: float, coast: float) -> float:
	var t := clampf((r - build_radius) / maxf(coast - build_radius, 0.1), 0.0, 1.0)
	var y := lerpf(ground_y, -0.15, ease(t, 1.6))  # descend doucement jusqu'au bord de l'eau
	if r <= coast:
		return y
	var under := clampf((r - coast) / shelf_width, 0.0, 1.0)
	y = lerpf(-0.15, -0.8, under)  # la plateforme peu profonde où l'on puise en marchant
	if r <= coast + shelf_width:
		return y
	var drop := clampf((r - coast - shelf_width) / 5.0, 0.0, 1.0)
	return lerpf(-0.8, seabed_y, smoothstep(0.0, 1.0, drop))


## Découpe une hauteur en paliers, avec une rampe entre deux paliers (on y monte en marchant).
static func terrace(h: float, step: float) -> float:
	if step <= 0.0 or h <= 0.0:
		return maxf(h, 0.0)
	var k := h / step
	var level := floorf(k)
	var frac := k - level
	return (level + smoothstep(0.45, 1.0, frac)) * step


## Couleur d'une facette selon sa hauteur moyenne, sa pente (0 plat … 1 vertical) et un peu de hasard.
func color(y: float, slope: float, jitter: float, sea_y: float = 0.0) -> Color:
	var c: Color
	if y > ground_y + 0.55 and slope < 0.35:
		c = Color(0.34, 0.46, 0.21)  # herbe sur le haut des dunes
	elif y > sea_y + 0.12:
		c = Color(0.64, 0.54, 0.34)  # sable sec
		if slope > 0.25:
			c = Color(0.58, 0.46, 0.28)  # sable des pentes, un ton plus chaud
	elif y > sea_y - 0.5:
		c = Color(0.50, 0.42, 0.27)  # sable mouillé
	elif y > seabed_y + 0.5:
		c = Color(0.46, 0.42, 0.29)  # sable sous l'eau
	else:
		c = Color(0.36, 0.38, 0.30)  # fond marin
	var k := 1.0 + jitter * 0.06
	return Color(c.r * k, c.g * k, c.b * k)
