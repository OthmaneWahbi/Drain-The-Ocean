extends SceneTree
## Lanceur de tests en ligne de commande :
##   godot --headless --path game -s res://tests/run_tests.gd
## Code de sortie 0 si tout passe, 1 sinon.
## TESTS_ONLY="test_a,test_b" (variable d'environnement) : ne lance que ces méthodes.

const TEST_DIR := "res://tests"


func _initialize() -> void:
	var total := 0
	var failed: Array[String] = []
	var only := OS.get_environment("TESTS_ONLY").split(",", false)
	var files := DirAccess.get_files_at(TEST_DIR)
	files.sort()
	for file in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file == "test_case.gd":
			continue
		var script: GDScript = load("%s/%s" % [TEST_DIR, file])
		# Un fichier de tests qui ne compile pas est un échec, pas un fichier ignoré.
		if script == null or not script.can_instantiate():
			print("  ÉCHEC %s" % file)
			failed.append("%s : le fichier ne compile pas" % file)
			continue
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_") or (not only.is_empty() and not only.has(name)):
				continue
			var test: TestCase = script.new()
			test._current = "%s::%s" % [file, name]
			test.before_each()
			test.call(name)
			test.after_each()
			total += 1
			if test.failures.is_empty():
				print("  ok    %s" % test._current)
			else:
				print("  ÉCHEC %s" % test._current)
				failed.append_array(test.failures)
	print("")
	for f in failed:
		printerr("ÉCHEC : " + f)
	print("%d tests, %d échec(s)" % [total, failed.size()])
	quit(0 if failed.is_empty() and total > 0 else 1)
