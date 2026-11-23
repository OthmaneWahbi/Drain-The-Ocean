class_name SeaLifeView
extends Node3D
## La baleine et les dauphins au large (0.1.25, PRD §19.32). GameState décide quand et où
## (`sea_life`) ; cette vue les montre et dit à GameState quand le joueur les regarde
## (`spot_sea_life`), de près ou à la longue-vue. La baleine : on entend son souffle d'abord, puis
## le jet monte, le dos affleure, la queue sort avant de plonger. Les dauphins : quatre sauts en
## arc, décalés, qui avancent ensemble.

const WHALE_SIZE := 16.0
const DOLPHIN_SIZE := 3.5
const DOLPHINS := 4
## Les temps de la baleine (s depuis son apparition) : jet, dos, queue.
const SPOUT_AT := 1.4
const SPOUT_S := 3.0
const TAIL_AT := 9.0
## Les dauphins : un saut toutes les … s, … m de haut, à … m/s.
const JUMP_PERIOD := 2.4
const JUMP_H := 2.5
const SWIM_MPS := 7.0

var _root: Node3D
var _whale: Node3D
var _spout: Node3D
var _dolphins: Array[Node3D] = []
var _sound: AudioStreamPlayer3D
var _splashed: Array[bool] = []
var _splashes: Array[Node3D] = []  # une gerbe par dauphin, montrée quand il retombe
var _splash_t: Array[float] = []


func _ready() -> void:
	_sound = AudioStreamPlayer3D.new()
	_sound.max_distance = 2000.0
	_sound.unit_size = 120.0
	add_child(_sound)
	GameState.sea_life_changed.connect(_rebuild)
	GameState.game_reset.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	if _root:
		_root.queue_free()
		_root = null
	_whale = null
	_spout = null
	_dolphins.clear()
	_splashed.clear()
	_splashes.clear()
	_splash_t.clear()
	var ev := GameState.sea_life
	if ev.is_empty():
		return
	_root = Node3D.new()
	_root.position = ev.position
	_root.rotation.y = float(ev.heading)
	add_child(_root)
	_sound.position = ev.position
	if ev.kind == "baleine":
		_whale = LaterGoods.whale(WHALE_SIZE)
		_root.add_child(_whale)
		_spout = LaterGoods.spout()
		_spout.position = Vector3(0, 0, -WHALE_SIZE * 0.2)
		_spout.visible = false
		_root.add_child(_spout)
		_play("blow", 4.0)  # le son d'abord
	else:
		for i in DOLPHINS:
			var d := LaterGoods.dolphin(DOLPHIN_SIZE)
			_root.add_child(d)
			_dolphins.append(d)
			_splashed.append(false)
			var sp := LaterGoods.splash()
			sp.visible = false
			_root.add_child(sp)
			_splashes.append(sp)
			_splash_t.append(0.0)
	_process(0.0)


func _play(name: String, volume_db: float) -> void:
	_sound.stream = SoundSynth.stream(name)
	_sound.volume_db = volume_db
	_sound.play()


## La hauteur du dos de la baleine sous la surface (m, négatif = sous l'eau) à `age` s.
static func whale_rise(age: float, duration: float) -> float:
	var up := smoothstep(SPOUT_AT - 0.5, SPOUT_AT + 1.5, age)
	var down := smoothstep(TAIL_AT, duration, age)
	return lerpf(-2.5, -0.6, up) - 3.0 * down


## La hauteur d'un dauphin au-dessus de l'eau à `t` s (un arc, puis sous l'eau entre deux sauts).
static func dolphin_jump(t: float) -> float:
	var k := fposmod(t, JUMP_PERIOD) / JUMP_PERIOD
	if k > 0.45:
		return -1.0
	var u := k / 0.45
	return JUMP_H * 4.0 * u * (1.0 - u) - 0.3


func _process(delta: float) -> void:
	var ev := GameState.sea_life
	if ev.is_empty() or _root == null:
		return
	var age := float(ev.age)
	var sea := GameState.water_level_y()
	if _whale:
		_root.position.y = sea
		_whale.position.y = whale_rise(age, float(ev.duration))
		_whale.position.z = -age * 1.2
		var tail := _whale.get_node("Tail") as Node3D
		var dive := smoothstep(TAIL_AT, TAIL_AT + 2.5, age)
		_whale.rotation.x = -dive * 0.6
		tail.rotation.x = -dive * 0.5 + sin(age * 1.3) * 0.1
		_spout.visible = age > SPOUT_AT and age < SPOUT_AT + SPOUT_S
		var s := clampf((age - SPOUT_AT) / 0.6, 0.0, 1.0) * (1.0 - clampf((age - SPOUT_AT - SPOUT_S + 0.8) / 0.8, 0.0, 1.0))
		_spout.scale = Vector3(3.0 + s * 3.0, maxf(s, 0.01) * 10.0, 3.0 + s * 3.0)
		_spout.position = Vector3(0, _whale.position.y + 1.5, _whale.position.z - WHALE_SIZE * 0.2)
	else:
		_root.position.y = sea
		for i in _dolphins.size():
			var d := _dolphins[i]
			var t := age + i * 0.55
			var h := dolphin_jump(t)
			var lead := -age * SWIM_MPS
			d.position = Vector3((i - 1.5) * 3.0, h, lead + (i % 2) * 2.5)
			d.visible = h > -0.9
			var k := fposmod(t, JUMP_PERIOD) / JUMP_PERIOD / 0.45
			d.rotation.x = lerpf(0.7, -0.7, clampf(k, 0.0, 1.0))  # le nez monte, puis plonge
			_splash_t[i] = maxf(_splash_t[i] - delta, 0.0)
			_splashes[i].visible = _splash_t[i] > 0.0
			_splashes[i].scale = Vector3.ONE * (1.6 - _splash_t[i])
			if h < 0.0 and k > 0.8 and k <= 1.0 and not _splashed[i]:
				_splashed[i] = true
				_splash_t[i] = 0.6
				_splashes[i].position = Vector3(d.position.x, 0.0, d.position.z - DOLPHIN_SIZE * 0.4)
				if i == 0:
					_sound.position = _root.global_position
					_play("splash", 6.0)
			elif k < 0.5:
				_splashed[i] = false
	_check_seen(age)


## Le joueur regarde-t-il l'apparition (dans le cadre, et visible en ce moment) ?
func _check_seen(age: float) -> void:
	if bool(GameState.sea_life.get("seen", false)):
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var target := _root.global_position + Vector3(0, 1.0, 0)
	if _whale and not (_spout.visible or age > TAIL_AT):
		return  # la baleine sous l'eau : rien à voir
	var to := target - cam.global_position
	var player := get_tree().get_first_node_in_group(&"player")
	var spying: bool = player != null and bool(player.get("spying"))
	if in_view(-cam.global_basis.z, to, cam.fov):
		GameState.spot_sea_life(to.length(), spying)


## `to` est-il dans le cadre d'une caméra qui regarde vers `forward` (champ vertical `fov_deg`) ?
static func in_view(forward: Vector3, to: Vector3, fov_deg: float) -> bool:
	if to.length() < 0.01:
		return true
	return forward.normalized().dot(to.normalized()) >= cos(deg_to_rad(fov_deg * 0.5 * 0.85))
