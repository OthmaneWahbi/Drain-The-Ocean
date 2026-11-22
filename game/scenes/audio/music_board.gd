class_name MusicBoard
extends Node
## La musique selon le moment de la journée (0.1.24, PRD §19.31) : matin, midi, soir, nuit
## (`config.music_moments` donne l'heure de début de chacun). Quand le moment change, l'ancienne
## musique s'éteint et la nouvelle monte en `music_fade_s` secondes. Les boucles sont fabriquées
## par SoundSynth, en arrière-plan (WorkerThreadPool) pour ne pas figer le jeu. Le volume vient
## des options (« Musique »). Indépendant : on peut retirer ce nœud sans rien casser.

var _players: Array[AudioStreamPlayer] = []
var _current := 0  # le lecteur qui monte (l'autre descend)
var _moment := ""
var _streams: Dictionary = {}  # moment -> AudioStreamWAV
var _pending: Dictionary = {}  # moment -> [id de tâche, PackedFloat32Array partagé]
var _fade := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)


## Le moment de la journée à l'heure `hour` : le dernier dont l'heure de début est passée.
static func moment_at(hour: float, moments: Dictionary) -> String:
	var best := ""
	var best_h := -INF
	var last := ""
	var last_h := -INF
	for k in moments:
		var h := float(moments[k])
		if h <= hour and h > best_h:
			best = String(k)
			best_h = h
		if h > last_h:
			last = String(k)
			last_h = h
	return best if best != "" else last  # avant le premier moment : celui de la veille au soir


## Le gain (0 à 1) de la musique qui monte, `t` secondes après le changement.
static func fade_in(t: float, fade_s: float) -> float:
	return clampf(t / maxf(fade_s, 0.001), 0.0, 1.0)


func _process(delta: float) -> void:
	var cfg := GameState.config
	var want := moment_at(GameState.day.hour(), cfg.music_moments)
	if GameState.ending != null:
		want = ""  # pendant la fin, la musique se tait
	if want != _moment:
		_moment = want
		_fade = 0.0
		_current = 1 - _current
		_players[_current].stop()
		_players[_current].stream = null
	if _moment != "" and _players[_current].stream == null:
		var s := _stream(_moment)
		if s:
			_players[_current].stream = s
			_players[_current].play()
	_fade = minf(_fade + delta / maxf(cfg.music_fade_s, 0.001), 1.0)
	var vol := Settings.data.music_volume
	_set_gain(_players[_current], vol * _fade)
	_set_gain(_players[1 - _current], vol * (1.0 - _fade))
	if _fade >= 1.0 and _players[1 - _current].playing:
		_players[1 - _current].stop()


func _set_gain(p: AudioStreamPlayer, g: float) -> void:
	p.volume_db = linear_to_db(maxf(g, 0.0001)) - 6.0


## La boucle d'un moment : prête, ou lancée en arrière-plan (null en attendant).
func _stream(moment: String) -> AudioStreamWAV:
	if _streams.has(moment):
		return _streams[moment]
	if not _pending.has(moment):
		var box := [PackedFloat32Array()]
		var id := WorkerThreadPool.add_task(func(): box[0] = SoundSynth.music_samples(moment))
		_pending[moment] = [id, box]
		return null
	var job: Array = _pending[moment]
	if not WorkerThreadPool.is_task_completed(job[0]):
		return null
	WorkerThreadPool.wait_for_task_completion(job[0])
	_pending.erase(moment)
	_streams[moment] = SoundSynth.wrap_loop(job[1][0], SoundSynth.MUSIC_RATE)
	return _streams[moment]


func _exit_tree() -> void:
	for m in _pending:
		WorkerThreadPool.wait_for_task_completion(_pending[m][0])
	_pending.clear()
