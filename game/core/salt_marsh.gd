class_name SaltMarsh
extends RefCounted
## Les marais salants creusés à la pelle (0.1.20, PRD §19.27). Logique pure sur le terrain :
## trouver le trou sous un point, dire s'il fait un marais, ses bords, sa matière.
## Un trou = des cases de 1 m reliées (par un côté), chacune creusée d'au moins `min_depth`
## sous son sol d'origine.

const NEIGHBORS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


## La hauteur moyenne d'origine d'une case (avant la pelle).
static func base_mean(terrain: TerrainLogic, cell: Vector2i) -> float:
	var s := 0.0
	var vs := TerrainLogic.cell_vertices(cell)
	for v in vs:
		s += terrain.base_vertex(v.x, v.y).y
	return s / vs.size()


## De combien la case est creusée sous son sol d'origine (m, positif = creusé).
static func depth(terrain: TerrainLogic, cell: Vector2i) -> float:
	return base_mean(terrain, cell) - terrain.cell_mean(cell)


static func is_dug(terrain: TerrainLogic, cell: Vector2i, min_depth: float) -> bool:
	return depth(terrain, cell) >= min_depth


## Les cases du trou qui contient `start` (les plus proches d'abord), au plus `max_cells`.
## `excluded(cell) -> bool` : cases à ignorer (la mer…). Vide si `start` n'est pas creusée.
static func region(terrain: TerrainLogic, start: Vector2i, min_depth: float, max_cells: int, excluded: Callable = Callable()) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not is_dug(terrain, start, min_depth) or (excluded.is_valid() and excluded.call(start)):
		return out
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty() and out.size() < max_cells:
		var c: Vector2i = queue.pop_front()
		out.append(c)
		for d in NEIGHBORS:
			var n: Vector2i = c + d
			if seen.has(n):
				continue
			seen[n] = true
			if is_dug(terrain, n, min_depth) and not (excluded.is_valid() and excluded.call(n)):
				queue.append(n)
	return out


## Le trou fait-il un marais ? Assez de cases, et un fond assez plat.
static func is_valid(terrain: TerrainLogic, cells: Array, min_cells: int, max_spread: float) -> bool:
	if cells.size() < min_cells:
		return false
	return spread(terrain, cells) <= max_spread


static func spread(terrain: TerrainLogic, cells: Array) -> float:
	var lo := INF
	var hi := -INF
	for c: Vector2i in cells:
		var m := terrain.cell_mean(c)
		lo = minf(lo, m)
		hi = maxf(hi, m)
	return hi - lo if lo <= hi else 0.0


## Le fond le plus bas du marais (m).
static func floor_y(terrain: TerrainLogic, cells: Array) -> float:
	var lo := INF
	for c: Vector2i in cells:
		lo = minf(lo, terrain.cell_mean(c))
	return lo


## Les cases autour du trou (qui touchent une case du trou par un côté ou un coin).
static func rim(cells: Array) -> Array[Vector2i]:
	var inside := {}
	for c: Vector2i in cells:
		inside[c] = true
	var out: Array[Vector2i] = []
	var seen := {}
	for c: Vector2i in cells:
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				var n := c + Vector2i(dx, dz)
				if inside.has(n) or seen.has(n):
					continue
				seen[n] = true
				out.append(n)
	return out


## La matière d'une case : celle de son sommet du milieu.
static func cell_soil(terrain: TerrainLogic, cell: Vector2i) -> int:
	return terrain.soil(cell * TerrainLogic.SUB + Vector2i(TerrainLogic.SUB / 2, TerrainLogic.SUB / 2))


## La part de terre parmi ces cases (0 à 1).
static func earth_ratio(terrain: TerrainLogic, cells: Array) -> float:
	if cells.is_empty():
		return 0.0
	var n := 0
	for c: Vector2i in cells:
		if cell_soil(terrain, c) == TerrainLogic.Soil.EARTH:
			n += 1
	return float(n) / cells.size()


## La case du trou la plus proche de son centre : là où le marais « est » (tuyaux, texte d'aide).
static func center_cell(cells: Array) -> Vector2i:
	var mid := Vector2.ZERO
	for c: Vector2i in cells:
		mid += Vector2(c)
	mid /= maxf(cells.size(), 1)
	var best: Vector2i = cells[0]
	for c: Vector2i in cells:
		if Vector2(c).distance_squared_to(mid) < Vector2(best).distance_squared_to(mid) - 1e-6:
			best = c
	return best


## Vrai si une case à moins de `reach` cases du trou est dans la mer (`is_sea(cell)`).
static func touches_sea(cells: Array, reach: int, is_sea: Callable) -> bool:
	var inside := {}
	for c: Vector2i in cells:
		inside[c] = true
	var seen := {}
	for c: Vector2i in cells:
		for dz in range(-reach, reach + 1):
			for dx in range(-reach, reach + 1):
				var n := c + Vector2i(dx, dz)
				if inside.has(n) or seen.has(n):
					continue
				seen[n] = true
				if is_sea.call(n):
					return true
	return false
