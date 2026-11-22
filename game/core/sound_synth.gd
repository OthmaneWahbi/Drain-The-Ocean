class_name SoundSynth
extends RefCounted
## Les sons du jeu, fabriqués par calcul (synthèse), sans aucun fichier audio : en attendant les
## banques CC0 (M-76), chaque bruit est une petite recette (oscillateurs, bruit filtré, enveloppes).
## Tout est déterministe (bruit à graine fixe) : mêmes échantillons à chaque lancement, testables.
##
## `samples(name)` rend les échantillons (-1..1) ; `stream(name)` les emballe dans un AudioStreamWAV.

const RATE := 22050
const NAMES := ["fill", "pour", "plop", "ring", "pickup", "jingle", "plane", "engine", "gurgle", "waves", "tink"]
## Les sons qui tournent en boucle.
const LOOPS := ["waves", "gurgle", "engine"]


static func samples(name: String) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name)
	match name:
		"fill":  # on plonge le seau : un « splotch » de bruit qui s'éteint
			return _noise_burst(rng, 0.35, 1800.0, 6.0, 0.7)
		"pour":  # l'eau qui coule : bruit doux, plus long
			return _noise_burst(rng, 0.7, 2600.0, 2.5, 0.5)
		"plop":  # la bonde : une note qui chute très vite
			return _sweep(0.25, 900.0, 140.0, 14.0, 0.9)
		"ring":  # le téléphone rouge : deux tons alternés
			return _ring(1.2)
		"pickup":  # ramasser : petit bip montant
			return _sweep(0.12, 600.0, 1300.0, 18.0, 0.5)
		"jingle":  # un jalon : arpège do-mi-sol-do
			return _arpeggio([523.25, 659.25, 783.99, 1046.5], 0.11, 0.5)
		"plane":  # l'avion : bourdonnement grave qui monte puis s'éloigne
			return _drone(3.0, 95.0, 0.45)
		"engine":  # le moteur de l'avion de livraison (boucle, joué en 3D sur l'avion, 0.1.17)
			return _engine(1.0, 96.0, 0.4)
		"gurgle":  # le glouglou : bruit grave modulé (boucle)
			return _gurgle(rng, 2.0)
		"waves":  # l'ambiance de la mer (boucle)
			return _waves(rng, 4.0)
		"tink":  # 0.1.20 : un grain de sel tombe sur le tas (petit tintement de verre)
			return _tink(0.22, 2093.0, 0.35)
	return PackedFloat32Array()


static func stream(name: String) -> AudioStreamWAV:
	var data := samples(name)
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	if LOOPS.has(name):
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = data.size()
	return wav


## Durée en secondes.
static func length_s(data: PackedFloat32Array) -> float:
	return data.size() / float(RATE)


static func peak(data: PackedFloat32Array) -> float:
	var p := 0.0
	for v in data:
		p = maxf(p, absf(v))
	return p


# --- Recettes ------------------------------------------------------------------------------

## Bruit passé dans un filtre passe-bas simple (un pôle), avec une enveloppe qui retombe.
static func _noise_burst(rng: RandomNumberGenerator, dur: float, cutoff: float, decay: float, gain: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var a := 1.0 - exp(-TAU * cutoff / RATE)
	var y := 0.0
	for i in n:
		var t := i / float(RATE)
		y += a * (rng.randf_range(-1.0, 1.0) - y)
		var env := minf(t * 60.0, 1.0) * exp(-decay * t)
		out[i] = y * env * gain * 2.0
	return out


## Une sinusoïde dont la fréquence glisse de f0 à f1 (exponentiellement).
static func _sweep(dur: float, f0: float, f1: float, decay: float, gain: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := i / float(RATE)
		var f := f0 * pow(f1 / f0, t / dur)
		phase += TAU * f / RATE
		out[i] = sin(phase) * exp(-decay * t) * minf(t * 400.0, 1.0) * gain
	return out


static func _ring(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := i / float(RATE)
		var f := 880.0 if int(t * 16.0) % 2 == 0 else 1100.0
		var on := 1.0 if fmod(t, 0.6) < 0.45 else 0.0
		out[i] = signf(sin(TAU * f * t)) * 0.18 * on * minf((dur - t) * 20.0, 1.0)
	return out


static func _arpeggio(notes: Array, step: float, gain: float) -> PackedFloat32Array:
	var dur := step * notes.size() + 0.4
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for k in notes.size():
		var start := int(k * step * RATE)
		for i in range(start, n):
			var t := (i - start) / float(RATE)
			out[i] += sin(TAU * float(notes[k]) * t) * exp(-6.0 * t) * gain / 2.0
	return out


static func _drone(dur: float, f: float, gain: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := i / float(RATE)
		var env := sin(PI * t / dur)  # arrive, passe, s'éloigne
		var doppler := f * (1.08 - 0.16 * t / dur)
		var saw := fmod(doppler * t, 1.0) * 2.0 - 1.0
		out[i] = (saw * 0.6 + sin(TAU * doppler * 2.0 * t) * 0.4) * env * gain
	return out


## Un moteur qui tourne rond, en boucle sans couture : la durée contient un nombre entier de
## périodes de chaque composante (f, 2f, et le « teuf-teuf » à 12 Hz).
static func _engine(dur: float, f: float, gain: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := i / float(RATE)
		var saw := fmod(f * t + 0.5, 1.0) * 2.0 - 1.0  # décalée d'une demi-période : part de 0, sans clic
		var chug := 0.75 + 0.25 * sin(TAU * 12.0 * t)
		out[i] = (saw * 0.55 + sin(TAU * f * 2.0 * t) * 0.45) * chug * gain
	return out


static func _gurgle(rng: RandomNumberGenerator, dur: float) -> PackedFloat32Array:
	var base := _noise_burst(rng, dur, 300.0, 0.0, 1.0)
	for i in base.size():
		var t := i / float(RATE)
		# Les bulles : une modulation rapide et irrégulière ; on referme la boucle en douceur.
		var bubbles := 0.5 + 0.5 * sin(TAU * 7.0 * t + sin(TAU * 1.3 * t) * 3.0)
		var edge := minf(minf(t, dur - t) * 20.0, 1.0)
		base[i] *= bubbles * edge * 0.8
	return base


static func _waves(rng: RandomNumberGenerator, dur: float) -> PackedFloat32Array:
	var base := _noise_burst(rng, dur, 700.0, 0.0, 1.0)
	for i in base.size():
		var t := i / float(RATE)
		# Une vague toutes les 2 s : la boucle de 4 s retombe pile sur ses pieds.
		var swell := 0.25 + 0.75 * pow(0.5 - 0.5 * cos(TAU * t / 2.0), 2.0)
		var edge := minf(minf(t, dur - t) * 30.0, 1.0)
		base[i] *= swell * edge * 0.35
	return base


## Un tintement : deux sinus (la note et sa quinte aiguë) qui s'éteignent très vite.
static func _tink(dur: float, f: float, gain: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 28.0) * minf(t * 2000.0, 1.0)
		out[i] = (sin(TAU * f * t) + 0.4 * sin(TAU * f * 1.5 * t)) * env * gain / 1.4
	return out
