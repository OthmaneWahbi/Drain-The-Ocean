class_name IslandEventsView
extends Node3D
## Ce qui arrive sur l'île (0.1.23, PRD §19.30), vu : les épaves qui dérivent puis s'échouent
## (E pour les ouvrir), les tortues qui pondent la nuit et leurs nids, les petites tortues qui
## courent vers la mer, les cocotiers plantés (pousse puis palmier), ce que la pelle sort du sable,
## et à l'horizon les îles lointaines et le tourbillon du drain. Aucune règle : tout vient de
## GameState et de ses signaux.

const ISLAND_RING_M := 420.0

var _wrecks: Dictionary = {}  # id -> WreckBody
var _nests: Dictionary = {}  # id -> Node3D
var _palms: Dictionary = {}  # id -> [Node3D, grown]
var _actors: Array = []  # [node, from, to, t, duration, kind]
var _whirl: Node3D
var _t := 0.0


func _ready() -> void:
	GameState.wreck_added.connect(_on_wreck_added)
	GameState.wreck_removed.connect(_on_wreck_removed)
	GameState.turtle_laid.connect(_on_turtle_laid)
	GameState.turtles_hatched.connect(_on_hatched)
	GameState.planted_changed.connect(_refresh_palms)
	GameState.dug_up.connect(_on_dug_up)
	GameState.game_reset.connect(_clear)
	_build_horizon()
	for w in GameState.wrecks:
		_on_wreck_added(w)
	_refresh_nests()
	_refresh_palms()


func _clear() -> void:
	for id in _wrecks:
		_wrecks[id].queue_free()
	_wrecks.clear()
	for id in _nests:
		_nests[id].queue_free()
	_nests.clear()
	for id in _palms:
		_palms[id][0].queue_free()
	_palms.clear()


# --- L'horizon : trois îles lointaines et le tourbillon du drain -------------------------------

func _build_horizon() -> void:
	var islands := [[35.0, 110.0, Color(0, 0, 0, 0)], [140.0, 80.0, Color(0.25, 0.45, 0.85)], [215.0, 150.0, Color(0, 0, 0, 0)]]
	for row in islands:
		var a := deg_to_rad(float(row[0]))
		var isl := IslandGoods.far_island(float(row[1]), row[2])
		isl.position = Vector3(cos(a) * ISLAND_RING_M, GameState.config.sea_level_y - 2.0, sin(a) * ISLAND_RING_M)
		isl.rotation.y = -a
		add_child(isl)
	_whirl = IslandGoods.whirlpool()
	var wa := deg_to_rad(300.0)
	_whirl.position = Vector3(cos(wa) * 150.0, GameState.config.sea_level_y + 0.08, sin(wa) * 150.0)
	add_child(_whirl)


# --- Épaves -------------------------------------------------------------------------------

func _on_wreck_added(w: Dictionary) -> void:
	var body := WreckBody.new()
	body.wreck = w
	add_child(body)
	_wrecks[w.id] = body


func _on_wreck_removed(w: Dictionary) -> void:
	var body: Node = _wrecks.get(w.id)
	if body:
		body.queue_free()
	_wrecks.erase(w.id)


class WreckBody extends StaticBody3D:
	var wreck: Dictionary
	var _model: Node3D
	var _t := 0.0

	func _ready() -> void:
		_model = IslandGoods.wreck_crate()
		add_child(_model)
		add_child(Greybox.box_collision(Vector3(0.8, 0.6, 0.7), Vector3(0, 0.3, 0)))
		position = wreck.position

	func _process(delta: float) -> void:
		_t += delta
		position = wreck.position
		if wreck.landed:
			_model.position.y = 0.0
			_model.rotation = Vector3(0.0, 0.3, 0.08)
		else:
			# Elle flotte : à moitié dans l'eau, elle tangue.
			_model.position.y = -0.3 + sin(_t * 1.7) * 0.08
			_model.rotation = Vector3(sin(_t * 1.3) * 0.12, _t * 0.05, sin(_t * 1.1) * 0.1)

	func get_prompt(_player: Node) -> String:
		return tr("PROMPT_WRECK") if wreck.landed else tr("PROMPT_WRECK_DRIFT")

	func interact(_player: Node) -> void:
		GameState.open_wreck(wreck)


# --- Tortues -------------------------------------------------------------------------------

func _refresh_nests() -> void:
	for n in GameState.nests:
		if not _nests.has(n.id):
			var m := IslandGoods.nest()
			m.position = n.position
			add_child(m)
			_nests[n.id] = m


## Une tortue sort de la mer, va au nid, creuse (le nid apparaît), puis repart.
func _on_turtle_laid(n: Dictionary) -> void:
	var p: Vector3 = n.position
	var sea := _sea_point(p, 0.0)
	var t := IslandGoods.turtle(0.9)
	add_child(t)
	_actors.append([t, sea, p, 0.0, 10.0, "go"])
	_refresh_nests()


## Les petites tortues courent du nid vers la mer, un peu en éventail.
func _on_hatched(n: Dictionary) -> void:
	var m: Node = _nests.get(n.id)
	if m:
		m.queue_free()
	_nests.erase(n.id)
	var p: Vector3 = n.position
	var dir := Vector3(p.x, 0, p.z).normalized()
	for i in GameState.config.turtle_babies:
		var baby := IslandGoods.turtle(0.18)
		add_child(baby)
		var side := dir.cross(Vector3.UP) * (i - 2) * 0.6
		var to := _sea_point(p, (i - 2) * 0.05)
		_actors.append([baby, p + side * 0.2, to, -0.3 * i, 8.0 + i * 0.5, "run"])


## Un point dans la mer, 3 m après le rivage, dans la direction du nid vu du centre de l'île
## (tourné de `turn` radians, pour l'éventail des petites).
func _sea_point(from: Vector3, turn: float) -> Vector3:
	var a := atan2(from.z, from.x) + turn
	var r := GameState.terrain.coast_at(a) + 3.0
	return Vector3(cos(a) * r, GameState.water_level_y() - 0.1, sin(a) * r)


func _process(delta: float) -> void:
	_t += delta
	if _whirl:
		_whirl.rotation.y -= delta * 0.8
	for a in _actors.duplicate():
		var node: Node3D = a[0]
		a[3] += delta
		var k := clampf(float(a[3]) / float(a[4]), 0.0, 1.0)
		if a[3] < 0.0:
			node.visible = false
			continue
		node.visible = true
		var from: Vector3 = a[1]
		var to: Vector3 = a[2]
		var pos := from.lerp(to, k)
		# Sur le sable, ou à fleur d'eau quand elle nage.
		pos.y = maxf(GameState.terrain.height(pos.x, pos.z), GameState.water_level_y() - 0.15)
		node.position = pos
		var flat := Vector3(to.x - from.x, 0, to.z - from.z)
		if flat.length() > 0.01:
			node.rotation.y = atan2(-flat.x, -flat.z)
		for leg in node.get_children():
			if String(leg.name).begins_with("Leg"):
				leg.rotation.y = sin(_t * 8.0 + leg.get_index()) * 0.5
		if k >= 1.0:
			if a[5] == "go":
				# Elle a pondu : elle repart vers la mer.
				a[1] = to
				a[2] = from
				a[3] = -3.0  # elle creuse un moment avant de repartir
				a[5] = "back"
				node.visible = true
			else:
				node.queue_free()
				_actors.erase(a)


# --- Cocotiers plantés ----------------------------------------------------------------------

func _refresh_palms() -> void:
	var alive := {}
	for pl in GameState.planted:
		alive[pl.id] = true
		var grown := GameState.is_grown(pl)
		if _palms.has(pl.id) and _palms[pl.id][1] == grown:
			continue
		if _palms.has(pl.id):
			_palms[pl.id][0].queue_free()
		var node: Node3D
		if grown:
			var body := StaticBody3D.new()
			body.add_child(Models.palm(4.5, hash(pl.id) % 1000))
			body.add_child(Greybox.cylinder_collision(0.25, 2.4, Vector3(0, 1.2, 0)))
			node = body
		else:
			node = IslandGoods.sapling()
		node.position = pl.position
		add_child(node)
		_palms[pl.id] = [node, grown]
	for id in _palms.keys():
		if not alive.has(id):
			_palms[id][0].queue_free()
			_palms.erase(id)


# --- Ce que la pelle sort du sable -----------------------------------------------------------

func _on_dug_up(kind: String, pos: Vector3) -> void:
	var model: Node3D
	match kind:
		"piece":
			model = IslandGoods.coin()
		"perle":
			model = Props.pile("perles", 3)
			model.scale = Vector3.ONE * 0.4
		"ferraille":
			model = Props.pile("mineraux", 4)
			model.scale = Vector3.ONE * 0.4
		_:
			model = IslandGoods.chest()
	model.position = pos
	add_child(model)
	var label := Label3D.new()
	label.text = "DUG_" + kind.to_upper()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font = UiTheme.title_font()
	label.font_size = 56
	label.outline_size = 12
	label.modulate = IslandGoods.GOLD
	label.position = pos + Vector3(0, 0.8, 0)
	add_child(label)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(model, "position:y", pos.y + 1.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(model, "rotation:y", TAU, 1.2)
	tw.tween_property(label, "position:y", pos.y + 2.0, 1.8)
	tw.tween_property(label, "modulate:a", 0.0, 1.8)
	tw.chain().tween_callback(func():
		model.queue_free()
		label.queue_free())
