class_name SoundBoard
extends Node
## Joue les sons (SoundSynth) en regardant GameState, sans rien lui demander : le seau qui se
## remplit ou se vide, le téléphone qui sonne, un ramassage, un jalon, l'avion, la bonde.
## Indépendant : on peut retirer ce nœud sans rien casser. Le volume général vient des options.

const POOL := 6

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _waves: AudioStreamPlayer
var _gurgle: AudioStreamPlayer
var _ring: AudioStreamPlayer
var _last_bucket_l := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	for name in SoundSynth.NAMES:
		_streams[name] = SoundSynth.stream(name)
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_waves = _loop("waves", -10.0)
	_gurgle = _loop("gurgle", -2.0)
	_ring = AudioStreamPlayer.new()
	_ring.stream = _streams["ring"]
	_ring.volume_db = -8.0
	add_child(_ring)
	_waves.play()
	GameState.milestone_reached.connect(func(_m): play("jingle"))
	GameState.pickup_removed.connect(func(_p): play("pickup", -6.0))
	# 0.1.19 : le crabe croque (plop) ou est content (petit son de ramassage).
	GameState.pet_reacted.connect(func(a: int): play("plop" if a == CrabPose.Anim.EAT else "pickup", -9.0))
	# L'avion (0.1.17) porte son propre bruit de moteur, en 3D (DeliveryPlane) : il s'entend
	# quand il passe, et plus au moment de la commande.
	GameState.ending_phase_changed.connect(_on_ending_phase)
	GameState.game_reset.connect(func(): _last_bucket_l = 0.0)
	_last_bucket_l = GameState.bucket.water_l


## Joue un son court (pris dans une petite réserve de lecteurs).
func play(name: String, volume_db := 0.0) -> void:
	if not _streams.has(name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[name]
	p.volume_db = volume_db
	p.pitch_scale = randf_range(0.95, 1.05)  # jamais deux fois exactement le même
	p.play()


func _process(_delta: float) -> void:
	# Le seau : plus d'eau = on vient de puiser ; moins = on verse.
	var water := GameState.bucket.water_l
	if water > _last_bucket_l + 0.01:
		play("fill", -4.0)
	elif water < _last_bucket_l - 0.01:
		play("pour", -4.0)
	_last_bucket_l = water
	# Le téléphone sonne tant qu'on ne décroche pas.
	# Pendant la conversation du premier appel, on a décroché : plus de sonnerie.
	var booth := get_tree().get_first_node_in_group(&"phone_booth")
	var in_call: bool = booth != null and booth.is_in_call()
	if GameState.phone.is_ringing() and GameState.ending == null and not in_call:
		if not _ring.playing:
			_ring.play()
	elif _ring.playing:
		_ring.stop()
	# La mer se tait quand l'océan est parti.
	_waves.volume_db = -10.0 if GameState.ending_drop_m < 2.0 else -40.0


func _on_ending_phase(phase: int) -> void:
	match phase:
		EndingLogic.Phase.GURGLE:
			play("plop")
			_gurgle.play()
		EndingLogic.Phase.WALK:
			_gurgle.stop()


func _loop(name: String, volume_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = _streams[name]
	p.volume_db = volume_db
	add_child(p)
	return p
