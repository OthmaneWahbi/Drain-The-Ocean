class_name TerrainLogic
extends RefCounted
## La forme de l'île (version 0.1.1 : le terrain low poly ; 0.1.3 : 50 % plus grande, avec une
## crique devant la plage de départ et un îlot au large), sans aucun affichage.
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
##
## 0.1.10 : le terrain est une **grille de sommets** de 1 m, alignée sur la grille de placement
## (un sommet sur chaque coin de case), un peu décalés au hasard pour les facettes. `height()`
## donne la hauteur EXACTE du maillage affiché (on interpole dans son triangle) : ce qu'on pose au
## sol touche vraiment le sol. `base_height()` reste la forme « idéale » de l'île.
## On peut **travailler le sable** (la pelle) : `edits` remplace la hauteur de certains coins, qui
## ne sont alors plus décalés. Une case dont les 4 coins sont travaillés à la même hauteur est plate.

var ground_y: float
var build_radius: float
var seabed_y: float
var coast_radius: float = 38.0
## La crique de la plage de départ (+Z) : le rivage y rentre de `cove_depth` m, sur ±`cove_half_angle`
## degrés. L'île est grande, mais l'eau reste près du camp.
var cove_depth: float = 8.0
var cove_half_angle: float = 40.0
## Les îlots au large : (x, z, rayon). Une petite bosse de sable qui sort de l'eau.
var islets: Array[Vector3] = [Vector3(-52.0, -30.0, 5.0)]
## Variation du rayon du rivage (± m).
var coast_wobble: float = 3.0
## Largeur de la plage sous l'eau avant la descente vers le fond (m).
var shelf_width: float = 5.0
## Hauteur max des dunes au-dessus du plateau, et hauteur d'une terrasse.
var dune_height: float = 3.2
var terrace_step: float = 0.5
## Relief du plateau (m) : assez pour des facettes, trop peu pour qu'un objet flotte.
var plateau_relief: float = 0.03

## La grille du maillage : sommets de -GRID_HALF à +GRID_HALF (en mètres, pas de 1 m).
const GRID_HALF := 72
const GRID_CELL := 1.0
## Décalage au hasard des sommets (part d'une case) : des triangles irréguliers, pas une grille.
const JITTER := 0.3
## Écart de hauteur toléré entre les coins d'une case plate.
const FLAT_TOLERANCE := 0.02

## Les coins travaillés (pelle) : Vector2i(i, j) -> hauteur (m).
var edits: Dictionary = {}
## Les sommets non travaillés déjà calculés (la forme idéale ne change jamais).
var _vcache: Dictionary = {}

var _angle_noise := FastNoiseLite.new()
var _dune_noise := FastNoiseLite.new()
var _detail_noise := FastNoiseLite.new()


func _init(p_ground_y: float = 0.5, p_build_radius: float = 24.0, p_seabed_y: float = -3.0, seed: int = 7) -> void:
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
	var to_beach := absf(angle_difference(angle, PI / 2.0))
	var cove := cove_depth * (1.0 - smoothstep(0.0, deg_to_rad(cove_half_angle), to_beach))
	return maxf(coast_radius + n * coast_wobble - cove, build_radius + 3.0)


## Force des dunes (0..1) dans la direction `angle`. Nulle autour de la plage de départ (+Z).
func dune_amount(angle: float) -> float:
	var n := _dune_noise.get_noise_2d(cos(angle) * 2.0, sin(angle) * 2.0)
	var base := smoothstep(-0.3, 0.15, n)
	# Pas de dune face à la plage de départ (angle +90°, vers +Z), sur ±60°.
	var to_beach := absf(angle_difference(angle, PI / 2.0))
	return base * smoothstep(deg_to_rad(60.0), deg_to_rad(85.0), to_beach)


## La forme idéale de l'île en (x, z), sans le maillage ni le travail du sable.
func base_height(x: float, z: float) -> float:
	var r := Vector2(x, z).length()
	var angle := atan2(z, x)
	var detail := _detail_noise.get_noise_2d(x, z)
	if r <= build_radius:
		return ground_y + detail * plateau_relief
	var coast := coast_at(angle)
	var dunes := dune_amount(angle)
	# La plage : du plateau jusqu'au rivage, puis sous l'eau jusqu'au bord de la plateforme.
	var beach := _beach(r, coast) + detail * 0.12 * (1.0 - smoothstep(coast + shelf_width, coast + shelf_width + 5.0, r))
	beach = maxf(beach, _islets(x, z))
	if dunes <= 0.0:
		return beach
	# Les dunes : une bosse entre le plateau et le rivage, découpée en terrasses.
	var mid := (build_radius + coast) * 0.5 + 0.8
	var half := (coast - build_radius) * 0.5 + 1.0
	var bump := maxf(0.0, 1.0 - pow((r - mid) / half, 2.0))
	var raw := dune_height * dunes * bump * (0.8 + 0.4 * (detail * 0.5 + 0.5))
	return beach + terrace(raw, terrace_step)


## La hauteur des îlots en (x, z) (très bas si on est loin de tous).
func _islets(x: float, z: float) -> float:
	var best := -INF
	for isl in islets:
		var d := Vector2(x - isl.x, z - isl.y).length() / isl.z
		if d < 1.6:
			# Un dôme plat qui sort de 0,6 m, entouré d'une plage qui replonge vers le fond.
			best = maxf(best, lerpf(0.6, seabed_y, smoothstep(0.55, 1.6, d)))
	return best


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
	if y > ground_y + 1.4 and slope < 0.3:
		c = Color(0.34, 0.46, 0.21)  # herbe sur le haut des dunes (les flancs restent en sable)
	elif y > ground_y + 0.9 and slope < 0.12 and jitter > 0.2:
		c = Color(0.42, 0.5, 0.25)  # touffes d'herbe sèche sur les terrasses
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


# --- La grille du maillage (0.1.10) -------------------------------------------------------------

## Un nombre pseudo-aléatoire entre 0 et 1, toujours le même pour (i, j, k).
static func hash01(i: int, j: int, k: int) -> float:
	var h := (i * 73856093) ^ (j * 19349663) ^ (k * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(h & 0xFFFF) / 65535.0


## Le sommet (i, j) du maillage, en mètres. Un coin travaillé n'est pas décalé : sa case reste
## exactement alignée sur la grille de placement.
func vertex(i: int, j: int) -> Vector3:
	var key := Vector2i(i, j)
	if edits.has(key):
		return Vector3(i * GRID_CELL, float(edits[key]), j * GRID_CELL)
	var cached: Variant = _vcache.get(key)
	if cached != null:
		return cached
	var x := i * GRID_CELL
	var z := j * GRID_CELL
	if absi(i) < GRID_HALF and absi(j) < GRID_HALF:
		x += (hash01(i, j, 1) * 2.0 - 1.0) * JITTER * GRID_CELL
		z += (hash01(i, j, 2) * 2.0 - 1.0) * JITTER * GRID_CELL
	var v := Vector3(x, base_height(x, z), z)
	_vcache[key] = v
	return v


## Les deux triangles de la case dont le coin bas est (i, j) : 6 sommets, dans l'ordre.
## La diagonale alterne d'une case à l'autre (moins de lignes droites visibles).
func cell_triangles(i: int, j: int) -> Array[Vector3]:
	var a := vertex(i, j)
	var b := vertex(i + 1, j)
	var c := vertex(i, j + 1)
	var d := vertex(i + 1, j + 1)
	if posmod(i + j, 2) == 0:
		return [a, c, b, b, c, d]
	return [a, c, d, a, d, b]


## La hauteur du maillage en (x, z) : on cherche le triangle qui contient le point (dans la case
## et ses voisines, à cause du décalage) et on interpole. Hors de la grille : la forme idéale.
func height(x: float, z: float) -> float:
	var f := facet(x, z)
	if f.is_empty():
		return base_height(x, z)
	return _interpolate(f[0], f[1], f[2], Vector2(x, z))


## La facette (triangle [a, b, c]) du maillage sous (x, z), ou [] hors de la grille.
func facet(x: float, z: float) -> Array:
	var ci := floori(x / GRID_CELL)
	var cj := floori(z / GRID_CELL)
	if ci < -GRID_HALF or cj < -GRID_HALF or ci >= GRID_HALF or cj >= GRID_HALF:
		return []
	var p := Vector2(x, z)
	for dj in [0, -1, 1]:
		for di in [0, -1, 1]:
			var i: int = ci + di
			var j: int = cj + dj
			if i < -GRID_HALF or j < -GRID_HALF or i >= GRID_HALF or j >= GRID_HALF:
				continue
			var t := cell_triangles(i, j)
			for k in [0, 3]:
				if not is_nan(_interpolate(t[k], t[k + 1], t[k + 2], p)):
					return [t[k], t[k + 1], t[k + 2]]
	return []


## La hauteur la plus basse du sol sur un disque (centre + 8 points du bord) : un objet posé à
## cette hauteur ne flotte jamais, même sur une pente (remarque 1 d'Othmane, 0.1.10).
func lowest_height(x: float, z: float, radius: float) -> float:
	var y := height(x, z)
	for k in 8:
		var a := TAU * k / 8.0
		y = minf(y, height(x + cos(a) * radius, z + sin(a) * radius))
	return y


## La hauteur du triangle (a, b, c) au-dessus de p, ou NAN si p n'est pas dedans (vu d'en haut).
static func _interpolate(a: Vector3, b: Vector3, c: Vector3, p: Vector2) -> float:
	var v0 := Vector2(b.x - a.x, b.z - a.z)
	var v1 := Vector2(c.x - a.x, c.z - a.z)
	var v2 := Vector2(p.x - a.x, p.y - a.z)
	var den := v0.x * v1.y - v1.x * v0.y
	if absf(den) < 1e-9:
		return NAN
	var u := (v2.x * v1.y - v1.x * v2.y) / den
	var v := (v0.x * v2.y - v2.x * v0.y) / den
	if u < -1e-5 or v < -1e-5 or u + v > 1.0 + 1e-5:
		return NAN
	return a.y + u * (b.y - a.y) + v * (c.y - a.y)


## La pente du sol en (x, z) : 0 à plat, 1 à la verticale (comme pour la couleur des facettes).
func slope(x: float, z: float, d := 0.3) -> float:
	var n := Vector3(height(x - d, z) - height(x + d, z), 2.0 * d, height(x, z - d) - height(x, z + d)).normalized()
	return 1.0 - n.y


## Vrai si la facette sous (x, z) est peinte en herbe : exactement la règle de couleur des
## facettes (hauteur moyenne et pente du triangle), et jamais sur du sable travaillé.
func is_grass(x: float, z: float) -> bool:
	var f := facet(x, z)
	if f.is_empty() or cell_worked(cell_of(x, z)):
		return false
	var a: Vector3 = f[0]
	var b: Vector3 = f[1]
	var c: Vector3 = f[2]
	var n := (b - a).cross(c - a).normalized()
	var y := (a.y + b.y + c.y) / 3.0
	return y > ground_y + 1.4 and 1.0 - absf(n.y) < 0.3


## Vrai si (x, z) et tout un petit disque autour sont dans l'herbe (une fleur ne déborde pas
## sur le sable).
func is_grass_around(x: float, z: float, radius: float) -> bool:
	if not is_grass(x, z):
		return false
	for k in 6:
		var a := TAU * k / 6.0
		if not is_grass(x + cos(a) * radius, z + sin(a) * radius):
			return false
	return true


## La case de la grille de placement (1 m) qui contient (x, z).
static func cell_of(x: float, z: float) -> Vector2i:
	return Vector2i(floori(x / GRID_CELL), floori(z / GRID_CELL))


## Les 4 coins d'une case (i, j bas, puis i+1, puis j+1…).
static func cell_corners(cell: Vector2i) -> Array[Vector2i]:
	return [cell, cell + Vector2i(1, 0), cell + Vector2i(0, 1), cell + Vector2i(1, 1)]


## Vrai si au moins un coin de la case a été travaillé.
func cell_worked(cell: Vector2i) -> bool:
	for c in cell_corners(cell):
		if edits.has(c):
			return true
	return false


## Le niveau d'une case où l'on peut poser quelque chose, ou NAN :
##  - une case du plateau jamais travaillée : `ground_y` (le relief du plateau ne compte pas) ;
##  - une case dont les 4 coins sont travaillés à la même hauteur : cette hauteur.
func cell_level(cell: Vector2i) -> float:
	var corners := cell_corners(cell)
	if not cell_worked(cell):
		for c in corners:
			if Vector2(c.x, c.y).length() * GRID_CELL > build_radius:
				return NAN
		return ground_y
	var lo := INF
	var hi := -INF
	for c in corners:
		if not edits.has(c):
			return NAN
		lo = minf(lo, float(edits[c]))
		hi = maxf(hi, float(edits[c]))
	return lo if hi - lo <= FLAT_TOLERANCE else NAN


## La hauteur moyenne actuelle des 4 coins d'une case.
func cell_mean(cell: Vector2i) -> float:
	var s := 0.0
	for c in cell_corners(cell):
		s += vertex(c.x, c.y).y
	return s / 4.0


## Met les 4 coins de la case à la hauteur `y` (la case devient plate). Renvoie les coins changés.
func set_cell(cell: Vector2i, y: float) -> Array[Vector2i]:
	var changed: Array[Vector2i] = []
	for c in cell_corners(cell):
		if not edits.has(c) or absf(float(edits[c]) - y) > 0.0001:
			changed.append(c)
		edits[c] = y
	return changed


## Les coins travaillés, pour la sauvegarde : [[i, j, y], …].
func edits_to_array() -> Array:
	var out := []
	for c: Vector2i in edits:
		out.append([c.x, c.y, snappedf(float(edits[c]), 0.001)])
	return out


func edits_from_array(a: Variant) -> void:
	edits.clear()
	if not a is Array:
		return
	for e in a:
		if e is Array and e.size() >= 3:
			edits[Vector2i(int(e[0]), int(e[1]))] = float(e[2])
