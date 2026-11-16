extends TestCase
## Les sons fabriqués par calcul (SoundSynth) : présents, pas saturés, pas muets, déterministes.


func test_every_sound_exists_and_is_short_enough() -> void:
	for name in SoundSynth.NAMES:
		var data := SoundSynth.samples(name)
		assert_true(data.size() > 0, name)
		assert_true(SoundSynth.length_s(data) <= 4.5, "%s trop long" % name)


func test_no_sound_clips_and_none_is_silent() -> void:
	for name in SoundSynth.NAMES:
		var p := SoundSynth.peak(SoundSynth.samples(name))
		assert_true(p <= 1.0, "%s sature (%f)" % [name, p])
		assert_true(p > 0.05, "%s muet (%f)" % [name, p])


func test_sounds_are_the_same_every_time() -> void:
	assert_eq(SoundSynth.samples("waves"), SoundSynth.samples("waves"))
	assert_eq(SoundSynth.samples("fill"), SoundSynth.samples("fill"))


func test_loops_start_and_end_quietly() -> void:
	for name in SoundSynth.LOOPS:
		var data := SoundSynth.samples(name)
		assert_true(absf(data[0]) < 0.02 and absf(data[data.size() - 1]) < 0.02, "%s : pas de clic à la boucle" % name)


func test_streams_are_16_bit_wav_and_loop_when_needed() -> void:
	var wav := SoundSynth.stream("waves")
	assert_eq(wav.format, AudioStreamWAV.FORMAT_16_BITS)
	assert_eq(wav.mix_rate, SoundSynth.RATE)
	assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	assert_eq(wav.data.size(), SoundSynth.samples("waves").size() * 2)
	assert_eq(SoundSynth.stream("plop").loop_mode, AudioStreamWAV.LOOP_DISABLED)


func test_plop_falls_in_pitch() -> void:
	# On compte les passages par zéro au début et à la fin : moins à la fin = plus grave.
	var d := SoundSynth.samples("plop")
	var q := d.size() / 4
	assert_true(_crossings(d, 0, q) > _crossings(d, 3 * q, d.size()) * 2)


func _crossings(d: PackedFloat32Array, a: int, b: int) -> int:
	var n := 0
	for i in range(a + 1, b):
		if signf(d[i]) != signf(d[i - 1]):
			n += 1
	return n
