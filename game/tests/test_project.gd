extends TestCase
## Le projet lui-même : chaque script compile, et les autoloads attendus sont déclarés.
## (Othmane a eu des « Identifier not declared » quand project.godot avait perdu une ligne.)

const AUTOLOADS := ["InputSetup", "GameState", "Admin"]


func test_expected_autoloads_are_declared_and_exist() -> void:
	for name in AUTOLOADS:
		var key: String = "autoload/" + name
		assert_true(ProjectSettings.has_setting(key), "%s absent de project.godot" % name)
		var path := String(ProjectSettings.get_setting(key, "")).trim_prefix("*")
		assert_true(ResourceLoader.exists(path), "%s : %s introuvable" % [name, path])


func test_settings_need_no_autoload() -> void:
	assert_false(ProjectSettings.has_setting("autoload/Settings"), "Settings est une classe statique")
	assert_true(Settings.data is SettingsLogic)


func test_every_script_compiles() -> void:
	var scripts: Array[String] = []
	_collect("res://", scripts)
	assert_true(scripts.size() > 50, "scripts trouvés : %d" % scripts.size())
	for path in scripts:
		var s: GDScript = load(path)
		assert_true(s != null and s.can_instantiate(), "ne compile pas : " + path)


func _collect(dir: String, out: Array[String]) -> void:
	for sub in DirAccess.get_directories_at(dir):
		if not sub.begins_with("."):
			_collect(dir.path_join(sub), out)
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
