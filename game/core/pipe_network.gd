class_name PipeNetwork
extends RefCounted
## Les tuyaux (T2, PRD §7), sans aucun affichage : une grille de CASES en 3D.
##
## Le joueur pose les tuyaux à la main, une pièce par case (1 m) : au sol (niveau 0) ou en
## hauteur (niveaux 1, 2…). Deux pièces voisines (6 directions : avant, arrière, gauche, droite,
## haut, bas) sont reliées d'office : on peut faire des lignes droites, des coudes, des T, des
## montées verticales, comme on veut.
##
## Une pompe pousse l'eau dans les pièces qui la touchent (à côté d'elle au sol, ou juste
## au-dessus). L'eau suit les pièces reliées et tombe dans une zone de séchage quand une pièce
## est au-dessus de la zone (ou dedans). Rien n'est mémorisé : on recalcule tout à chaque fois,
## donc déplacer une pompe, une zone ou un tuyau ne peut pas laisser un réseau « cassé ».

const DIRS: Array[Vector3i] = [
	Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1),
	Vector3i(0, 0, -1), Vector3i(0, 1, 0), Vector3i(0, -1, 0),
]


## La case (niveau 0) qui contient ce point.
static func cell_of(pos: Vector3, cell_m: float = 1.0) -> Vector3i:
	return Vector3i(floori(pos.x / cell_m), 0, floori(pos.z / cell_m))


## Centre d'une case dans le monde. `ground_y` : hauteur du sol ; le niveau 0 est posé dessus.
static func cell_center(cell: Vector3i, cell_m: float, ground_y: float) -> Vector3:
	return Vector3((cell.x + 0.5) * cell_m, ground_y + 0.2 + cell.y * cell_m, (cell.z + 0.5) * cell_m)


## Pièces voisines d'une case.
static func neighbors(cell: Vector3i, cells: Dictionary) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for d in DIRS:
		if cells.has(cell + d):
			out.append(cell + d)
	return out


## Les cases où un tuyau touche la pompe : au sol, toutes les cases qui bordent son emprise
## (`foot`, en cases X/Z ; une seule case, celle de la pompe, si vide), et la case au-dessus d'elle.
static func pump_ports(pump_cell: Vector3i, foot: Rect2i = Rect2i()) -> Array[Vector3i]:
	if foot.size == Vector2i.ZERO:
		foot = Rect2i(pump_cell.x, pump_cell.z, 1, 1)
	var y := pump_cell.y
	var out: Array[Vector3i] = []
	for x in range(foot.position.x, foot.end.x):
		out.append(Vector3i(x, y, foot.position.y - 1))
		out.append(Vector3i(x, y, foot.end.y))
	for z in range(foot.position.y, foot.end.y):
		out.append(Vector3i(foot.position.x - 1, y, z))
		out.append(Vector3i(foot.end.x, y, z))
	out.append(pump_cell + Vector3i(0, 1, 0))
	return out


## Parcours en largeur depuis les pièces qui touchent la pompe : case -> distance (en pièces).
static func reach(pump_cell: Vector3i, cells: Dictionary, foot: Rect2i = Rect2i()) -> Dictionary:
	var dist := {}
	var queue: Array[Vector3i] = []
	for port in pump_ports(pump_cell, foot):
		if cells.has(port) and not dist.has(port):
			dist[port] = 1
			queue.append(port)
	while not queue.is_empty():
		var c: Vector3i = queue.pop_front()
		for n in neighbors(c, cells):
			if not dist.has(n):
				dist[n] = int(dist[c]) + 1
				queue.append(n)
	return dist


## Vrai si la pièce verse dans la zone (0.1.6, Othmane) : elle est au niveau `pour_level` (un seul
## bloc au-dessus du bac), et son centre est dans l'arrivée de la zone `inlet` (le milieu du bac).
static func feeds(cell: Vector3i, inlet: Rect2, pour_level: int, cell_m: float = 1.0) -> bool:
	if cell.y != pour_level:
		return false
	var c := Vector2((cell.x + 0.5) * cell_m, (cell.z + 0.5) * cell_m)
	return inlet.grow(1e-3).has_point(c)


## Les zones remplies par une pompe, de la plus proche (en pièces de tuyau) à la plus lointaine.
## `pours(case, zone)` dit si une pièce verse dans une zone (GameState.pipe_feeds).
static func zones_reached(pump_pos: Vector3, cells: Dictionary, zones: Array, pours: Callable, cell_m: float = 1.0, foot: Rect2i = Rect2i()) -> Array:
	var dist := reach(cell_of(pump_pos, cell_m), cells, foot)
	var found := []
	for zone in zones:
		var best := -1
		for c in dist:
			if bool(pours.call(c, zone)) and (best < 0 or int(dist[c]) < best):
				best = int(dist[c])
		if best >= 0:
			found.append({"zone": zone, "dist": best})
	found.sort_custom(func(a, b): return a.dist < b.dist)
	return found.map(func(f): return f.zone)


## Verse `liters` dans les zones, dans l'ordre donné (la plus proche d'abord). Renvoie ce qui
## a été accepté : le reste n'est jamais pompé.
static func distribute(liters: float, zones: Array) -> float:
	var poured := 0.0
	for zone in zones:
		if poured >= liters:
			break
		poured += (zone.logic as DryingLogic).add_water(liters - poured)
	return poured
