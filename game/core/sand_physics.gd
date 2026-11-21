class_name SandPhysics
extends RefCounted
## Du sable qui se tient comme du sable (0.1.12). Logique pure, sans scène : testable seule.
##
## Le sol est une grille de hauteurs (un sommet tous les 50 cm, TerrainLogic). Deux idées,
## classiques et peu coûteuses :
##
## 1. **La pelletée** : creuser enlève un volume fixe (une pelletée) sous une « brosse » ronde et
##    douce autour du sommet visé (plus profond au centre), poser l'ajoute de la même façon. Le
##    volume compte exactement : ce qui part du sol va sur la pelle, et inversement.
##
## 2. **L'éboulement** (pente d'éboulement, « angle of repose ») : du sable sec ne tient pas plus
##    raide qu'environ 34°, du sable mouillé un peu plus. Après chaque coup de pelle, partout où la
##    pente entre deux sommets voisins dépasse cet angle, une partie du sable du sommet haut glisse
##    vers le bas (la moitié de l'excès, partagée entre les voisins trop bas, au prorata). On répète
##    jusqu'à ce que tout tienne. C'est l'« érosion thermique » de Musgrave (1989), le modèle des
##    tas de sable de Houdini, de World Machine ou de From Dust, en version locale : on ne regarde
##    que les sommets qui viennent de bouger et leurs voisins (une file), pas toute l'île.
##
## Le volume total ne change jamais pendant l'éboulement. Les sommets « fixes » (sous un objet,
## dans la mer, au bord de la grille) ne bougent pas : ils retiennent le sable comme un mur.

## La surface que représente un sommet (m²) : volume = hauteur × AREA.
const AREA := TerrainLogic.VERTEX_STEP * TerrainLogic.VERTEX_STEP
## Les 8 voisins d'un sommet, et leur distance (m).
const N8: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
const N8_DIST: Array[float] = [0.5, 0.5, 0.5, 0.5, 0.70710678, 0.70710678, 0.70710678, 0.70710678]
## En dessous de cet excès (m), une pente est considérée comme stable.
const EPS := 0.004


## La brosse ronde d'une pelletée : sommet -> poids (1 au centre, 0 au bord du rayon).
static func brush(center: Vector2i, radius_m: float) -> Dictionary:
	var out := {}
	var r := ceili(radius_m / TerrainLogic.VERTEX_STEP)
	for dj in range(-r, r + 1):
		for di in range(-r, r + 1):
			var d := Vector2(di, dj).length() * TerrainLogic.VERTEX_STEP
			if d < radius_m:
				var k := 1.0 - (d / radius_m) * (d / radius_m)
				out[center + Vector2i(di, dj)] = k * k
	return out


## Creuse (`dig` vrai) ou pose jusqu'à `volume_m3` sous la brosse. `heights` : la hauteur
## actuelle de chaque sommet de la brosse (seuls ceux-là bougent). Jamais sous `floor_y` ni
## au-dessus de `ceil_y` : un sommet qui touche la borne en prend (ou en pose) moins, et la
## pelletée est plus petite (on ne reporte pas sur les autres : le trou resterait rond, pas en
## croix à fond plat).
## Renvoie {"heights": nouvelles hauteurs, "volume": volume vraiment déplacé (m³)}.
static func carve(heights: Dictionary, weights: Dictionary, volume_m3: float, dig: bool, floor_y: float, ceil_y: float) -> Dictionary:
	var out := heights.duplicate()
	var wsum := 0.0
	for v in weights:
		if out.has(v):
			wsum += float(weights[v])
	var moved := 0.0
	if wsum <= 0.0 or volume_m3 <= 0.0:
		return {"heights": out, "volume": 0.0}
	var depth := volume_m3 / (wsum * AREA)
	for v in weights:
		if not out.has(v):
			continue
		var dh := minf(float(weights[v]) * depth, _room(out[v], dig, floor_y, ceil_y))
		if dh <= 0.0:
			continue
		out[v] = float(out[v]) - dh if dig else float(out[v]) + dh
		moved += dh * AREA
	return {"heights": out, "volume": moved}


## Lisser : chaque sommet se rapproche de la moyenne pondérée de la brosse (`strength` × son
## poids). Le volume ne change pas (la moyenne pondérée est celle qui le garde). Les sommets déjà
## à moins de `snap_m` de la moyenne (au cœur de la brosse) sont mis exactement à leur propre
## moyenne : la surface devient vraiment plate, sans créer de sable.
static func smooth(heights: Dictionary, weights: Dictionary, strength: float, snap_m: float) -> Dictionary:
	var out := heights.duplicate()
	var sw := 0.0
	var sh := 0.0
	for v in weights:
		if heights.has(v):
			sw += float(weights[v])
			sh += float(weights[v]) * float(heights[v])
	if sw <= 0.0:
		return out
	var mean := sh / sw
	for v in weights:
		if heights.has(v):
			out[v] = lerpf(float(heights[v]), mean, clampf(strength * float(weights[v]), 0.0, 1.0))
	# Le cœur presque plat devient plat (à sa propre moyenne : le volume ne bouge pas).
	var core: Array = []
	var s := 0.0
	for v in weights:
		if out.has(v) and float(weights[v]) >= 0.4 and absf(float(out[v]) - mean) <= snap_m:
			core.append(v)
			s += float(out[v])
	if core.size() >= 4:
		var m := s / core.size()
		for v in core:
			out[v] = m
	return out


## Fondre un bord (0.1.13) : les sommets `free` prennent peu à peu la moyenne de leurs 4 voisins
## (`iterations` passes de Jacobi, part `k`). Les autres voisins (lus dans `h` ou avec `read`)
## servent de bord fixe : la pente entre une case nivelée et le sable autour devient une rampe
## douce au lieu d'une marche. Renvoie les nouvelles hauteurs des sommets `free`.
static func blend(h: Dictionary, read: Callable, free: Array, iterations: int, k: float) -> Dictionary:
	var cur := {}
	for v: Vector2i in free:
		cur[v] = _height(v, h, read)
	for _it in iterations:
		var nxt := {}
		for v: Vector2i in free:
			var s := 0.0
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = v + d
				s += float(cur[n]) if cur.has(n) else _height(n, h, read)
			nxt[v] = lerpf(float(cur[v]), s / 4.0, k)
		cur = nxt
	return cur


static func _room(h: float, dig: bool, floor_y: float, ceil_y: float) -> float:
	return maxf(h - floor_y, 0.0) if dig else maxf(ceil_y - h, 0.0)


## L'éboulement, à partir des sommets `seeds`. `h` : les hauteurs connues (Vector2i -> float),
## complétées à la demande avec `read.call(v)` et mises à jour sur place. `can_move.call(v)` dit
## si un sommet peut bouger ; ceux de `locked` ne bougent pas non plus (sable tassé à la pelle).
## La pente limite est `tan_dry` (sable sec), ou `tan_wet` vers un sommet plus bas que
## `wet_below_y` (le sable mouillé tient plus raide). Renvoie les sommets qui ont bougé (un set).
static func relax(h: Dictionary, read: Callable, can_move: Callable, seeds: Array, tan_dry: float, tan_wet: float, wet_below_y: float, locked: Dictionary = {}, max_ops: int = 30000) -> Dictionary:
	var changed := {}
	var movable := {}
	var queue: Array[Vector2i] = []
	var queued := {}
	for s: Vector2i in seeds:
		if not queued.has(s):
			queued[s] = true
			queue.append(s)
	var i := 0
	var ns: Array[Vector2i] = []
	var ds: Array[float] = []
	while i < queue.size() and i < max_ops:
		var v: Vector2i = queue[i]
		i += 1
		queued.erase(v)
		if locked.has(v) or not _movable(v, can_move, movable):
			continue
		var hv := _height(v, h, read)
		ns.clear()
		ds.clear()
		var total := 0.0
		var most := 0.0
		for k in 8:
			var n: Vector2i = v + N8[k]
			if locked.has(n) or not _movable(n, can_move, movable):
				continue
			var hn := _height(n, h, read)
			var limit := (tan_wet if hn < wet_below_y else tan_dry) * N8_DIST[k]
			var d := hv - hn - limit
			if d > EPS:
				ns.append(n)
				ds.append(d)
				total += d
				most = maxf(most, d)
		if ns.is_empty():
			continue
		var move := 0.5 * most
		for k in ns.size():
			var amt := move * ds[k] / total
			h[ns[k]] = float(h[ns[k]]) + amt
			hv -= amt
			changed[ns[k]] = true
			if not queued.has(ns[k]):
				queued[ns[k]] = true
				queue.append(ns[k])
		h[v] = hv
		changed[v] = true
		# v a baissé : ses voisins plus hauts peuvent maintenant être trop raides, et lui encore.
		for k in 8:
			var n: Vector2i = v + N8[k]
			if not queued.has(n):
				queued[n] = true
				queue.append(n)
		if not queued.has(v):
			queued[v] = true
			queue.append(v)
	return changed


static func _height(v: Vector2i, h: Dictionary, read: Callable) -> float:
	if not h.has(v):
		h[v] = float(read.call(v))
	return float(h[v])


static func _movable(v: Vector2i, can_move: Callable, cache: Dictionary) -> bool:
	if not cache.has(v):
		cache[v] = bool(can_move.call(v))
	return bool(cache[v])


## La pente la plus raide entre deux voisins (m de dénivelé par m), parmi les sommets donnés qui
## peuvent bouger. Pour les tests : après relax(), elle ne dépasse pas la pente limite.
static func steepest(h: Dictionary, read: Callable, can_move: Callable, vertices: Array) -> float:
	var worst := 0.0
	for v: Vector2i in vertices:
		if not bool(can_move.call(v)):
			continue
		for k in 8:
			var n: Vector2i = v + N8[k]
			if not bool(can_move.call(n)):
				continue
			var a := float(h[v]) if h.has(v) else float(read.call(v))
			var b := float(h[n]) if h.has(n) else float(read.call(n))
			worst = maxf(worst, (a - b) / N8_DIST[k])
	return worst
