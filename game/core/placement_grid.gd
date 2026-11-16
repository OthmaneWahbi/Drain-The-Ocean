class_name PlacementGrid
extends RefCounted
## Règles de placement des objets sur l'île, sans aucun affichage (PRD §10, M-22).
##
## L'île est découpée en cases carrées de `cell_m` mètres. Un objet posé a une EMPRISE :
## un cercle de rayon r autour de son centre. Un emplacement est valide si :
## - l'emprise tient entièrement sur le sable sec (dans `build_radius` du centre de l'île) ;
## - elle ne touche aucune autre emprise (objets déplaçables et obstacles fixes).


## Centre de la case la plus proche (on garde la hauteur telle quelle).
static func snap(pos: Vector3, cell_m: float) -> Vector3:
	return Vector3(snappedf(pos.x - cell_m / 2.0, cell_m) + cell_m / 2.0, pos.y, snappedf(pos.z - cell_m / 2.0, cell_m) + cell_m / 2.0)


## `others` : liste de {position: Vector3, radius: float}. On ne regarde que X et Z.
static func is_valid(pos: Vector3, radius: float, others: Array, build_radius: float) -> bool:
	var flat := Vector2(pos.x, pos.z)
	if flat.length() + radius > build_radius:
		return false
	for o in others:
		var op: Vector3 = o.position
		if flat.distance_to(Vector2(op.x, op.z)) < radius + float(o.radius):
			return false
	return true
