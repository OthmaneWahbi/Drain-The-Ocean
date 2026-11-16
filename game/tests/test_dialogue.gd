extends TestCase
## Les conversations de la cabine téléphonique (0.1.2) : fichier valide et traduit, déroulé des
## répliques, choix et actions.


func _data() -> Dictionary:
	return DialogueLogic.load_file()


func _translated_keys() -> Dictionary:
	var keys := {}
	var f := FileAccess.open("res://localization/strings.csv", FileAccess.READ)
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 3 and row[0] != "":
			keys[row[0]] = row
	return keys


func test_dialogue_file_is_valid() -> void:
	var data := _data()
	for conv in ["tutorial", "offer", "call", "no_catalogue"]:
		assert_true(data.has(conv), "conversation « %s » présente" % conv)
	assert_eq(DialogueLogic.errors(data), [] as Array[String])


func test_every_dialogue_line_is_translated() -> void:
	var keys := _translated_keys()
	for k in DialogueLogic.text_keys(_data()):
		assert_true(keys.has(k), "clé traduite : " + k)
		if keys.has(k):
			assert_true(keys[k][1] != "" and keys[k][2] != "", "français et anglais : " + k)


func test_errors_catch_broken_links() -> void:
	var broken := {"x": {"start": "a", "nodes": {"a": {"text": "K", "next": "nope"}, "b": {"text": ""}}}}
	assert_eq(DialogueLogic.errors(broken).size(), 2)


func test_tutorial_runs_to_the_hold_music() -> void:
	var d := DialogueLogic.new(_data(), 1)
	assert_true(d.start("tutorial"))
	assert_eq(d.speaker(), "DLG_GINETTE")
	assert_eq(d.choices().size(), 2)
	assert_eq(d.advance(), "", "on ne saute pas une question")
	assert_true(d.is_active())
	d.choose(1)
	var actions := []
	var guard := 0
	while d.is_active() and guard < 20:
		guard += 1
		actions.append(d.choose(1) if not d.choices().is_empty() else d.advance())
	assert_false(d.is_active(), "la conversation se termine")
	assert_true(actions.has("hold_music"), "elle finit par la musique d'attente")


func test_offer_choice_opens_the_catalogue() -> void:
	var d := DialogueLogic.new(_data(), 1)
	d.start("offer")
	assert_eq(d.choose(0), "open_catalogue")
	assert_false(d.is_active())
	d.start("offer")
	assert_eq(d.choose(1), "")
	assert_true(d.is_active(), "« non merci » : Ginette répond encore")
	d.advance()
	assert_false(d.is_active())


func test_call_greeting_varies_and_question_loops_back() -> void:
	var seen := {}
	for s in 40:
		var d := DialogueLogic.new(_data(), s + 1)
		d.start("call")
		seen[d.text()] = true
	assert_true(seen.size() >= 3, "plusieurs façons de décrocher : %d" % seen.size())
	var d := DialogueLogic.new(_data(), 3)
	d.start("call")
	d.choose(1)  # « Il reste beaucoup d'eau ? »
	d.advance()
	assert_eq(d.text(), "DLG_CALL_ELSE")
	assert_eq(d.choose(0), "open_catalogue")


func test_unknown_conversation_does_not_start() -> void:
	var d := DialogueLogic.new(_data())
	assert_false(d.start("nope"))
	assert_false(d.is_active())
	assert_eq(d.choose(0), "")
