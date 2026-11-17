class_name ProductModels
extends RefCounted
## Les « photos » des produits du catalogue (0.1.2) : un petit modèle cartoon par article, posé
## sur un plateau tournant dans un studio miniature (ProductPhoto). Depuis 0.1.4, la plupart sont
## les vrais modèles du jeu (Props) : ce qu'on voit au catalogue est ce qui sera livré. Les
## autres (bateau, tongs, brouette, flamant, manuel, tuyaux) sont fabriqués ici.

const WOOD := Color(0.62, 0.42, 0.24)
const WOOD_DARK := Color(0.45, 0.3, 0.17)
const METAL := Color(0.62, 0.66, 0.7)
const BLUE := Color(0.2, 0.5, 0.85)
const PINK := Color(1.0, 0.47, 0.66)
const WATER := Color(0.35, 0.78, 0.9)
const GLASS := Color(0.75, 0.95, 1.0, 0.4)


static func build(id: String) -> Node3D:
	var n := Node3D.new()
	match id:
		"bache":
			n.add_child(Props.drying_zone("bache"))
			n.scale = Vector3.ONE * 0.55
		"grand_seau":
			var b := Props.bucket(true, 0.75)
			Props.set_bucket_fill(b, 0.85)
			n.add_child(b)
		"bateau":
			var bottle := _cyl(0.24, 0.24, 1.0, GLASS, Vector3(0, 0.26, 0))
			bottle.rotation.z = PI / 2
			n.add_child(bottle)
			var neck := _cyl(0.1, 0.1, 0.25, GLASS, Vector3(0.62, 0.26, 0))
			neck.rotation.z = PI / 2
			n.add_child(neck)
			var cork := _cyl(0.09, 0.09, 0.12, WOOD, Vector3(0.78, 0.26, 0))
			cork.rotation.z = PI / 2
			n.add_child(cork)
			n.add_child(_box(Vector3(0.45, 0.08, 0.14), UiTheme.RED, Vector3(-0.05, 0.14, 0)))
			n.add_child(_box(Vector3(0.02, 0.28, 0.02), WOOD_DARK, Vector3(-0.05, 0.3, 0)))
			n.add_child(_box(Vector3(0.18, 0.18, 0.01), Color.WHITE, Vector3(0.02, 0.33, 0)))
		"tongs":
			for i in 2:
				var sole := _cyl(0.2, 0.2, 0.05, [PINK, UiTheme.TEAL][i], Vector3(i * 0.5 - 0.25, 0.03, 0))
				sole.scale = Vector3(1.0, 1.0, 2.1)
				sole.rotation.y = 0.25 - i * 0.5
				n.add_child(sole)
				n.add_child(_box(Vector3(0.3, 0.06, 0.05), UiTheme.YELLOW, Vector3(i * 0.5 - 0.25, 0.1, -0.05)))
		"brouette":
			n.add_child(_box(Vector3(0.8, 0.32, 0.6), UiTheme.TEAL, Vector3(0, 0.45, 0)))
			n.add_child(_box(Vector3(0.7, 0.04, 0.5), Color(0.97, 0.97, 0.93), Vector3(0, 0.62, 0)))
			var wheel := _cyl(0.2, 0.2, 0.1, Color(0.18, 0.18, 0.2), Vector3(0.5, 0.2, 0))
			wheel.rotation.x = PI / 2
			n.add_child(wheel)
			for sz in [-1, 1]:
				n.add_child(_box(Vector3(0.9, 0.05, 0.05), WOOD, Vector3(-0.45, 0.42, sz * 0.25)))
				n.add_child(_box(Vector3(0.05, 0.3, 0.05), WOOD, Vector3(-0.2, 0.15, sz * 0.22)))
		"rateau":
			var r := Props.rake()
			r.rotation = Vector3(-0.3, PI / 2, 0)
			r.position = Vector3(0, 0.35, 0)
			r.scale = Vector3.ONE * 1.2
			n.add_child(r)
		"palanche":
			n.add_child(Props.yoke())
		"condenseur":
			n.add_child(Props.condenser())
			n.scale = Vector3.ONE * 0.6
		"rations":
			n.add_child(Props.rations())
			n.scale = Vector3.ONE * 1.3
		"manuel":
			var book := Node3D.new()
			book.rotation = Vector3(-0.5, 0.3, 0)
			book.position = Vector3(0, 0.45, 0)
			n.add_child(book)
			book.add_child(_box(Vector3(0.8, 1.0, 0.16), UiTheme.RED))
			book.add_child(_box(Vector3(0.74, 0.96, 0.17), Color(0.97, 0.95, 0.88), Vector3(0.04, 0, 0)))
			book.add_child(_box(Vector3(0.8, 1.0, 0.03), UiTheme.RED, Vector3(0, 0, 0.09)))
			book.add_child(_box(Vector3(0.5, 0.12, 0.01), UiTheme.YELLOW, Vector3(0, 0.25, 0.11)))
			book.add_child(_box(Vector3(0.2, 0.2, 0.01), METAL, Vector3(0, -0.1, 0.11)))
		"bassin_bois":
			n.add_child(Props.drying_zone("bassin_bois"))
			n.scale = Vector3.ONE * 0.32
		"miroir":
			n.add_child(Props.mirror())
			n.scale = Vector3.ONE * 0.75
		"pompe_bras":
			n.add_child(Props.hand_pump())
			n.scale = Vector3.ONE * 0.8
		"tuyau":
			for k in 5:
				var pipe := _cyl(0.09, 0.09, 1.0, [UiTheme.TEAL, METAL][k % 2], Vector3(0, 0.09 + (k / 3) * 0.17, -0.2 + (k % 3) * 0.2 + (k / 3) * 0.1))
				pipe.rotation.z = PI / 2
				n.add_child(pipe)
		"toboggan":
			var sl := Props.slide()
			sl.rotation.y = PI / 2
			n.add_child(sl)
			n.scale = Vector3.ONE * 0.4
		"flamant":
			var ring := MeshInstance3D.new()
			var t := TorusMesh.new()
			t.inner_radius = 0.22
			t.outer_radius = 0.48
			t.rings = 14
			t.ring_segments = 8
			ring.mesh = t
			ring.material_override = _mat(PINK)
			ring.position = Vector3(0, 0.13, 0)
			n.add_child(ring)
			var neck := _cyl(0.07, 0.09, 0.7, PINK, Vector3(0.36, 0.5, 0))
			neck.rotation.z = 0.2
			n.add_child(neck)
			n.add_child(_box(Vector3(0.26, 0.14, 0.14), PINK, Vector3(0.38, 0.86, 0)))
			n.add_child(_box(Vector3(0.12, 0.06, 0.07), Color(0.15, 0.15, 0.15), Vector3(0.55, 0.83, 0)))
			n.add_child(_box(Vector3(0.03, 0.04, 0.15), Color(0.1, 0.1, 0.1), Vector3(0.44, 0.9, 0)))
		"moulin_pompe":
			n.add_child(Props.windmill())
			n.scale = Vector3.ONE * 0.3
		_:
			# Un article inconnu : une caisse de l'Agence, avec un point d'interrogation.
			n.add_child(_box(Vector3(0.7, 0.6, 0.7), WOOD, Vector3(0, 0.3, 0)))
			n.add_child(_box(Vector3(0.72, 0.1, 0.72), UiTheme.RED, Vector3(0, 0.45, 0)))
			n.set_meta("unknown", true)
	return n


static func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.1
		m.metallic_specular = 0.8
	return m


static func _box(size: Vector3, color: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = _mat(color)
	mi.position = pos
	return mi


static func _cyl(top: float, bottom: float, height: float, color: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = height
	c.radial_segments = 10
	c.rings = 1
	mi.mesh = c
	mi.material_override = _mat(color)
	mi.position = pos
	return mi
