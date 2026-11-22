class_name TidePoolsView
extends Node3D
## Les flaques de marée basse (0.1.20, PRD §19.27) : un cercle de galets, un fond plus sombre,
## une eau peu profonde, et les trouvailles du moment posées au fond. Une flaque se vise (E pour
## ramasser) seulement quand la marée l'a découverte. Aucune règle ici : tout vient de GameState.

var _pools: Array[Pool] = []


func _ready() -> void:
	GameState.tide_pools_changed.connect(_refresh)
	GameState.game_reset.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	for p in _pools:
		p.queue_free()
	_pools.clear()
	for i in GameState.tide_pools.size():
		var pool := Pool.new()
		pool.index = i
		add_child(pool)
		_pools.append(pool)
	_refresh()


func _refresh() -> void:
	for p in _pools:
		if is_instance_valid(p):
			p.refresh()


## Une flaque.
class Pool extends StaticBody3D:
	var index := 0
	var _items: Node3D
	var _shape: CollisionShape3D
	var _shown: Array = []

	func data() -> Dictionary:
		return GameState.tide_pools[index] if index < GameState.tide_pools.size() else {}

	func _ready() -> void:
		var d := data()
		if d.is_empty():
			return
		position = d.position
		PhysicsLayers.make_walk_through(self)
		var r: float = GameState.config.tide_pool_radius_m
		# Un fond sombre et mouillé, et un cercle de galets.
		var bed := Props.cyl(r, r, 0.04, Color(0.33, 0.36, 0.3), Vector3(0, 0.0, 0), 14)
		add_child(bed)
		var water := Props.cyl(r * 0.92, r * 0.92, 0.02, Color(0.4, 0.72, 0.78, 0.7), Vector3(0, 0.035, 0), 14)
		water.material_override = Props.mat(Color(0.4, 0.72, 0.78))
		(water.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		(water.material_override as StandardMaterial3D).albedo_color.a = 0.55
		add_child(water)
		var rng := RandomNumberGenerator.new()
		rng.seed = 100 + index
		for k in 11:
			var a := TAU * k / 11.0 + rng.randf_range(-0.1, 0.1)
			var s := rng.randf_range(0.12, 0.22)
			add_child(Props.ball(s, Color(0.5, 0.5, 0.47).darkened(rng.randf_range(0.0, 0.25)), Vector3(cos(a) * r, s * 0.3, sin(a) * r), k, 0.15, Vector3(1.2, 0.7, 1.0)))
		_items = Node3D.new()
		add_child(_items)
		_shape = Greybox.cylinder_collision(r, 0.3, Vector3(0, 0.1, 0))
		add_child(_shape)

	func refresh() -> void:
		var d := data()
		if d.is_empty() or _items == null:
			return
		var items: Array = d.items
		if items == _shown:
			return
		_shown = items.duplicate()
		for c in _items.get_children():
			c.queue_free()
		var r: float = GameState.config.tide_pool_radius_m
		for k in items.size():
			var m := Finds.model(String(items[k]))
			var a := 1.1 + k * 2.3
			m.position = Vector3(cos(a), 0.0, sin(a)) * r * 0.45
			m.rotation.y = a * 1.7
			_items.add_child(m)

	func _process(_delta: float) -> void:
		var d := data()
		if d.is_empty() or _shape == null:
			return
		var open := GameState.tide_pool_uncovered(d)
		_shape.disabled = not open or (d.items as Array).is_empty()

	func get_prompt(_player: Node) -> String:
		var d := data()
		if d.is_empty() or not GameState.tide_pool_uncovered(d) or (d.items as Array).is_empty():
			return ""
		var what := String(d.items[0])
		if what == "coquillage" and not GameState.can_carry("coquillages"):
			return tr("PROMPT_HANDS_FULL")
		return tr("PROMPT_POOL_TAKE") % tr("FIND_" + what.to_upper())

	func interact(_player: Node) -> void:
		GameState.take_from_pool(data())
