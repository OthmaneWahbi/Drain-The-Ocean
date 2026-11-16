extends Node3D
## Chef d'orchestre de la scène : crée une vue 3D pour chaque élément de GameState
## (zones, caisses, décors), anime le soleil, place la surface de l'océan à sa vraie hauteur,
## et gère la sauvegarde manuelle (F5).

const DryingZoneView := preload("res://scenes/world/drying_zone_view.gd")
const CrateView := preload("res://scenes/world/crate_view.gd")
const DecorView := preload("res://scenes/world/decor_view.gd")
const DeliveryPlane := preload("res://scenes/world/delivery_plane.gd")
const PickupView := preload("res://scenes/world/pickup_view.gd")
const StationView := preload("res://scenes/world/station_view.gd")
const MirrorView := preload("res://scenes/world/mirror_view.gd")

## Durée de la chute en parachute (le reste du délai de livraison est le vol de l'avion).
const CHUTE_TIME_S := 1.5

@onready var sun: DirectionalLight3D = $Sun
@onready var depot: Node3D = $Depot
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var ocean_mesh: Node3D = $Ocean

var _views: Node3D
## La lune : une lumière bleutée très faible et un disque blanc dessiné loin dans le ciel,
## à l'opposé du soleil. Le soleil est éteint la nuit (sinon le ciel dessine un « soleil noir »).
var _moon: DirectionalLight3D
var _moon_disk: MeshInstance3D
var _crate_views: Dictionary = {}  # id de caisse -> vue
var _id_views: Dictionary = {}  # id de ramassable / d'objet à portions -> vue


func _ready() -> void:
	_views = Node3D.new()
	_views.name = "Views"
	add_child(_views)
	_build_moon()
	GameState.game_reset.connect(_clear_views)
	GameState.zone_added.connect(_on_zone_added)
	GameState.crate_added.connect(_on_crate_added)
	GameState.crate_removed.connect(_on_crate_removed)
	GameState.decor_added.connect(_on_decor_added)
	GameState.pickup_added.connect(_spawn_view.bind(PickupView))
	GameState.station_added.connect(_spawn_view.bind(StationView))
	GameState.mirror_added.connect(_spawn_view.bind(MirrorView))
	GameState.pickup_removed.connect(_remove_view)
	GameState.station_removed.connect(_remove_view)
	GameState.item_moved.connect(_on_item_moved)
	# Le mode déplacement des objets (G, M-22).
	var placement := PlacementController.new()
	placement.name = "Placement"
	add_child(placement)
	# Le repère de niveau d'eau, sur la plage, tourné vers le centre de l'île (M-62, N-10).
	var gauge := WaterGauge.new()
	gauge.position = Vector3(3, 0.5, 17)
	gauge.rotation_degrees.y = 180.0
	add_child(gauge)
	# La partie en mémoire a été créée avant la scène : on rejoue son contenu.
	GameState.continue_or_new()


func _process(_delta: float) -> void:
	_update_sun()
	# Le plan d'eau suit la hauteur honnête calculée depuis le volume retiré (M1),
	# et suit le joueur à l'horizontale pour qu'on n'en voie jamais le bord.
	ocean_mesh.position.y = GameState.water_level_y()
	var cam := get_viewport().get_camera_3d()
	if cam:
		ocean_mesh.position.x = snappedf(cam.global_position.x, 100.0)
		ocean_mesh.position.z = snappedf(cam.global_position.z, 100.0)


func _build_moon() -> void:
	_moon = DirectionalLight3D.new()
	_moon.light_color = Color(0.6, 0.7, 1.0)
	_moon.light_energy = 0.12
	_moon.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY  # le disque est dessiné à part
	add_child(_moon)
	_moon_disk = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 60.0
	sphere.height = 120.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.92, 0.93, 0.98)
	mat.disable_fog = true
	sphere.material = mat
	_moon_disk.mesh = sphere
	_moon_disk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_moon_disk)


func _update_sun() -> void:
	var elevation := GameState.day.sun_elevation_deg()
	sun.rotation_degrees = Vector3(-elevation, 35.0, 0.0)
	sun.visible = elevation > -2.0
	var daylight := clampf(elevation / 15.0, 0.0, 1.0)
	sun.light_energy = lerpf(0.0, 0.9, daylight)
	# La lune suit le chemin inverse du soleil.
	var moon_elevation := -elevation
	_moon.rotation_degrees = Vector3(-moon_elevation, 215.0, 0.0)
	_moon.visible = moon_elevation > 0.0
	_moon_disk.visible = _moon.visible
	var cam := get_viewport().get_camera_3d()
	if cam:
		# La lumière part vers -Z : l'astre est donc du côté +Z de son repère.
		_moon_disk.global_position = cam.global_position + _moon.global_transform.basis.z * 4000.0
	world_env.environment.ambient_light_energy = lerpf(0.12, 0.45, daylight)
	world_env.environment.background_energy_multiplier = lerpf(0.15, 1.0, daylight)


func _unhandled_input(event: InputEvent) -> void:
	# F5 : sauvegarde manuelle (M-78). Les touches de triche sont dans game/admin/.
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F5:
		GameState.save_game()


func _clear_views() -> void:
	for child in _views.get_children():
		child.queue_free()
	_crate_views.clear()
	_id_views.clear()


## Crée la vue d'un élément de GameState (ramassable, objet à portions) et la retient par son id.
func _spawn_view(item: Dictionary, script: GDScript) -> void:
	var view: Node3D = script.new()
	_views.add_child(view)
	view.setup(item)
	_id_views[item.id] = view


func _remove_view(item: Dictionary) -> void:
	var view: Node = _id_views.get(item.id)
	if view and is_instance_valid(view):
		view.queue_free()
	_id_views.erase(item.id)


func _on_zone_added(zone: Dictionary) -> void:
	_spawn_view(zone, DryingZoneView)


func _on_decor_added(decor: Dictionary) -> void:
	_spawn_view(decor, DecorView)


## Un objet a changé de place : sa vue le suit.
func _on_item_moved(item: Dictionary) -> void:
	var view: Node3D = _id_views.get(item.id)
	if view and is_instance_valid(view):
		view.position = item.position


func _on_crate_added(crate: Dictionary, animate: bool) -> void:
	var view := CrateView.new()
	_views.add_child(view)
	view.setup(crate)
	_crate_views[crate.id] = view
	if not animate:
		view.land_now()
		return
	view.visible = false
	var plane := DeliveryPlane.new()
	_views.add_child(plane)
	var drop_at := maxf(GameState.config.delivery_time_s - CHUTE_TIME_S, 0.5)
	plane.dropped.connect(func():
		if is_instance_valid(view):
			view.visible = true
			view.drop_from(16.0, CHUTE_TIME_S))
	plane.fly(depot.global_position, crate.position, drop_at)


func _on_crate_removed(crate: Dictionary) -> void:
	var view: Node = _crate_views.get(crate.id)
	if view and is_instance_valid(view):
		view.queue_free()
	_crate_views.erase(crate.id)
