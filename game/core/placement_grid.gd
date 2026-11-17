class_name PlacementGrid
extends RefCounted
## Règles de placement des objets sur l'île, sans aucun affichage (PRD §10, M-22).
##
## L'île est découpée en cases carrées de `cell_m` mètres. Depuis 0.1.5, un objet posé a une
## EMPRISE RECTANGULAIRE faite de cases entières (ex. la cuvette : 4 × 3 cases, son bac plus la
## colonne de ses tas). Le rectangle est donné dans le repère de l'objet et tourne avec lui
## (quarts de tour) ; ses bords tombent toujours sur les lignes de la grille.
##
## Ce qui n'est pas un objet posé (le joueur, les noix de coco, les tuyaux, les palmiers…) reste
## un petit cercle. Une « forme » est donc l'un de :
##   {"rect": Rect2}                          (X, Z du monde)
##   {"position": Vector3, "radius": float}   (cercle, on ne regarde que X et Z)
##
## Un emplacement est valide si la forme tient sur le sable constructible (`build_radius`) et ne
## CHEVAUCHE aucune autre forme. Deux rectangles qui se touchent par un bord ne se chevauchent pas :
## deux objets peuvent être posés case contre case.

## Marge sous laquelle deux formes qui « se touchent » ne comptent pas comme un chevauchement.
const EPS := 1e-3


## Centre de la case la plus proche (on garde la hauteur telle quelle).
static func snap(pos: Vector3, cell_m: float) -> Vector3:
	return Vector3(snappedf(pos.x - cell_m / 2.0, cell_m) + cell_m / 2.0, pos.y, snappedf(pos.z - cell_m / 2.0, cell_m) + cell_m / 2.0)


## Le rectangle local d'une emprise, tourné de `rotation_deg` autour de la verticale (comme la vue :
## rotation_degrees.y), puis posé en `pos`. Exact pour les quarts de tour.
static func rect_at(local: Rect2, pos: Vector3, rotation_deg: float) -> Rect2:
	var a := deg_to_rad(rotation_deg)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for corner in [local.position, Vector2(local.end.x, local.position.y), local.end, Vector2(local.position.x, local.end.y)]:
		var v := Vector3(corner.x, 0.0, corner.y).rotated(Vector3.UP, a)
		var p := Vector2(snappedf(v.x, 1e-4), snappedf(v.z, 1e-4))
		lo = lo.min(p)
		hi = hi.max(p)
	return Rect2(lo + Vector2(pos.x, pos.z), hi - lo)


## Aligne un objet sur la grille : on le pousse au plus près de `pos` pour que les bords de son
## emprise (tournée) tombent sur les lignes de la grille. Une emprise de largeur impaire a donc
## son centre au milieu d'une case, une emprise de largeur paire sur une ligne.
static func snap_rect(pos: Vector3, local: Rect2, rotation_deg: float, cell_m: float) -> Vector3:
	var r := rect_at(local, Vector3.ZERO, rotation_deg)
	var x := snappedf(pos.x + r.position.x, cell_m) - r.position.x
	var z := snappedf(pos.z + r.position.y, cell_m) - r.position.y
	return Vector3(snappedf(x, 1e-4), pos.y, snappedf(z, 1e-4))


static func rect_shape(r: Rect2) -> Dictionary:
	return {"rect": r}


static func circle_shape(pos: Vector3, radius: float) -> Dictionary:
	return {"position": pos, "radius": radius}


## Vrai si les deux formes se chevauchent (se toucher ne compte pas).
static func overlaps(a: Dictionary, b: Dictionary) -> bool:
	if a.has("rect") and b.has("rect"):
		var ra: Rect2 = a.rect
		var rb: Rect2 = b.rect
		return ra.position.x < rb.end.x - EPS and rb.position.x < ra.end.x - EPS \
			and ra.position.y < rb.end.y - EPS and rb.position.y < ra.end.y - EPS
	if a.has("rect"):
		return _rect_circle(a.rect, b.position, float(b.radius))
	if b.has("rect"):
		return _rect_circle(b.rect, a.position, float(a.radius))
	var pa: Vector3 = a.position
	var pb: Vector3 = b.position
	return Vector2(pa.x, pa.z).distance_to(Vector2(pb.x, pb.z)) < float(a.radius) + float(b.radius) - EPS


static func _rect_circle(r: Rect2, center: Vector3, radius: float) -> bool:
	var c := Vector2(center.x, center.z)
	var closest := c.clamp(r.position, r.end)
	return closest.distance_to(c) < radius - EPS


## Distance (au sol) entre un point et une forme : 0 dedans.
static func distance_to(shape: Dictionary, pos: Vector3) -> float:
	var c := Vector2(pos.x, pos.z)
	if shape.has("rect"):
		var r: Rect2 = shape.rect
		return c.clamp(r.position, r.end).distance_to(c)
	var p: Vector3 = shape.position
	return maxf(c.distance_to(Vector2(p.x, p.z)) - float(shape.radius), 0.0)


## Vrai si la forme tient entièrement dans le disque constructible de rayon `build_radius`.
static func fits(shape: Dictionary, build_radius: float) -> bool:
	if is_inf(build_radius):
		return true
	if shape.has("rect"):
		var r: Rect2 = shape.rect
		for corner in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
			if (corner as Vector2).length() > build_radius + EPS:
				return false
		return true
	var p: Vector3 = shape.position
	return Vector2(p.x, p.z).length() + float(shape.radius) <= build_radius + EPS


## La forme tient sur l'île et ne chevauche aucune de `others`.
static func is_valid(shape: Dictionary, others: Array, build_radius: float) -> bool:
	return fits(shape, build_radius) and conflicts(shape, others).is_empty()


## Les formes de `others` que celle-ci chevauche (pour les montrer en rouge).
static func conflicts(shape: Dictionary, others: Array) -> Array:
	var out := []
	for o in others:
		if overlaps(shape, o):
			out.append(o)
	return out


## Les cases (x, z) couvertes par un rectangle aligné sur la grille.
static func cells_of(r: Rect2, cell_m: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var x0 := roundi(r.position.x / cell_m)
	var z0 := roundi(r.position.y / cell_m)
	var x1 := roundi(r.end.x / cell_m)
	var z1 := roundi(r.end.y / cell_m)
	for x in range(x0, x1):
		for z in range(z0, z1):
			out.append(Vector2i(x, z))
	return out


## Ramène un angle entre 0 et 360 degrés.
static func wrap_deg(deg: float) -> float:
	return fposmod(deg, 360.0)
