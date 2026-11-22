class_name Finds
extends RefCounted
## Les modèles des trouvailles de la collection (0.1.20, PRD §19.27-19.28) : faits en facettes
## comme le reste (Props). Un seul point d'entrée, `model(id)`, utilisé par les flaques et la vitrine.

const STAR := Color(0.95, 0.45, 0.32)
const URCHIN := Color(0.32, 0.18, 0.38)
const HERMIT_SHELL := Color(0.86, 0.72, 0.52)
const HERMIT_BODY := Color(0.9, 0.35, 0.25)


## Le modèle d'une trouvaille (environ 25 cm), posé sur y = 0.
static func model(id: String) -> Node3D:
	match id:
		"etoile_de_mer":
			var root := Node3D.new()
			root.add_child(Props.starfish(0.28, STAR))
			return root
		"oursin":
			return urchin(0.11)
		"bernard_ermite":
			return hermit_crab(0.14)
		"coquillage", "coq_petoncle":
			return Props.shell(0)
		"coq_bigorneau":
			var b := Props.conch(0.14, Color(0.35, 0.32, 0.3))
			return b
		"coq_couteau":
			var r := Node3D.new()
			r.add_child(Props.box(Vector3(0.3, 0.04, 0.06), Color(0.7, 0.6, 0.45), Vector3(0, 0.02, 0)))
			r.add_child(Props.box(Vector3(0.3, 0.012, 0.062), Color(0.5, 0.4, 0.3), Vector3(0, 0.045, 0)))
			return r
		"coq_conque":
			return Props.conch(0.28, Color(0.95, 0.8, 0.65))
		"coq_nautile":
			var n := Node3D.new()
			var t := Props.torus(0.04, 0.13, Color(0.95, 0.92, 0.85), Vector3(0, 0.13, 0))
			t.rotation.x = PI / 2
			n.add_child(t)
			var stripes := Props.torus(0.02, 0.08, Color(0.75, 0.4, 0.25), Vector3(0.03, 0.13, 0))
			stripes.rotation.x = PI / 2
			n.add_child(stripes)
			return n
		"perle":
			var pr := Node3D.new()
			pr.add_child(Props.scallop(0.24, Color(0.85, 0.82, 0.88)))
			pr.add_child(Props.pearl(0.05, Vector3(0, 0.07, 0.02)))
			return pr
		"poisson_clown", "chirurgien_bleu", "poisson_perroquet", "raie":
			return fish(id)
		"bouteille_carte", "bouteille_chaine", "bouteille_avion", "bouteille_crabe":
			# 0.1.23 : la bouteille, debout, son papier à la couleur du dessin.
			var b := IslandGoods.bottle()
			b.rotation.z = PI / 2
			b.position.y = 0.17
			var tint := {"bouteille_carte": Color(0.95, 0.85, 0.55), "bouteille_chaine": Color(0.6, 0.7, 0.85), "bouteille_avion": Color(0.9, 0.55, 0.5), "bouteille_crabe": Color(0.95, 0.6, 0.4)}
			var holder := Node3D.new()
			holder.add_child(b)
			holder.add_child(Props.box(Vector3(0.06, 0.02, 0.06), tint[id], Vector3(0, 0.02, 0)))
			return holder
		"piece_ancienne":
			return IslandGoods.coin()
		"coffre":
			return IslandGoods.chest()
		"oeuf_tortue":
			return IslandGoods.egg()
	# Inconnu : un petit galet (jamais d'erreur).
	var r := Node3D.new()
	r.add_child(Props.ball(0.08, Color(0.6, 0.6, 0.6), Vector3(0, 0.05, 0)))
	return r


## Un oursin : une boule violette hérissée de piquants.
static func urchin(radius: float) -> Node3D:
	var root := Node3D.new()
	root.add_child(Props.ball(radius, URCHIN, Vector3(0, radius * 0.8, 0), 5, 0.05, Vector3(1, 0.8, 1)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for k in 26:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.2, 1), rng.randf_range(-1, 1)).normalized()
		var a := Vector3(0, radius * 0.8, 0) + dir * radius * 0.8
		root.add_child(Props.beam(a, a + dir * radius * 0.9, radius * 0.08, URCHIN.darkened(0.25)))
	return root


## Un bernard-l'ermite : une coquille en spirale, deux pinces rouges et des yeux qui dépassent.
static func hermit_crab(size: float) -> Node3D:
	var root := Node3D.new()
	var shell := Props.conch(size * 1.2, HERMIT_SHELL)
	shell.position.x = -size * 0.15
	root.add_child(shell)
	for side in [-1.0, 1.0]:
		root.add_child(Props.ball(size * 0.16, HERMIT_BODY, Vector3(size * 0.45, size * 0.12, side * size * 0.2), 3))
		root.add_child(Props.beam(Vector3(size * 0.38, size * 0.2, side * size * 0.08), Vector3(size * 0.45, size * 0.42, side * size * 0.1), size * 0.04, HERMIT_BODY))
		root.add_child(Props.ball(size * 0.06, Color.BLACK, Vector3(size * 0.45, size * 0.45, side * size * 0.1)))
	return root


const FISH := {
	"poisson_clown": [Color(1.0, 0.5, 0.1), Color.WHITE, 0.16],
	"chirurgien_bleu": [Color(0.15, 0.3, 0.85), Color(1.0, 0.85, 0.2), 0.2],
	"poisson_perroquet": [Color(0.2, 0.75, 0.6), Color(0.95, 0.45, 0.6), 0.24],
}


## Un poisson du récif : un corps en losange, une queue, une bande d'une autre couleur.
## La raie est plate, en losange large, avec une longue queue.
static func fish(id: String) -> Node3D:
	var root := Node3D.new()
	if id == "raie":
		var body := Props.ball(0.18, Color(0.45, 0.4, 0.5), Vector3(0, 0.08, 0), 9, 0.0, Vector3(1.0, 0.18, 1.3))
		body.rotation.y = PI / 4
		root.add_child(body)
		root.add_child(Props.beam(Vector3(0, 0.08, 0.15), Vector3(0, 0.08, 0.5), 0.015, Color(0.35, 0.3, 0.4)))
		return root
	var spec: Array = FISH.get(id, [Color.ORANGE, Color.WHITE, 0.18])
	var size: float = spec[2]
	root.add_child(Props.ball(size, spec[0], Vector3(0, size * 0.9, 0), 3, 0.0, Vector3(0.45, 0.75, 1.0)))
	root.add_child(Props.ball(size * 0.5, spec[1], Vector3(0, size * 0.9, size * 0.05), 4, 0.0, Vector3(0.5, 1.2, 0.3)))
	var tail := Props.box(Vector3(0.02, size * 0.7, size * 0.5), spec[0].darkened(0.15), Vector3(0, size * 0.9, -size * 1.1))
	root.add_child(tail)
	root.add_child(Props.ball(size * 0.1, Color.BLACK, Vector3(size * 0.22, size * 1.05, size * 0.6)))
	root.add_child(Props.ball(size * 0.1, Color.BLACK, Vector3(-size * 0.22, size * 1.05, size * 0.6)))
	return root
