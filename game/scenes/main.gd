extends Node3D
## Chef d'orchestre de la scène : crée une vue 3D pour chaque élément de GameState
## (zones, caisses, décors), anime le soleil, crée l'océan et la vie autour de l'île,
## et gère la sauvegarde manuelle (F5).

const DryingZoneView := preload("res://scenes/world/drying_zone_view.gd")
const CrateView := preload("res://scenes/world/crate_view.gd")
const DecorView := preload("res://scenes/world/decor_view.gd")
const DeliveryPlane := preload("res://scenes/world/delivery_plane.gd")
const PickupView := preload("res://scenes/world/pickup_view.gd")
const StationView := preload("res://scenes/world/station_view.gd")
const MirrorView := preload("res://scenes/world/mirror_view.gd")
const PumpView := preload("res://scenes/world/pump_view.gd")
const PipesView := preload("res://scenes/world/pipes_view.gd")
const SlideView := preload("res://scenes/world/slide_view.gd")
const MilestonePanel := preload("res://scenes/ui/milestone_panel.gd")
const DemoEnd := preload("res://scenes/ui/demo_end.gd")
const ToolbarMenu := preload("res://scenes/ui/toolbar_menu.gd")
const DepotScript := preload("res://scenes/world/depot.gd")

## Durée de la chute en parachute (le reste du délai de livraison est le vol de l'avion).
const CHUTE_TIME_S := 1.5

@onready var sun: DirectionalLight3D = $Sun
@onready var depot: Node3D = $Depot
@onready var world_env: WorldEnvironment = $WorldEnvironment

var _views: Node3D
## La lune : une lumière bleutée très faible et un disque blanc dessiné loin dans le ciel,
## à l'opposé du soleil. Le soleil est éteint la nuit (sinon le ciel dessine un « soleil noir »).
var _moon: DirectionalLight3D
var _moon_disk: MeshInstance3D
var _crate_views: Dictionary = {}  # id de caisse -> vue
var _id_views: Dictionary = {}  # id de ramassable / d'objet à portions -> vue


func _ready() -> void:
	Settings.apply()  # langue, volume, plein écran choisis dans les options
	_views = Node3D.new()
	_views.name = "Views"
	add_child(_views)
	_build_moon()
	# Le ciel cartoon (dégradé, soleil rond, étoiles) : il suit la lumière du soleil tout seul.
	SkyStyle.install(world_env.environment)
	# Le terrain low poly de l'île (0.1.1) : plateau, plages, dunes en terrasses, fond marin.
	var terrain := TerrainView.new()
	terrain.name = "Terrain"
	add_child(terrain)
	# Palmiers, noix de coco, rochers, buissons des dunes (0.1.2, modèles CC0 retouchés).
	var props := IslandProps.new()
	props.name = "Props"
	add_child(props)
	# Le monde vivant : océan à vagues, filtre sous l'eau, fond marin, nuages, animaux.
	# Chaque morceau est indépendant ; on peut en retirer un sans toucher aux autres.
	var ocean := OceanView.new()
	ocean.name = "Ocean"
	add_child(ocean)
	var underwater := UnderwaterOverlay.new()
	underwater.name = "Underwater"
	underwater.environment = world_env.environment
	add_child(underwater)
	for extra: Node3D in [SeabedDecor.new(), Clouds.new(), Fauna.new()]:
		add_child(extra)
	GameState.game_reset.connect(_clear_views)
	GameState.zone_added.connect(_on_zone_added)
	GameState.crate_added.connect(_on_crate_added)
	GameState.crate_removed.connect(_on_crate_removed)
	GameState.decor_added.connect(_on_decor_added)
	GameState.pickup_added.connect(_spawn_view.bind(PickupView))
	GameState.station_added.connect(_spawn_view.bind(StationView))
	GameState.mirror_added.connect(_spawn_view.bind(MirrorView))
	GameState.pump_added.connect(_spawn_view.bind(PumpView))
	GameState.slide_added.connect(_spawn_view.bind(SlideView))
	GameState.pickup_removed.connect(_remove_view)
	GameState.station_removed.connect(_remove_view)
	GameState.item_moved.connect(_on_item_moved)
	# Les tuyaux entre pompes et zones (T2).
	var pipes := PipesView.new()
	pipes.name = "Pipes"
	add_child(pipes)
	# Poser les tuyaux à la main (case « tuyaux » de la barre).
	var builder := PipeBuilder.new()
	builder.name = "PipeBuilder"
	add_child(builder)
	# La fin de la démo (M-05), déclenchée par le moulin-pompe.
	var milestones := MilestonePanel.new()
	milestones.name = "Milestones"
	add_child(milestones)
	var toolbar_menu := ToolbarMenu.new()
	toolbar_menu.name = "ToolbarMenu"
	add_child(toolbar_menu)
	var demo_end := DemoEnd.new()
	demo_end.name = "DemoEnd"
	add_child(demo_end)
	# Le mode déplacement des objets (G, M-22).
	var placement := PlacementController.new()
	placement.name = "Placement"
	placement.view_for = func(it: Dictionary) -> Node3D: return depot if it.id == "depot" else _id_views.get(it.id)
	add_child(placement)
	# Le repère de niveau d'eau, sur la plage, tourné vers le centre de l'île (M-62, N-10).
	var gauge := WaterGauge.new()
	gauge.position = Vector3(3, 0.5, 17)
	gauge.rotation_degrees.y = 180.0
	add_child(gauge)
	# Le menu pause (Échap) et le menu principal (3 emplacements, M-71).
	var pause_menu := PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)
	# Les sous-titres et les réponses au téléphone de la cabine (0.1.2).
	var dialogue := DialogueBox.new()
	dialogue.name = "Dialogue"
	add_child(dialogue)
	var main_menu := MainMenu.new()
	main_menu.name = "MainMenu"
	add_child(main_menu)
	pause_menu.main_menu_requested.connect(main_menu.open_menu)
	# La vraie fin (touche de debug F4), puis retour au menu principal (Q-24).
	var ending := EndingDirector.new()
	ending.name = "Ending"
	add_child(ending)
	GameState.run_finished.connect(main_menu.open_menu)
	# Les sons, fabriqués par calcul (SoundSynth), qui écoutent GameState.
	var sounds := SoundBoard.new()
	sounds.name = "Sounds"
	add_child(sounds)
	# Les traits des réveils, sur le palmier le plus proche de la plage (M-84).
	# Le palmier est penché : on suit son tronc à 1,2 m du sol, côté centre de l'île.
	var marks := PalmMarks.new()
	marks.name = "PalmMarks"
	add_child(marks)
	var palm_body := props.palm_near(Vector3(-13, 0, -3))
	var palm_model: Node3D = palm_body.get_meta("model")
	var trunk := Models.trunk_at(palm_model, 1.2)
	var palm := palm_model.global_transform * (trunk[0] as Vector3)
	var to_center := Vector3(-palm.x, 0, -palm.z).normalized()
	marks.look_at_from_position(palm + to_center * (float(trunk[1]) * palm_model.global_transform.basis.get_scale().x + 0.01), palm - to_center)
	# La partie en mémoire a été créée avant la scène : on rejoue son contenu.
	# DTO_SKIP_MENU=1 (captures d'écran, essais) saute le menu et reprend l'emplacement 1.
	if OS.get_environment("DTO_SKIP_MENU") != "":
		GameState.continue_or_new()
	else:
		GameState.new_game()  # une île neuve, figée derrière le menu
		main_menu.open_menu()


func _process(_delta: float) -> void:
	_update_sun()


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
	sun.light_energy = lerpf(0.0, 1.0, daylight)
	sun.light_color = SkyStyle.sun_color(elevation)
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
	view.rotation_degrees.y = GameState.item_rotation(item)
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
	# La palette est dans la scène (main.tscn), les autres vues sont retenues par id.
	var view: Node3D = depot if item.id == "depot" else _id_views.get(item.id)
	if view and is_instance_valid(view):
		view.position = item.position
		view.rotation_degrees.y = GameState.item_rotation(item)


func _on_crate_added(crate: Dictionary, animate: bool) -> void:
	var view := CrateView.new()
	_views.add_child(view)
	view.setup(crate)
	_crate_views[crate.id] = view
	if not animate:
		view.land_now()
		return
	view.visible = false
	# Plusieurs caisses dans une commande : les avions passent l'un après l'autre.
	var delay := float(crate.get("delay_s", 0.0))
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
		if not is_instance_valid(view):
			return
	var plane := DeliveryPlane.new()
	_views.add_child(plane)
	var drop_at := maxf(GameState.config.delivery_time_s - CHUTE_TIME_S, 0.5)
	# Le crochet arrache le paiement sur la palette (sauf pour la caisse offerte du premier appel).
	if not crate.get("free", false):
		var paid: Dictionary = crate.get("paid", {})
		plane.hooked.connect(func(): plane.carry_bundle(_bundle_colors(paid)))
	plane.dropped.connect(func():
		if is_instance_valid(view):
			view.visible = true
			view.drop_from(16.0, CHUTE_TIME_S))
	plane.fly(depot.global_position, crate.position, drop_at)


## Une boîte par ressource payée, aux couleurs de la palette (au moins une).
func _bundle_colors(paid: Dictionary) -> Array:
	var out := []
	for r in Economy.RESOURCES:
		if int(paid.get(r, 0)) > 0:
			out.append(DepotScript.COLORS[r])
	return out if not out.is_empty() else [Greybox.WOOD]


func _on_crate_removed(crate: Dictionary) -> void:
	var view: Node = _crate_views.get(crate.id)
	if view and is_instance_valid(view):
		view.queue_free()
	_crate_views.erase(crate.id)
