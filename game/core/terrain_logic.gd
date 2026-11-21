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
##
## 0.1.11 : la grille est **deux fois plus fine** (un sommet tous les 50 cm, SUB sommets par mètre) :
## des facettes quatre fois plus petites. La case de placement et de pelle reste de 1 m : elle
## couvre SUB × SUB petites cases et (SUB + 1)² sommets. Les indices de sommet (i, j) sont en
## pas de VERTEX_STEP ; les cases (Vector2i) sont en mètres.

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

## Petites cases du maillage par mètre (0.1.11 : 2, des facettes de 50 cm).
const SUB := 2
## L'écart entre deux sommets (m).
const VERTEX_STEP := 1.0 / SUB
## La grille du maillage : sommets d'indice -GRID_HALF à +GRID_HALF (soit ±72 m).
const GRID_HALF := 72 * SUB
## La case de placement et de pelle (m).
const CELL_M := 1.0
## Décalage au hasard des sommets (part d'une petite case) : des triangles irréguliers, pas une grille.
const JITTER := 0.3
## Écart de hauteur toléré entre les coins d'une case plate.
const FLAT_TOLERANCE := 0.02

## Les sommets travaillés (pelle) : Vector2i(i, j) (indices de sommet) -> hauteur (m).
var edits: Dictionary = {}
## Les sommets non travaillés déjà calculés (la forme idéale ne change jamais).
var _vcache: Dictionary = {}
## 0.1.11 : les sommets voisins d'un sommet travaillé ne sont plus décalés au hasard (ils gardent
## la hauteur naturelle). Sans ça, le pied d'une pente de pelle zigzague et ses facettes forment
## des dents de scie. Se déduit toujours de `edits` (rien à sauvegarder).
var _pinned: Dictionary = {}

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


## 0.1.14 : l'intérieur de l'île (le sol d'origine à plus de `inland_above_y`) n'a jamais la mer
## au-dessus de lui, même creusé sous son niveau : la mer y est cachée (OceanView), on n'y nage
## pas, et on peut y creuser profond. GameState règle ce seuil (mer de départ + marge).
var inland_above_y := 0.3


func inland(x: float, z: float) -> bool:
	return base_height(x, z) > inland_above_y


## Les catégories de sol (0.1.12 : le sable sec se nuance ensuite sommet par sommet).
enum Ground { GRASS, DRY_GRASS, DRY_SAND, WET_SAND, UNDERWATER, SEABED }

## Le sable sec d'une plage tropicale (0.1.12 : plus clair et plus saturé), et celui des pentes.
const DRY_SAND := Color(0.74, 0.6, 0.34)
const SLOPE_SAND := Color(0.7, 0.53, 0.3)


## La catégorie d'une facette selon sa hauteur moyenne, sa pente (0 plat … 1 vertical) et un peu
## de hasard.
func ground_kind(y: float, slope: float, jitter: float, sea_y: float = 0.0) -> int:
	if y > ground_y + 1.4 and slope < 0.3:
		return Ground.GRASS  # herbe sur le haut des dunes (les flancs restent en sable)
	if y > ground_y + 0.9 and slope < 0.12 and jitter > 0.2:
		return Ground.DRY_GRASS  # touffes d'herbe sèche sur les terrasses
	if y > sea_y + 0.12:
		return Ground.DRY_SAND
	if y > sea_y - 0.5:
		return Ground.WET_SAND
	if y > seabed_y + 0.5:
		return Ground.UNDERWATER
	return Ground.SEABED


## Le sable sec selon la pente, en douceur (un ton plus chaud dans les pentes).
static func dry_sand_color(slope: float) -> Color:
	return DRY_SAND.lerp(SLOPE_SAND, smoothstep(0.15, 0.5, slope))


## La couleur d'une catégorie de sol (la pente nuance le sable sec).
static func kind_color(kind: int, slope: float) -> Color:
	match kind:
		Ground.GRASS:
			return Color(0.34, 0.5, 0.2)
		Ground.DRY_GRASS:
			return Color(0.44, 0.54, 0.24)
		Ground.DRY_SAND:
			return dry_sand_color(slope)
		Ground.WET_SAND:
			return Color(0.56, 0.45, 0.27)  # sable mouillé
		Ground.UNDERWATER:
			return Color(0.5, 0.45, 0.29)  # sable sous l'eau
	return Color(0.36, 0.38, 0.30)  # fond marin


## Couleur d'une facette selon sa hauteur moyenne, sa pente (0 plat … 1 vertical) et un peu de hasard.
## `vary` faux : la couleur de la catégorie seule (0.1.11 : le terrain varie par sommet, en douceur,
## au lieu d'un damier de facettes).
func color(y: float, slope: float, jitter: float, sea_y: float = 0.0, vary: bool = true) -> Color:
	var c := kind_color(ground_kind(y, slope, jitter, sea_y), slope)
	if not vary:
		return c
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
		return Vector3(i * VERTEX_STEP, float(edits[key]), j * VERTEX_STEP)
	if _pinned.has(key):
		return Vector3(i * VERTEX_STEP, base_height(i * VERTEX_STEP, j * VERTEX_STEP), j * VERTEX_STEP)
	var cached: Variant = _vcache.get(key)
	if cached != null:
		return cached
	var x := i * VERTEX_STEP
	var z := j * VERTEX_STEP
	if absi(i) < GRID_HALF and absi(j) < GRID_HALF:
		x += (hash01(i, j, 1) * 2.0 - 1.0) * JITTER * VERTEX_STEP
		z += (hash01(i, j, 2) * 2.0 - 1.0) * JITTER * VERTEX_STEP
	var v := Vector3(x, base_height(x, z), z)
	_vcache[key] = v
	return v


## Les deux triangles de la petite case dont le coin bas est le sommet (i, j) : 6 sommets, dans l'ordre.
## La diagonale alterne d'une case à l'autre (moins de lignes droites visibles).
func cell_triangles(i: int, j: int) -> Array[Vector3]:
	var a := vertex(i, j)
	var b := vertex(i + 1, j)
	var c := vertex(i, j + 1)
	var d := vertex(i + 1, j + 1)
	if posmod(i + j, 2) == 0:
		return [a, c, b, b, c, d]
	return [a, c, d, a, d, b]


## Les indices des 6 sommets de cell_triangles(i, j), dans le même ordre.
static func cell_triangle_ids(i: int, j: int) -> Array[Vector2i]:
	var a := Vector2i(i, j)
	var b := Vector2i(i + 1, j)
	var c := Vector2i(i, j + 1)
	var d := Vector2i(i + 1, j + 1)
	if posmod(i + j, 2) == 0:
		return [a, c, b, b, c, d]
	return [a, c, d, a, d, b]


## La normale lissée au sommet (i, j) (0.1.11), tournée vers le haut : la moyenne de la pente
## autour du sommet. Le sable s'éclaire en douceur au lieu de pans plats.
func vertex_normal(i: int, j: int) -> Vector3:
	var dx := vertex(i + 1, j) - vertex(i - 1, j)
	var dz := vertex(i, j + 1) - vertex(i, j - 1)
	var n := dz.cross(dx).normalized()
	return -n if n.y < 0.0 else n


## La hauteur du maillage en (x, z) : on cherche le triangle qui contient le point (dans la case
## et ses voisines, à cause du décalage) et on interpole. Hors de la grille : la forme idéale.
func height(x: float, z: float) -> float:
	var f := facet(x, z)
	if f.is_empty():
		return base_height(x, z)
	return _interpolate(f[0], f[1], f[2], Vector2(x, z))


## La facette (triangle [a, b, c]) du maillage sous (x, z), ou [] hors de la grille.
func facet(x: float, z: float) -> Array:
	var ci := floori(x / VERTEX_STEP)
	var cj := floori(z / VERTEX_STEP)
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
	return Vector2i(floori(x / CELL_M), floori(z / CELL_M))


## Les (SUB + 1)² sommets d'une case de 1 m (indices de sommet), bords compris.
static func cell_vertices(cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for b in SUB + 1:
		for a in SUB + 1:
			out.append(Vector2i(cell.x * SUB + a, cell.y * SUB + b))
	return out


## Les 4 coins extérieurs d'une case de 1 m (indices de sommet).
static func cell_corners(cell: Vector2i) -> Array[Vector2i]:
	var o := cell * SUB
	return [o, o + Vector2i(SUB, 0), o + Vector2i(0, SUB), o + Vector2i(SUB, SUB)]


## Les cases de 1 m qui touchent ce sommet (1 au milieu d'une case, 2 sur un bord, 4 sur un coin).
static func cells_of_vertex(v: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1)]:
		var small: Vector2i = v + d
		var cell := Vector2i(floori(float(small.x) / SUB), floori(float(small.y) / SUB))
		if not out.has(cell):
			out.append(cell)
	return out


## Un sommet en mètres (sans le décalage au hasard).
static func vertex_xz(v: Vector2i) -> Vector2:
	return Vector2(v.x * VERTEX_STEP, v.y * VERTEX_STEP)


## Vrai si au moins un sommet de la case a été travaillé.
func cell_worked(cell: Vector2i) -> bool:
	for c in cell_vertices(cell):
		if edits.has(c):
			return true
	return false


## Le niveau d'une case où l'on peut poser quelque chose, ou NAN :
##  - une case du plateau jamais travaillée : `ground_y` (le relief du plateau ne compte pas) ;
##  - une case dont tous les sommets sont travaillés à la même hauteur : cette hauteur.
func cell_level(cell: Vector2i) -> float:
	if not cell_worked(cell):
		for c in cell_corners(cell):
			if vertex_xz(c).length() > build_radius:
				return NAN
		return ground_y
	var lo := INF
	var hi := -INF
	for c in cell_vertices(cell):
		if not edits.has(c):
			return NAN
		lo = minf(lo, float(edits[c]))
		hi = maxf(hi, float(edits[c]))
	return lo if hi - lo <= FLAT_TOLERANCE else NAN


## La hauteur moyenne actuelle des sommets d'une case.
func cell_mean(cell: Vector2i) -> float:
	var s := 0.0
	var vs := cell_vertices(cell)
	for c in vs:
		s += vertex(c.x, c.y).y
	return s / vs.size()


## Met tous les sommets de la case à la hauteur `y` (la case devient plate). Renvoie les sommets
## changés (et leurs voisins qui viennent d'être recalés sur la grille, voir `_pinned`).
func set_cell(cell: Vector2i, y: float) -> Array[Vector2i]:
	var changed: Array[Vector2i] = []
	for c in cell_vertices(cell):
		if not edits.has(c) or absf(float(edits[c]) - y) > 0.0001:
			changed.append(c)
		edits[c] = y
		_pinned.erase(c)
	if not changed.is_empty():
		for c in cell_vertices(cell):
			changed.append_array(_pin_around(c))
	return changed


## Met chaque sommet de `heights` (Vector2i -> float) à sa hauteur (0.1.12 : la pelle et le sable
## qui s'éboule touchent des sommets un par un). Renvoie les sommets changés et les voisins recalés.
func set_vertices(heights: Dictionary) -> Array[Vector2i]:
	var changed: Array[Vector2i] = []
	for v: Vector2i in heights:
		var y := float(heights[v])
		if edits.has(v) and absf(float(edits[v]) - y) <= 0.0001:
			continue
		changed.append(v)
		edits[v] = y
		_pinned.erase(v)
	var pinned: Array[Vector2i] = []
	for v in changed:
		pinned.append_array(_pin_around(v))
	changed.append_array(pinned)
	return changed


## Le sommet le plus proche d'un point (x, z), en indices.
static func nearest_vertex(x: float, z: float) -> Vector2i:
	return Vector2i(roundi(x / VERTEX_STEP), roundi(z / VERTEX_STEP))


## Recale sur la grille les voisins non travaillés d'un sommet travaillé. Renvoie les nouveaux.
func _pin_around(v: Vector2i) -> Array[Vector2i]:
	var added: Array[Vector2i] = []
	for dj in range(-1, 2):
		for di in range(-1, 2):
			var k := v + Vector2i(di, dj)
			if not edits.has(k) and not _pinned.has(k):
				_pinned[k] = true
				added.append(k)
	return added


## Les sommets recalés sur la grille autour du sable travaillé.
func pinned_vertices() -> Array:
	return _pinned.keys()


## Efface tout le travail de la pelle (nouvelle partie). Renvoie les sommets qui ont bougé.
func clear_edits() -> Array:
	var touched: Array = edits.keys() + _pinned.keys()
	edits.clear()
	_pinned.clear()
	return touched


## Les coins travaillés, pour la sauvegarde : [[i, j, y], …].
func edits_to_array() -> Array:
	var out := []
	for c: Vector2i in edits:
		out.append([c.x, c.y, snappedf(float(edits[c]), 0.001)])
	return out


## `sub` : la finesse de la grille de la sauvegarde (1 avant 0.1.11). Une ancienne grille est
## convertie : chaque case de 1 m dont les 4 coins étaient travaillés est refaite à l'identique
## (plate si elle l'était), les coins isolés gardent leur hauteur.
func edits_from_array(a: Variant, sub: int = SUB) -> void:
	clear_edits()
	_edits_from_array(a, sub)
	for v: Vector2i in edits.keys():
		_pin_around(v)


func _edits_from_array(a: Variant, sub: int) -> void:
	if not a is Array:
		return
	if sub == SUB:
		for e in a:
			if e is Array and e.size() >= 3:
				edits[Vector2i(int(e[0]), int(e[1]))] = float(e[2])
		return
	var old := {}
	for e in a:
		if e is Array and e.size() >= 3:
			old[Vector2i(int(e[0]), int(e[1]))] = float(e[2])
	for c: Vector2i in old:
		edits[c * SUB] = old[c]
	for c: Vector2i in old:
		var corners := [c, c + Vector2i(1, 0), c + Vector2i(0, 1), c + Vector2i(1, 1)]
		if not corners.all(func(k): return old.has(k)):
			continue
		# Interpolation bilinéaire des 4 coins sur les sommets de la case.
		for v in cell_vertices(c):
			var u := float(v.x - c.x * SUB) / SUB
			var w := float(v.y - c.y * SUB) / SUB
			edits[v] = lerpf(lerpf(old[corners[0]], old[corners[1]], u), lerpf(old[corners[2]], old[corners[3]], u), w)
