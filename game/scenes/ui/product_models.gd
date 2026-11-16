class_name ProductModels
extends RefCounted
## Les « photos » des produits du catalogue (0.1.2) : un petit modèle cartoon par article, posé
## sur un plateau tournant dans un studio miniature (ProductPhoto). Fabriqués ici avec des formes
## simples, dans les couleurs de UiTheme ; quand les vrais modèles des objets arriveront, il
## suffira de les renvoyer ici.

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
			n.add_child(_box(Vector3(1.4, 0.04, 1.0), BLUE, Vector3(0, 0.12, 0)))
			n.add_child(_box(Vector3(0.9, 0.05, 0.55), Color(0.97, 0.97, 0.93), Vector3(0.1, 0.15, 0.05)))
			for sx in [-1, 1]:
				for sz in [-1, 1]:
					n.add_child(_box(Vector3(0.06, 0.24, 0.06), WOOD, Vector3(sx * 0.68, 0.1, sz * 0.48)))
		"grand_seau":
			n.add_child(_cyl(0.42, 0.32, 0.7, UiTheme.YELLOW, Vector3(0, 0.35, 0)))
			n.add_child(_cyl(0.36, 0.36, 0.02, WATER, Vector3(0, 0.66, 0)))
			var handle := MeshInstance3D.new()
			var torus := TorusMesh.new()
			torus.inner_radius = 0.38
			torus.outer_radius = 0.43
			torus.rings = 12
			torus.ring_segments = 6
			handle.mesh = torus
			handle.material_override = _mat(METAL)
			handle.rotation.x = PI / 2
			handle.position = Vector3(0, 0.7, 0)
			n.add_child(handle)
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
			var stick := _box(Vector3(1.5, 0.05, 0.05), WOOD, Vector3(0, 0.3, 0))
			stick.rotation.z = 0.25
			n.add_child(stick)
			n.add_child(_box(Vector3(0.06, 0.06, 0.6), METAL, Vector3(0.72, 0.48, 0)))
			for k in 6:
				n.add_child(_box(Vector3(0.03, 0.16, 0.03), METAL, Vector3(0.72, 0.4, -0.25 + k * 0.1)))
		"palanche":
			n.add_child(_box(Vector3(1.5, 0.07, 0.07), WOOD, Vector3(0, 0.95, 0)))
			for sx in [-1, 1]:
				n.add_child(_box(Vector3(0.02, 0.4, 0.02), Color(0.3, 0.25, 0.2), Vector3(sx * 0.65, 0.73, 0)))
				n.add_child(_cyl(0.2, 0.15, 0.36, UiTheme.YELLOW, Vector3(sx * 0.65, 0.35, 0)))
		"condenseur":
			var tent := MeshInstance3D.new()
			var cone := CylinderMesh.new()
			cone.top_radius = 0.02
			cone.bottom_radius = 0.6
			cone.height = 0.6
			cone.radial_segments = 4
			tent.mesh = cone
			tent.material_override = _mat(GLASS)
			tent.position = Vector3(0, 0.3, 0)
			n.add_child(tent)
			n.add_child(_cyl(0.13, 0.11, 0.2, UiTheme.RED, Vector3(0, 0.1, 0)))
			n.add_child(_box(Vector3(0.06, 0.06, 0.06), BLUE, Vector3(0, 0.66, 0)))
		"rations":
			for i in 3:
				var c: Color = [UiTheme.RED, UiTheme.TEAL, UiTheme.YELLOW][i]
				var pos: Vector3 = [Vector3(-0.22, 0.2, 0), Vector3(0.22, 0.2, 0), Vector3(0, 0.6, 0)][i]
				n.add_child(_cyl(0.2, 0.2, 0.4, METAL, pos))
				n.add_child(_cyl(0.205, 0.205, 0.22, c, pos))
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
			n.add_child(_box(Vector3(1.3, 0.3, 0.9), WOOD, Vector3(0, 0.15, 0)))
			n.add_child(_box(Vector3(1.18, 0.02, 0.78), WATER, Vector3(0, 0.28, 0)))
			for k in 3:
				n.add_child(_box(Vector3(1.32, 0.03, 0.92), WOOD_DARK, Vector3(0, 0.05 + k * 0.1, 0)))
		"miroir":
			n.add_child(_box(Vector3(0.06, 0.6, 0.06), WOOD_DARK, Vector3(0, 0.3, 0)))
			var frame := _box(Vector3(1.0, 0.7, 0.06), UiTheme.YELLOW, Vector3(0, 0.75, 0))
			frame.rotation.x = -0.4
			n.add_child(frame)
			var glass := _box(Vector3(0.9, 0.6, 0.02), Color(0.85, 0.95, 1.0), Vector3(0, 0.0, 0.035))
			var m := _mat(Color(0.85, 0.95, 1.0))
			m.metallic = 0.9
			m.roughness = 0.05
			glass.material_override = m
			frame.add_child(glass)
		"pompe_bras":
			n.add_child(_cyl(0.18, 0.2, 0.8, UiTheme.TEAL, Vector3(0, 0.4, 0)))
			n.add_child(_cyl(0.06, 0.06, 0.35, METAL, Vector3(0.25, 0.65, 0)))
			n.get_child(-1).rotation.z = PI / 2
			var lever := _box(Vector3(0.7, 0.05, 0.05), UiTheme.RED, Vector3(-0.25, 0.92, 0))
			lever.rotation.z = -0.35
			n.add_child(lever)
			n.add_child(_box(Vector3(0.5, 0.06, 0.5), WOOD_DARK, Vector3(0, 0.03, 0)))
		"tuyau":
			for k in 5:
				var pipe := _cyl(0.09, 0.09, 1.0, [UiTheme.TEAL, METAL][k % 2], Vector3(0, 0.09 + (k / 3) * 0.17, -0.2 + (k % 3) * 0.2 + (k / 3) * 0.1))
				pipe.rotation.z = PI / 2
				n.add_child(pipe)
		"toboggan":
			var ramp := _box(Vector3(1.4, 0.05, 0.4), UiTheme.YELLOW, Vector3(0, 0.45, 0))
			ramp.rotation.z = -0.5
			n.add_child(ramp)
			for sz in [-1, 1]:
				var rail := _box(Vector3(1.4, 0.12, 0.04), UiTheme.RED, Vector3(0, 0.5, sz * 0.2))
				rail.rotation.z = -0.5
				n.add_child(rail)
			n.add_child(_box(Vector3(0.06, 0.8, 0.06), WOOD, Vector3(-0.55, 0.4, 0)))
			n.add_child(_box(Vector3(0.3, 0.25, 0.25), Color(0.85, 0.75, 0.55), Vector3(0.62, 0.12, 0)))
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
			var tower := MeshInstance3D.new()
			var c := CylinderMesh.new()
			c.top_radius = 0.08
			c.bottom_radius = 0.3
			c.height = 1.3
			c.radial_segments = 4
			tower.mesh = c
			tower.material_override = _mat(WOOD)
			tower.position = Vector3(0, 0.65, 0)
			n.add_child(tower)
			var hub := Node3D.new()
			hub.position = Vector3(0, 1.3, 0.12)
			hub.rotation.z = 0.3
			n.add_child(hub)
			for k in 4:
				var blade := _box(Vector3(0.12, 0.55, 0.02), [UiTheme.RED, Color(0.97, 0.95, 0.88)][k % 2], Vector3(0, 0.3, 0))
				var arm := Node3D.new()
				arm.rotation.z = k * PI / 2
				arm.add_child(blade)
				hub.add_child(arm)
			n.add_child(_box(Vector3(0.3, 0.15, 0.03), UiTheme.RED, Vector3(0, 1.3, -0.25)))
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
