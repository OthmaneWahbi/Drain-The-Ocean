class_name ReefView
extends Node3D
## Le petit récif autour de l'île (0.1.21, PRD §19.28) : des coraux et des gorgones entre 2 et 5 m
## de fond, quatre espèces de poissons colorés qui tournent autour, et les coquillages du matin
## posés au fond (E en plongée pour les ramasser). Un poisson vu de près avec le masque entre
## dans la collection (GameState.see_fish).

const CORALS := 18
const SPECIES: Array[String] = ["poisson_clown", "chirurgien_bleu", "poisson_perroquet", "raie"]
const CORAL_COLORS: Array[Color] = [Color(1.0, 0.45, 0.5), Color(0.95, 0.65, 0.25), Color(0.6, 0.35, 0.85), Color(0.3, 0.8, 0.7), Color(1.0, 0.85, 0.35)]

var _fish: Array[Node3D] = []
var _fish_species: Array[String] = []
var _fish_center: Array[Vector3] = []
var _fish_phase: Array[float] = []
var _shells: Node3D
var _t := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2121
	var spots: Array[Vector3] = []
	for i in CORALS:
		var p: Vector3 = GameState.random_reef_spot(rng)
		if p == GameState.FAR_AWAY:
			continue
		spots.append(p)
		add_child(_coral(rng, p))
	for i in spots.size():
		var species := SPECIES[i % SPECIES.size()]
		for k in (1 if species == "raie" else 3):
			var f := Finds.fish(species)
			f.scale = Vector3.ONE * 1.4
			add_child(f)
			_fish.append(f)
			_fish_species.append(species)
			_fish_center.append(spots[i] + Vector3(0, 0.8 + k * 0.25, 0))
			_fish_phase.append(rng.randf_range(0.0, TAU))
	_shells = Node3D.new()
	add_child(_shells)
	GameState.reef_changed.connect(_refresh_shells)
	_refresh_shells()


## Un massif de corail : quelques branches (cylindres penchés), des boules, une gorgone en éventail.
func _coral(rng: RandomNumberGenerator, at: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = at
	for k in rng.randi_range(3, 6):
		var c := CORAL_COLORS[rng.randi() % CORAL_COLORS.size()]
		var h := rng.randf_range(0.3, 0.9)
		var off := Vector3(rng.randf_range(-0.6, 0.6), 0, rng.randf_range(-0.6, 0.6))
		if k % 3 == 0:
			root.add_child(Props.ball(rng.randf_range(0.18, 0.35), c, off + Vector3(0, 0.15, 0), k, 0.15))
		else:
			var b := Props.cyl(0.04, 0.08, h, c, off + Vector3(0, h / 2.0, 0), 6)
			b.rotation = Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4))
			root.add_child(b)
	var fan := Props.box(Vector3(0.7, 0.6, 0.02), Color(0.85, 0.3, 0.55), Vector3(0, 0.35, 0))
	fan.rotation.y = rng.randf_range(0.0, PI)
	root.add_child(fan)
	return root


func _refresh_shells() -> void:
	for c in _shells.get_children():
		c.queue_free()
	for i in GameState.reef_shells.size():
		var s := ReefShell.new()
		s.index = i
		s.position = GameState.reef_shells[i]
		_shells.add_child(s)


func _process(delta: float) -> void:
	_t += delta
	var cam := get_viewport().get_camera_3d()
	var cam_p := cam.global_position if cam else Vector3(INF, INF, INF)
	var under := cam != null and UnderwaterOverlay.is_camera_under(cam_p.y, GameState.water_level_y()) and GameState.sea_at(cam_p.x, cam_p.z)
	for i in _fish.size():
		var a := _t * (0.25 if _fish_species[i] == "raie" else 0.5) + _fish_phase[i]
		var r := 1.6 + (i % 3) * 0.3
		var p := _fish_center[i] + Vector3(cos(a) * r, sin(_t * 0.7 + i) * 0.15, sin(a) * r)
		var f := _fish[i]
		f.position = p
		f.rotation.y = -a  # le nez dans le sens de la nage
		if under and p.distance_to(cam_p) < GameState.config.fish_seen_m:
			GameState.see_fish(_fish_species[i])


## Un coquillage au fond du récif : on le vise, E pour le prendre.
class ReefShell extends StaticBody3D:
	var index := 0

	func _ready() -> void:
		PhysicsLayers.make_walk_through(self)
		var m := Props.shell(index, 0.22)
		add_child(m)
		add_child(Greybox.cylinder_collision(0.25, 0.2, Vector3(0, 0.1, 0)))

	func get_prompt(_player: Node) -> String:
		return tr("PROMPT_REEF_SHELL") if GameState.can_carry("coquillages") else tr("PROMPT_HANDS_FULL")

	func interact(_player: Node) -> void:
		GameState.take_reef_shell(index)
