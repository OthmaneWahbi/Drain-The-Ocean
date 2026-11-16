class_name PhysicsLayers
extends RefCounted
## Les couches de collision (anti-blocage). Le joueur ne se cogne qu'aux objets SOLID (sol, zones,
## caisses, décors…). Les petits objets (tas de matériaux, tuyaux, coquillages, noix de coco) sont
## WALK_THROUGH : on passe à travers, mais le rayon de visée les trouve toujours (E, clic).
## Ainsi, aucun petit objet ne peut enfermer le joueur.

const SOLID := 1
const WALK_THROUGH := 2
## Ce que le rayon de visée du joueur touche.
const AIM := SOLID | WALK_THROUGH


## Rend un objet traversable : on le vise, on ne s'y cogne pas.
static func make_walk_through(body: CollisionObject3D) -> void:
	body.collision_layer = WALK_THROUGH
	body.collision_mask = 0
