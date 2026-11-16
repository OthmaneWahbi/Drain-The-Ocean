extends Node3D
## Chef d'orchestre de la scène : crée une vue 3D pour chaque élément de GameState
## (zones, caisses, décors), anime le soleil, place la surface de l'océan à sa vraie hauteur,
## et gère les touches de debug.

const DryingZoneView := preload("res://scenes/world/drying_zone_view.gd")
const CrateView := preload("res://scenes/world/crate_view.gd")
const DecorView := preload("res://scenes/world/decor_view.gd")
const DeliveryPlane := preload("res://scenes/world/delivery_plane.gd")

## Durée de la chute en parachute (le reste du délai de livraison est le vol de l'avion).
const CHUTE_TIME_S := 1.5

@onready var sun: DirectionalLight3D = $Sun
@onready var depot: Node3D = $Depot
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var ocean_mesh: Node3D = $Ocean

var _views: Node3D
var _crate_views: Dictionary = {}  # id de caisse -> vue


func _ready() -> void:
	_views = Node3D.new()
	_views.name = "Views"
	add_child(_views)
	GameState.game_reset.connect(_clear_views)
	GameState.zone_added.connect(_on_zone_added)
	GameState.crate_added.connect(_on_crate_added)
	GameState.crate_removed.connect(_on_crate_removed)
	GameState.decor_added.connect(_on_decor_added)
	# Le repère de niveau d'eau, sur la plage, tourné vers le centre de l'île (M-62, N-10).
	var gauge := WaterGauge.new()
	gauge.position = Vector3(3, 0.5, 17)
	gauge.rotation_degrees.y = 180.0
	add_child(gauge)
	# La partie en mémoire a été créée avant la scène : on rejoue son contenu.
	GameState.continue_or_new()


func _process(_delta: float) -> void:
	_update_sun()
	# Le plan d'eau suit la hauteur honnête calculée depuis le volume retiré (M1).
	ocean_mesh.position.y = GameState.water_level_y()


func _update_sun() -> void:
	var elevation := GameState.day.sun_elevation_deg()
	sun.rotation_degrees = Vector3(-maxf(elevation, 8.0), 35.0, 0.0)
	var daylight := clampf(elevation / 15.0, 0.0, 1.0)
	sun.light_energy = lerpf(0.08, 0.9, daylight)
	world_env.environment.ambient_light_energy = lerpf(0.12, 0.45, daylight)
	world_env.environment.background_energy_multiplier = lerpf(0.15, 1.0, daylight)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_F5:
			GameState.save_game()  # sauvegarde manuelle (M-78)
		KEY_F9:
			GameState.new_game()  # debug : nouvelle partie
		KEY_F10:
			Economy.add(GameState.stock, {"sel": 50, "mineraux": 5})  # debug : triche
			GameState.stock_changed.emit()


func _physics_process(delta: float) -> void:
	# Debug : maintenir F8 accélère le temps ×10 (pour tester le séchage).
	Engine.time_scale = 10.0 if Input.is_physical_key_pressed(KEY_F8) else 1.0
	# Debug : maintenir F7 vide l'océan à grande vitesse, pour voir l'eau baisser (M1).
	if Input.is_physical_key_pressed(KEY_F7):
		var ocean := GameState.ocean
		ocean.remove_water(ocean.total_volume_l * GameState.config.debug_drain_ratio_per_s * delta)
		GameState.ocean_changed.emit()


func _clear_views() -> void:
	for child in _views.get_children():
		child.queue_free()
	_crate_views.clear()


func _on_zone_added(zone: Dictionary) -> void:
	var view := DryingZoneView.new()
	_views.add_child(view)
	view.setup(zone)


func _on_decor_added(decor: Dictionary) -> void:
	var view := DecorView.new()
	_views.add_child(view)
	view.setup(decor)


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
