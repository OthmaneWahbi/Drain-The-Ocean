class_name LaterGoods
extends RefCounted
## Les modèles de la 0.1.25 (PRD §19.32), en formes simples : la tour de sable (un seau retourné,
## 1 à 3 étages), le socle des trophées et ses statues, la baleine et son jet, le dauphin.

const SAND := Color(0.86, 0.72, 0.46)
const SAND_DARK := Color(0.74, 0.6, 0.36)
const STONE := Color(0.5, 0.48, 0.45)
const STONE_DARK := Color(0.36, 0.35, 0.34)
const GOLD := Color(0.95, 0.74, 0.24)
const WHALE := Color(0.24, 0.3, 0.38)
const DOLPHIN := Color(0.32, 0.38, 0.48)
const BELLY := Color(0.86, 0.88, 0.9)
const SPRAY := Color(0.97, 0.98, 1.0)

## La hauteur d'un étage de tour (m) et son rayon en bas, pour le premier étage.
const FLOOR_H := 0.2
const BASE_R := 0.2


## Une tour de sable de `floors` étages : chaque étage est un seau retourné (tronc de cône
## strié), un peu plus petit que celui du dessous, avec ses créneaux au sommet.
static func sand_tower(floors: int) -> Node3D:
	var root := Node3D.new()
	var y := 0.0
	var r := BASE_R
	for i in clampi(floors, 1, 3):
		var top := r * 0.8
		root.add_child(Props.cyl(top, r, FLOOR_H, SAND if i % 2 == 0 else SAND_DARK, Vector3(0, y + FLOOR_H / 2.0, 0), 10))
		y += FLOOR_H
		r = top * 0.92
	# Les créneaux du dernier étage et un petit drapeau (un bâton, un bout de feuille).
	for k in 5:
		var a := TAU * k / 5.0
		root.add_child(Props.box(Vector3(0.05, 0.05, 0.05), SAND, Vector3(cos(a) * r * 0.85, y + 0.025, sin(a) * r * 0.85)))
	root.add_child(Props.beam(Vector3(0, y, 0), Vector3(0, y + 0.22, 0), 0.012, Props.WOOD_DARK))
	root.add_child(Props.box(Vector3(0.1, 0.06, 0.008), Color(0.3, 0.65, 0.3), Vector3(0.05, y + 0.19, 0)))
	return root


## Le socle des trophées : une longue dalle de pierre sur deux pieds, avec dix petits plots
## (un par succès) et une plaque. Les statues se posent sur les plots (`slot_position`).
static func trophy_stand(slots: int) -> Node3D:
	var root := Node3D.new()
	for x in [-0.75, 0.75]:
		root.add_child(Props.box(Vector3(0.3, 0.5, 0.5), STONE_DARK, Vector3(x, 0.25, 0)))
	root.add_child(Props.box(Vector3(1.9, 0.1, 0.7), STONE, Vector3(0, 0.55, 0)))
	for i in slots:
		root.add_child(Props.cyl(0.07, 0.08, 0.05, STONE_DARK, slot_position(i, slots) - Vector3(0, 0.025, 0), 8))
	return root


## Où se pose la statue `i` sur le socle (deux rangées de cinq).
static func slot_position(i: int, slots: int) -> Vector3:
	var per_row := ceili(slots / 2.0)
	var row := i / per_row
	var col := i % per_row
	return Vector3((col - (per_row - 1) / 2.0) * 0.36, 0.65, -0.15 + row * 0.3)


## La petite statue dorée d'un succès : une forme qui rappelle ce qu'on a fait.
static func statue(id: String) -> Node3D:
	var root := Node3D.new()
	match id:
		"premier_achat":  # une caisse et son parachute
			root.add_child(Props.box(Vector3(0.1, 0.1, 0.1), GOLD, Vector3(0, 0.05, 0)))
			root.add_child(Props.ball(0.08, GOLD, Vector3(0, 0.2, 0), 1, 0.0, Vector3(1.0, 0.5, 1.0)))
		"sel_100":  # un tas de sel
			root.add_child(Props.cyl(0.0, 0.09, 0.14, GOLD, Vector3(0, 0.07, 0), 8))
		"premier_marais":  # un bassin et son eau
			root.add_child(Props.cyl(0.1, 0.1, 0.05, GOLD, Vector3(0, 0.025, 0), 10))
			root.add_child(Props.cyl(0.07, 0.07, 0.01, Color(0.4, 0.7, 0.9), Vector3(0, 0.055, 0), 10))
		"hamac":  # une lune
			var moon := Props.torus(0.03, 0.08, GOLD, Vector3(0, 0.1, 0), 10)
			moon.rotation.x = PI / 2
			root.add_child(moon)
			root.add_child(Props.ball(0.06, GOLD.darkened(0.25), Vector3(0.03, 0.12, 0), 1))
		"pincon_5":  # un cœur
			for sx in [-1.0, 1.0]:
				root.add_child(Props.ball(0.045, Color(0.95, 0.45, 0.4), Vector3(sx * 0.035, 0.12, 0), 1))
			root.add_child(Props.cyl(0.07, 0.0, 0.09, Color(0.95, 0.45, 0.4), Vector3(0, 0.07, 0), 6))
		"coquillages":
			var sh := Props.shell(0, 0.18)
			root.add_child(sh)
		"collection":  # une vitrine
			root.add_child(Props.box(Vector3(0.14, 0.18, 0.06), GOLD, Vector3(0, 0.09, 0)))
			root.add_child(Props.box(Vector3(0.11, 0.06, 0.02), Color(0.75, 0.93, 1.0), Vector3(0, 0.12, 0.03)))
		"palier_2":  # un moulin
			root.add_child(Props.cyl(0.03, 0.05, 0.18, GOLD, Vector3(0, 0.09, 0), 6))
			for k in 4:
				var b := Props.box(Vector3(0.015, 0.1, 0.01), GOLD, Vector3(0, 0.18, 0.04), Vector3(0, 0, TAU * k / 4.0))
				root.add_child(b)
		"litres_1000":  # une goutte
			root.add_child(Props.ball(0.06, Color(0.4, 0.7, 0.95), Vector3(0, 0.06, 0), 1))
			root.add_child(Props.cyl(0.0, 0.045, 0.08, Color(0.4, 0.7, 0.95), Vector3(0, 0.13, 0), 8))
		"tresors_3":  # un coffre
			root.add_child(Props.box(Vector3(0.14, 0.08, 0.09), GOLD, Vector3(0, 0.04, 0)))
			root.add_child(Props.ball(0.05, GOLD.darkened(0.15), Vector3(0, 0.08, 0), 1, 0.0, Vector3(1.4, 0.55, 0.9)))
		_:
			root.add_child(Props.ball(0.06, GOLD, Vector3(0, 0.06, 0), 1))
	return root


## Une baleine (vers −Z), de `size` m de long : un grand corps sombre, le ventre clair, la queue.
static func whale(size: float, color: Color = WHALE) -> Node3D:
	var root := Node3D.new()
	var body := Props.ball(1.0, color, Vector3.ZERO, 6, 0.04)
	body.scale = Vector3(size * 0.16, size * 0.13, size * 0.5)
	root.add_child(body)
	var belly := Props.ball(1.0, BELLY, Vector3(0, -size * 0.04, -size * 0.12), 6, 0.0)
	belly.scale = Vector3(size * 0.12, size * 0.08, size * 0.3)
	root.add_child(belly)
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0, size * 0.48)
	for sx in [-1.0, 1.0]:
		tail.add_child(Props.box(Vector3(size * 0.16, size * 0.02, size * 0.09), color.darkened(0.1), Vector3(sx * size * 0.08, 0, size * 0.04), Vector3(0, sx * 0.35, 0)))
	root.add_child(tail)
	return root


## Le jet d'eau de la baleine : un panache blanc (nœud mis à l'échelle par la vue).
static func spout() -> Node3D:
	var root := Node3D.new()
	root.name = "Spout"
	root.add_child(Props.cyl(0.25, 0.05, 1.0, SPRAY, Vector3(0, 0.5, 0), 8))
	root.add_child(Props.ball(0.5, SPRAY, Vector3(0, 1.05, 0), 3, 0.15, Vector3(1.2, 0.6, 1.2)))
	# Vu de très loin (600 m et plus) : sans brume ni ombre, sinon le blanc se fond dans le ciel.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = SPRAY
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.disable_fog = true
	for m in root.get_children():
		(m as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		(m as GeometryInstance3D).material_override = mat
	return root


## Un dauphin (vers −Z), de `size` m : corps fuselé, rostre, aileron, queue.
static func dolphin(size: float, color: Color = DOLPHIN) -> Node3D:
	var root := Node3D.new()
	var body := Props.ball(1.0, color, Vector3.ZERO, 4, 0.0)
	body.scale = Vector3(size * 0.13, size * 0.14, size * 0.45)
	root.add_child(body)
	var belly := Props.ball(1.0, BELLY, Vector3(0, -size * 0.04, -size * 0.05), 4, 0.0)
	belly.scale = Vector3(size * 0.1, size * 0.09, size * 0.3)
	root.add_child(belly)
	root.add_child(Props.cyl(size * 0.02, size * 0.05, size * 0.16, color, Vector3(0, -size * 0.02, -size * 0.5), 6))
	root.get_child(-1).rotation.x = -PI / 2
	root.add_child(Props.box(Vector3(size * 0.02, size * 0.14, size * 0.12), color.darkened(0.15), Vector3(0, size * 0.16, size * 0.02), Vector3(-0.5, 0, 0)))
	root.add_child(Props.box(Vector3(size * 0.28, size * 0.02, size * 0.08), color.darkened(0.15), Vector3(0, 0, size * 0.46)))
	return root


## Une gerbe d'éclaboussure (un dauphin retombe) : quelques boules blanches, à l'échelle de la vue.
static func splash() -> Node3D:
	var root := Node3D.new()
	root.name = "Splash"
	for k in 6:
		var a := TAU * k / 6.0
		var b := Props.ball(0.35, SPRAY, Vector3(cos(a) * 0.5, 0.3 + (k % 2) * 0.3, sin(a) * 0.5), k, 0.2)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(b)
	return root
