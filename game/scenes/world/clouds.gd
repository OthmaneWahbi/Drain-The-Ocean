class_name Clouds
extends Node3D
## Des nuages en boules aplaties qui dérivent lentement avec le vent, très haut au-dessus de
## l'île. Un nuage qui sort d'un côté revient de l'autre (AmbientMotion.wrap_around), toujours
## autour de la caméra : il y en a donc partout où l'on va.

const COUNT := 16
const HALF_AREA := 450.0
const WIND := Vector3(2.5, 0.0, 0.8)

var _clouds: Array[Node3D] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 4242
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1)
	mat.roughness = 1.0
	mat.disable_fog = true
	mat.emission_enabled = true
	mat.emission = Color(0.55, 0.58, 0.62)  # reste clair même à contre-jour
	for i in COUNT:
		var cloud := Node3D.new()
		cloud.position = Vector3(_rng.randf_range(-HALF_AREA, HALF_AREA), _rng.randf_range(80.0, 130.0), _rng.randf_range(-HALF_AREA, HALF_AREA))
		var puffs := _rng.randi_range(3, 6)
		for j in puffs:
			var s := SphereMesh.new()
			var r := _rng.randf_range(9.0, 18.0)
			s.radius = r
			s.height = r * 0.9
			s.radial_segments = 12
			s.rings = 6
			s.material = mat
			var puff := MeshInstance3D.new()
			puff.mesh = s
			puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			puff.position = Vector3(j * r * 0.9 - puffs * r * 0.4, _rng.randf_range(-2.0, 3.0), _rng.randf_range(-6.0, 6.0))
			puff.scale = Vector3(1.0, 0.45, 0.8)
			cloud.add_child(puff)
		add_child(cloud)
		_clouds.append(cloud)


func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var center := cam.global_position if cam else Vector3.ZERO
	for c in _clouds:
		c.position += WIND * delta
		c.position.x = AmbientMotion.wrap_around(c.position.x, center.x, HALF_AREA)
		c.position.z = AmbientMotion.wrap_around(c.position.z, center.z, HALF_AREA)
