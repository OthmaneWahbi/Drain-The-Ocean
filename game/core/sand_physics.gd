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
## 0.1.15 : l'éboulement regarde aussi les 8 voisins « en L » (un pas et deux pas), à 1,12 m :
## avec seulement 8 voisins, la pente d'un trou formait un octogone à pans plats et à arêtes
## vives (les « triangles » qu'Othmane voyait) ; avec 16, le bord est presque rond.
const N16: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1),
	Vector2i(2, 1), Vector2i(-2, 1), Vector2i(2, -1), Vector2i(-2, -1),
	Vector2i(1, 2), Vector2i(-1, 2), Vector2i(1, -2), Vector2i(-1, -2)]
const N16_DIST: Array[float] = [0.5, 0.5, 0.5, 0.5, 0.70710678, 0.70710678, 0.70710678, 0.70710678,
	1.11803399, 1.11803399, 1.11803399, 1.11803399, 1.11803399, 1.11803399, 1.11803399, 1.11803399]
## En dessous de cet excès (m), une pente est considérée comme stable.
const EPS := 0.01


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
## `floors` (0.1.14) : un plancher par sommet, à la place de `floor_y` (on creuse plus profond à
## l'intérieur de l'île qu'au bord de l'eau).
static func carve(heights: Dictionary, weights: Dictionary, volume_m3: float, dig: bool, floor_y: float, ceil_y: float, floors: Dictionary = {}) -> Dictionary:
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
		var dh := minf(float(weights[v]) * depth, _room(out[v], dig, float(floors.get(v, floor_y)), ceil_y))
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
static func relax(h: Dictionary, read: Callable, can_move: Callable, seeds: Array, tan_dry: float, tan_wet: float, wet_below_y: float, locked: Dictionary = {}, max_ops: int = 60000) -> Dictionary:
	# 0.1.14 : sur une grille dense autour du geste (tableaux), plus vite qu'avec des dictionnaires
	# et des appels de fonction à chaque voisin : un trou de 3 m ou un gros tas restent fluides.
	# Hors de cette fenêtre (RELAX_MARGIN sommets autour des graines), le sable ne bouge pas.
	var changed := {}
	if seeds.is_empty():
		return changed
	var lo := Vector2i(1 << 30, 1 << 30)
	var hi := -lo
	for sd: Vector2i in seeds:
		lo = Vector2i(mini(lo.x, sd.x), mini(lo.y, sd.y))
		hi = Vector2i(maxi(hi.x, sd.x), maxi(hi.y, sd.y))
	lo -= Vector2i(RELAX_MARGIN, RELAX_MARGIN)
	hi += Vector2i(RELAX_MARGIN, RELAX_MARGIN)
	var w := hi.x - lo.x + 1
	var n := w * (hi.y - lo.y + 1)
	var hs := PackedFloat64Array()
	hs.resize(n)
	# État d'un sommet : 0 inconnu ; 1 lu, peut bouger ; 2 lu, fixe.
	var st := PackedByteArray()
	st.resize(n)
	var queued := PackedByteArray()
	queued.resize(n)
	var moved := PackedByteArray()
	moved.resize(n)
	var off := PackedInt32Array()
	var lim_dry := PackedFloat64Array()
	var lim_wet := PackedFloat64Array()
	for k in 16:
		off.append(N16[k].y * w + N16[k].x)
		lim_dry.append(tan_dry * N16_DIST[k])
		lim_wet.append(tan_wet * N16_DIST[k])
	var queue := PackedInt32Array()
	for sd: Vector2i in seeds:
		var idx := (sd.y - lo.y) * w + (sd.x - lo.x)
		if queued[idx] == 0:
			queued[idx] = 1
			queue.append(idx)
	var ns := PackedInt32Array()
	ns.resize(16)
	var ds := PackedFloat64Array()
	ds.resize(16)
	var i := 0
	while i < queue.size() and i < max_ops:
		var vi := queue[i]
		i += 1
		queued[vi] = 0
		if st[vi] == 0:
			_load(vi, w, lo, hs, st, h, read, can_move, locked)
		if st[vi] != 1:
			continue
		var vx := vi % w
		var vy := vi / w
		if vx < 2 or vy < 2 or vx > w - 3 or vi >= n - 2 * w:
			continue  # le bord de la fenêtre ne bouge pas
		var hv := hs[vi]
		var cnt := 0
		var total := 0.0
		var most := 0.0
		for k in 16:
			var ni := vi + off[k]
			if st[ni] == 0:
				_load(ni, w, lo, hs, st, h, read, can_move, locked)
			if st[ni] != 1:
				continue
			var hn := hs[ni]
			var d := hv - hn - (lim_wet[k] if hn < wet_below_y else lim_dry[k])
			if d > EPS:
				ns[cnt] = ni
				ds[cnt] = d
				cnt += 1
				total += d
				most = maxf(most, d)
		if cnt == 0:
			continue
		var move := 0.5 * most
		for k in cnt:
			var ni := ns[k]
			var amt := move * ds[k] / total
			hs[ni] += amt
			hv -= amt
			moved[ni] = 1
			if queued[ni] == 0:
				queued[ni] = 1
				queue.append(ni)
		hs[vi] = hv
		moved[vi] = 1
		# v a baissé : ses voisins plus hauts peuvent maintenant être trop raides, et lui encore.
		for k in 16:
			var ni := vi + off[k]
			if queued[ni] == 0:
				queued[ni] = 1
				queue.append(ni)
		if queued[vi] == 0:
			queued[vi] = 1
			queue.append(vi)
	for idx in n:
		if moved[idx] == 1:
			var v := Vector2i(lo.x + idx % w, lo.y + idx / w)
			h[v] = hs[idx]
			changed[v] = true
	return changed


## La fenêtre de l'éboulement autour des sommets touchés (sommets ; 0.1.14).
const RELAX_MARGIN := 40


## Lit un sommet de la fenêtre de relax() : sa hauteur et s'il peut bouger.
static func _load(idx: int, w: int, lo: Vector2i, hs: PackedFloat64Array, st: PackedByteArray, h: Dictionary, read: Callable, can_move: Callable, locked: Dictionary) -> void:
	var v := Vector2i(lo.x + idx % w, lo.y + idx / w)
	var y: Variant = h.get(v)
	hs[idx] = float(y) if y != null else float(read.call(v))
	st[idx] = 1 if (not locked.has(v) and bool(can_move.call(v))) else 2


## Adoucir (0.1.15) : après l'éboulement, `passes` passes de diffusion entre voisins (4 directs,
## et les diagonales à moitié) : chaque paire échange `k` × leur différence de hauteur, donc le
## volume ne change pas. Seuls les sommets de `region` (et leurs voisins) qui peuvent bouger
## échangent. L'éboulement à 8 voisins laisse des bords en étoile (des pointes, et leurs ombres) :
## ce lissage les arrondit, comme du vrai sable qui roule. Renvoie les sommets qui ont bougé.
static func soften(h: Dictionary, read: Callable, can_move: Callable, region: Array, passes: int, k: float, locked: Dictionary = {}) -> Dictionary:
	var changed := {}
	if region.is_empty() or passes <= 0 or k <= 0.0:
		return changed
	var area := {}
	for v: Vector2i in region:
		area[v] = true
		for d in N8:
			area[v + d] = true
	var movable := {}
	var verts: Array[Vector2i] = []
	for v: Vector2i in area:
		if not locked.has(v) and _movable(v, can_move, movable):
			verts.append(v)
			_height(v, h, read)
	var free := {}
	for v in verts:
		free[v] = true
	# Les paires (chacune une fois) : droite, bas, et les deux diagonales vers le bas.
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 1)]
	var wts: Array[float] = [1.0, 1.0, 0.5, 0.5]
	for _p in passes:
		var delta := {}
		for v in verts:
			var hv := float(h[v])
			for q in 4:
				var n: Vector2i = v + dirs[q]
				if not free.has(n):
					continue
				var f := k * wts[q] * (float(h[n]) - hv)
				delta[v] = float(delta.get(v, 0.0)) + f
				delta[n] = float(delta.get(n, 0.0)) - f
		for v: Vector2i in delta:
			var dv := float(delta[v])
			if absf(dv) > 1e-7:
				h[v] = float(h[v]) + dv
				changed[v] = true
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
