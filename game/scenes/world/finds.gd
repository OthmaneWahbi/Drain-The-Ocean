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
		"coquillage":
			return Props.shell(0)
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
