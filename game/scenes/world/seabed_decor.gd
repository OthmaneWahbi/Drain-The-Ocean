class_name SeabedDecor
extends Node3D
## Le fond marin, seulement autour de l'île (PRD §19.1) : des rochers et des algues posés au
## hasard (graine fixe, donc toujours au même endroit) sur le sable du fond, à y = -3.
## On le découvre en plongeant, puis à l'air libre quand l'océan baisse.

const SEABED_Y := -3.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.42, 0.43, 0.45)
	rock_mat.roughness = 1.0
	var weed_mat := StandardMaterial3D.new()
	weed_mat.albedo_color = Color(0.15, 0.45, 0.22)
	var coral_mat := StandardMaterial3D.new()
	coral_mat.albedo_color = Color(0.9, 0.45, 0.45)
	for i in 70:
		var p := AmbientMotion.ring_point(rng, 28.0, 110.0, SEABED_Y)
		var m := MeshInstance3D.new()
		var kind := rng.randi_range(0, 2)
		if kind == 0:
			var s := SphereMesh.new()
			var r := rng.randf_range(0.4, 1.6)
			s.radius = r
			s.height = r * 1.2
			s.radial_segments = 8
			s.rings = 4
			s.material = rock_mat
			m.mesh = s
			m.scale = Vector3(1.0, rng.randf_range(0.4, 0.8), rng.randf_range(0.7, 1.2))
		elif kind == 1:
			var b := BoxMesh.new()
			var h := rng.randf_range(0.6, 1.8)
			b.size = Vector3(0.08, h, 0.25)
			b.material = weed_mat
			m.mesh = b
			p.y += h / 2.0
			m.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0, TAU), rng.randf_range(-0.2, 0.2))
		else:
			var c := CylinderMesh.new()
			c.top_radius = rng.randf_range(0.2, 0.4)
			c.bottom_radius = 0.05
			c.height = rng.randf_range(0.3, 0.7)
			c.radial_segments = 6
			c.material = coral_mat
			m.mesh = c
			p.y += c.height / 2.0
		m.position = p
		add_child(m)
