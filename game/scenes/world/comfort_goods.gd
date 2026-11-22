class_name ComfortGoods
extends RefCounted
## Les modèles de la 0.1.24 (PRD §19.31), en formes simples : l'arrosoir et le seau percé, tenus
## en main ou en photo dans le catalogue.

const CAN := Color(0.3, 0.62, 0.5)
const PATCH := Color(0.55, 0.36, 0.2)


## L'arrosoir (bec vers −Z) : un corps rond, une anse, un long bec et sa pomme percée.
static func watering_can(size: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.add_child(Props.cyl(0.11 * size, 0.13 * size, 0.22 * size, CAN, Vector3(0, 0.11 * size, 0), 12))
	root.add_child(Props.cyl(0.1 * size, 0.1 * size, 0.012 * size, CAN.darkened(0.25), Vector3(0, 0.226 * size, 0), 12))
	var handle := Props.torus(0.07 * size, 0.09 * size, CAN.darkened(0.15), Vector3(0, 0.25 * size, 0.04 * size), 10)
	handle.rotation = Vector3(0, PI / 2, PI / 2)
	root.add_child(handle)
	root.add_child(Props.beam(Vector3(0, 0.06, -0.1) * size, Vector3(0, 0.27, -0.33) * size, 0.03 * size, CAN.darkened(0.1), true))
	var rose := Props.cyl(0.04 * size, 0.025 * size, 0.04 * size, Props.METAL, Vector3(0, 0.285 * size, -0.35 * size), 10)
	rose.rotation.x = -0.9
	rose.name = "Rose"
	root.add_child(rose)
	return root


## Le seau percé : le seau de départ, une rustine en bois et un clou de travers.
static func leaky_bucket(height := 0.26) -> Node3D:
	var root := Props.bucket(false, height)
	root.add_child(Props.box(Vector3(0.07, 0.06, 0.012), PATCH, Vector3(0.05, height * 0.35, height * 0.5), Vector3(0, 0, 0.3)))
	root.add_child(Props.beam(Vector3(0.05, height * 0.37, height * 0.51), Vector3(0.07, height * 0.39, height * 0.6), 0.012, Props.IRON))
	return root
