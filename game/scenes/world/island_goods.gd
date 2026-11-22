class_name IslandGoods
extends RefCounted
## Les modèles de la 0.1.23 (PRD §19.30), en facettes comme le reste : longue-vue, feu de camp,
## décor de l'île (dalle, clôture, lampion, tapis, coquillage géant), bouteille à la mer, caisse
## d'épave, nid et tortues, pousse de cocotier, détecteur de métaux, trouvailles (pièce, coffre,
## œuf), îles lointaines et tourbillon du drain.

const WOOD := Color(0.6, 0.42, 0.25)
const WOOD_DARK := Color(0.4, 0.27, 0.15)
const DRIFT := Color(0.72, 0.66, 0.58)
const BRASS := Color(0.85, 0.66, 0.3)
const GOLD := Color(1.0, 0.8, 0.25)
const STONE := Color(0.82, 0.78, 0.7)
const PAPER := Color(0.98, 0.94, 0.82)
const BOTTLE := Color(0.45, 0.75, 0.55, 0.6)
const TURTLE := Color(0.35, 0.55, 0.3)
const SHELL_TOP := Color(0.45, 0.35, 0.2)
const FLAME := Color(1.0, 0.55, 0.15)
const FLAME_IN := Color(1.0, 0.85, 0.3)
const LANTERN := Color(1.0, 0.45, 0.35)
const ISLAND := Color(0.28, 0.42, 0.3)  # vert sombre : de loin, la brume l'éclaircit


static func spyglass() -> Node3D:
	var root := Node3D.new()
	for i in 3:
		var a := TAU * i / 3.0
		root.add_child(Props.beam(Vector3(cos(a) * 0.35, 0.0, sin(a) * 0.35), Vector3(0, 1.1, 0), 0.04, WOOD_DARK, true))
	var tube := Node3D.new()
	tube.name = "Tube"
	tube.position.y = 1.15
	tube.rotation.x = -0.25
	# Le tube tient dans sa case (1 m) : oculaire, corps, objectif.
	tube.add_child(Props.beam(Vector3(0, 0, 0.22), Vector3(0, 0, -0.28), 0.09, BRASS, true))
	tube.add_child(Props.beam(Vector3(0, 0, -0.28), Vector3(0, 0, -0.44), 0.12, BRASS.darkened(0.15), true))
	tube.add_child(Props.beam(Vector3(0, 0, 0.22), Vector3(0, 0, 0.36), 0.06, WOOD_DARK, true))
	root.add_child(tube)
	return root


## Le feu de camp : un rond de pierres, des bûches en croix et (nœud « Fire ») les flammes, les
## braises et la lumière (« Light »), allumées seulement la nuit par la vue.
static func campfire() -> Node3D:
	var root := Node3D.new()
	for i in 8:
		var a := TAU * i / 8.0
		root.add_child(Props.ball(0.08, STONE.darkened(0.1 * (i % 2)), Vector3(cos(a) * 0.32, 0.05, sin(a) * 0.32), i, 0.2, Vector3(1.2, 0.8, 1.0)))
	for i in 3:
		var a := TAU * i / 3.0
		root.add_child(Props.beam(Vector3(cos(a) * 0.28, 0.03, sin(a) * 0.28), Vector3(0, 0.2, 0), 0.06, WOOD_DARK, true))
	var fire := Node3D.new()
	fire.name = "Fire"
	root.add_child(fire)
	for i in 3:
		var f := Props.cyl(0.0, 0.12 - i * 0.025, 0.35 - i * 0.07, FLAME if i == 0 else FLAME_IN, Vector3(0, 0.25 + i * 0.03, 0), 6)
		f.name = "Flame%d" % i
		_glow(f, FLAME if i == 0 else FLAME_IN)
		fire.add_child(f)
	var light := OmniLight3D.new()
	light.name = "Light"
	light.light_color = Color(1.0, 0.6, 0.3)
	light.omni_range = 6.0
	light.light_energy = 2.0
	light.position.y = 0.5
	fire.add_child(light)
	return root


static func _glow(mi: MeshInstance3D, color: Color) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 1.5
	mi.material_override = m


static func path_tile() -> Node3D:
	var root := Node3D.new()
	root.add_child(Props.box(Vector3(0.86, 0.05, 0.86), STONE, Vector3(0, 0.025, 0)))
	root.add_child(Props.box(Vector3(0.4, 0.052, 0.86), STONE.darkened(0.06), Vector3(-0.2, 0.026, 0)))
	var sh := Props.shell(1, 0.12)
	sh.position = Vector3(0.22, 0.05, 0.2)
	root.add_child(sh)
	return root


static func fence() -> Node3D:
	var root := Node3D.new()
	for x in [-0.42, 0.0, 0.42]:
		root.add_child(Props.box(Vector3(0.1, 0.7, 0.08), DRIFT, Vector3(x, 0.35, 0), Vector3(0, 0, x * 0.1)))
	for y in [0.22, 0.52]:
		root.add_child(Props.box(Vector3(0.98, 0.07, 0.05), DRIFT.darkened(0.1), Vector3(0, y, 0.05)))
	return root


## Le lampion sur son piquet ; nœud « Glow » (le papier) et « Light », allumés la nuit par la vue.
static func lantern() -> Node3D:
	var root := Node3D.new()
	root.add_child(Props.cyl(0.025, 0.03, 1.3, WOOD_DARK, Vector3(0, 0.65, 0), 6))
	root.add_child(Props.beam(Vector3(0, 1.3, 0), Vector3(0.25, 1.32, 0), 0.025, WOOD_DARK))
	var glow := Props.ball(0.16, LANTERN, Vector3(0.25, 1.1, 0), 3, 0.0, Vector3(1.0, 1.3, 1.0))
	glow.name = "Glow"
	root.add_child(glow)
	var light := OmniLight3D.new()
	light.name = "Light"
	light.light_color = Color(1.0, 0.7, 0.5)
	light.omni_range = 4.0
	light.light_energy = 1.2
	light.position = Vector3(0.25, 1.1, 0)
	root.add_child(light)
	return root


static func mat() -> Node3D:
	var root := Node3D.new()
	for i in 6:
		var x := -0.75 + i * 0.3
		root.add_child(Props.box(Vector3(0.3, 0.02, 0.8), [Color(0.95, 0.35, 0.35), Color(0.98, 0.95, 0.85), Color(0.25, 0.6, 0.85)][i % 3], Vector3(x, 0.01, 0)))
	return root


static func giant_shell() -> Node3D:
	var root := Node3D.new()
	var sh := Props.conch(0.85, Color(1.0, 0.78, 0.66))
	sh.position.y = 0.0
	root.add_child(sh)
	return root


## Une bouteille couchée, un papier roulé dedans, un bouchon.
static func bottle() -> Node3D:
	var root := Node3D.new()
	var glass := Props.cyl(0.07, 0.07, 0.3, BOTTLE, Vector3.ZERO, 10)
	glass.rotation.z = PI / 2
	glass.position.y = 0.07
	var gm := StandardMaterial3D.new()
	gm.albedo_color = BOTTLE
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.material_override = gm
	root.add_child(glass)
	var neck := Props.cyl(0.03, 0.03, 0.1, BOTTLE.darkened(0.2), Vector3(0.2, 0.07, 0), 8)
	neck.rotation.z = PI / 2
	root.add_child(neck)
	var cork := Props.cyl(0.03, 0.03, 0.05, WOOD, Vector3(0.27, 0.07, 0), 6)
	cork.rotation.z = PI / 2
	root.add_child(cork)
	var paper := Props.cyl(0.035, 0.035, 0.2, PAPER, Vector3(0, 0.07, 0), 6)
	paper.rotation.z = PI / 2
	root.add_child(paper)
	return root


## La caisse d'un autre naufragé : planches grises, sans logo, une corde.
static func wreck_crate() -> Node3D:
	var root := Node3D.new()
	root.add_child(Props.box(Vector3(0.8, 0.6, 0.7), DRIFT.darkened(0.25), Vector3(0, 0.3, 0)))
	for y in [0.12, 0.3, 0.48]:
		root.add_child(Props.box(Vector3(0.82, 0.04, 0.72), DRIFT.darkened(0.4), Vector3(0, y, 0)))
	root.add_child(Props.box(Vector3(0.84, 0.05, 0.05), Props.ROPE, Vector3(0, 0.62, 0)))
	var weed := Props.box(Vector3(0.3, 0.02, 0.12), Color(0.25, 0.5, 0.25), Vector3(0.1, 0.61, 0.15), Vector3(0, 0.6, 0))
	root.add_child(weed)
	return root


static func nest() -> Node3D:
	var root := Node3D.new()
	# Un petit tertre de sable remué, un peu plus foncé que la plage (sable humide).
	root.add_child(Props.ball(0.38, Color(0.72, 0.55, 0.32), Vector3(0, 0.0, 0), 4, 0.15, Vector3(1.0, 0.35, 1.0)))
	root.add_child(Props.beam(Vector3(-0.1, 0.08, 0.05), Vector3(-0.05, 0.4, 0.0), 0.02, WOOD_DARK))
	root.add_child(Props.beam(Vector3(0.12, 0.08, -0.05), Vector3(0.2, 0.35, -0.1), 0.02, WOOD_DARK))
	return root


## Une tortue de `size` m de long (vers −Z), pattes en nœuds « Leg0 » à « Leg3 ».
static func turtle(size: float) -> Node3D:
	var root := Node3D.new()
	root.add_child(Props.ball(size * 0.45, SHELL_TOP, Vector3(0, size * 0.18, 0), 5, 0.05, Vector3(1.0, 0.45, 1.25)))
	root.add_child(Props.ball(size * 0.14, TURTLE, Vector3(0, size * 0.16, -size * 0.6), 2))
	var k := 0
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var leg := Props.ball(size * 0.12, TURTLE, Vector3(sx * size * 0.38, size * 0.07, sz * size * 0.35), k, 0.0, Vector3(1.5, 0.4, 0.8))
			leg.name = "Leg%d" % k
			root.add_child(leg)
			k += 1
	return root


static func sapling() -> Node3D:
	var root := Node3D.new()
	root.add_child(Models.coconut(0.12, 3))
	root.add_child(Props.cyl(0.02, 0.03, 0.35, Color(0.45, 0.6, 0.25), Vector3(0, 0.25, 0), 5))
	for i in 4:
		var a := TAU * i / 4.0
		root.add_child(Props.beam(Vector3(0, 0.42, 0), Vector3(cos(a) * 0.3, 0.35, sin(a) * 0.3), 0.05, Color(0.3, 0.7, 0.3)))
	return root


## Le détecteur de métaux, tenu à la main : un manche, un disque au bout.
static func detector() -> Node3D:
	var root := Node3D.new()
	root.add_child(Props.beam(Vector3(0, 0, 0), Vector3(0, -0.2, -0.9), 0.03, Props.METAL, true))
	var disc := Props.cyl(0.14, 0.14, 0.03, Color(0.2, 0.22, 0.25), Vector3(0, -0.24, -0.95), 12)
	root.add_child(disc)
	root.add_child(Props.box(Vector3(0.08, 0.06, 0.12), Color(0.95, 0.75, 0.2), Vector3(0, -0.04, -0.2)))
	var led := Props.ball(0.02, Color(0.3, 1.0, 0.4), Vector3(0, 0.0, -0.22), 1)
	led.name = "Led"
	root.add_child(led)
	return root


static func coin() -> Node3D:
	var root := Node3D.new()
	var c := Props.cyl(0.1, 0.1, 0.02, GOLD, Vector3(0, 0.1, 0), 12)
	c.rotation.x = PI / 2
	root.add_child(c)
	return root


static func chest() -> Node3D:
	var root := Node3D.new()
	root.add_child(Props.box(Vector3(0.5, 0.25, 0.32), WOOD, Vector3(0, 0.125, 0)))
	root.add_child(Props.ball(0.18, WOOD.darkened(0.1), Vector3(0, 0.25, 0), 2, 0.0, Vector3(1.4, 0.55, 0.9)))
	for x in [-0.18, 0.18]:
		root.add_child(Props.box(Vector3(0.04, 0.36, 0.34), BRASS, Vector3(x, 0.18, 0)))
	root.add_child(Props.box(Vector3(0.06, 0.07, 0.02), GOLD, Vector3(0, 0.22, 0.17)))
	return root


static func egg() -> Node3D:
	var root := Node3D.new()
	root.add_child(Props.ball(0.09, Color(0.98, 0.96, 0.9), Vector3(0, 0.09, 0), 1, 0.0, Vector3(1.0, 1.15, 1.0)))
	return root


## Une île lointaine : une silhouette basse, deux palmiers, et parfois une cabine (couleur).
static func far_island(width: float, booth: Color = Color(0, 0, 0, 0)) -> Node3D:
	var root := Node3D.new()
	# 0.1.23 (captures) : une boule étirée par `stretch` restait une mince lamelle à 420 m ;
	# la colline est maintenant mise à l'échelle par son nœud (largeur, hauteur ~12 %, profondeur).
	var hill := Props.ball(1.0, ISLAND, Vector3.ZERO, 7, 0.1)
	hill.scale = Vector3(width * 0.5, width * 0.12, width * 0.3)
	root.add_child(hill)
	var k := width / 40.0  # palmiers et cabine à l'échelle de l'île (vus de très loin)
	for x in [-0.15, 0.2]:
		root.add_child(Props.cyl(0.4 * k, 0.6 * k, 9.0 * k, ISLAND.darkened(0.15), Vector3(x * width, width * 0.1 + 4.5 * k, 0), 5))
		var crown := Props.ball(3.0, ISLAND.darkened(0.1), Vector3(x * width, width * 0.1 + 9.5 * k, 0), 3, 0.2, Vector3(1.6, 0.5, 1.6))
		crown.scale = Vector3.ONE * k
		root.add_child(crown)
	if booth.a > 0.0:
		root.add_child(Props.box(Vector3(1.6, 3.4, 1.6) * k, booth, Vector3(width * 0.05, width * 0.11 + 1.7 * k, 0)))
	return root


## Le petit tourbillon du drain, au large (vu à la longue-vue) : des anneaux qui tournent.
static func whirlpool() -> Node3D:
	var root := Node3D.new()
	root.name = "Whirlpool"
	for i in 4:
		var ring := Props.torus(1.2 + i * 1.1, 1.5 + i * 1.1, Color(0.85, 0.95, 1.0, 1.0).darkened(0.08 * i), Vector3(0, -0.05 * i, 0), 20)
		ring.scale = Vector3(1.0, 0.12, 1.0)
		ring.name = "Ring%d" % i
		root.add_child(ring)
	return root
