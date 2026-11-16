extends Node
## Autoload « Settings » : garde les options (SettingsLogic), les lit et les écrit dans
## user://settings.json (à part des parties) et les applique au moteur : langue, plein écran,
## volume. Le joueur lit le champ de vision, la sensibilité et le balancement à chaque image.

signal changed

const PATH := "user://settings.json"

var data := SettingsLogic.new()
## Faux dans les tests : rien n'est écrit sur le disque.
var persist := true


func _ready() -> void:
	load_from_disk()
	apply()


func load_from_disk() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		data.load_dict(parsed)


func save_to_disk() -> void:
	if not persist:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data.to_dict(), "\t"))


## Change une option, l'applique et l'enregistre.
func set_value(key: String, value: Variant) -> void:
	var d := data.to_dict()
	d[key] = value
	data.load_dict(d)
	apply()
	save_to_disk()
	changed.emit()


func apply() -> void:
	TranslationServer.set_locale(data.language)
	var bus := AudioServer.get_bus_index(&"Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(data.volume, 0.0001)))
	AudioServer.set_bus_mute(bus, data.volume <= 0.0)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if data.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
