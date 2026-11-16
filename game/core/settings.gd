class_name Settings
extends RefCounted
## Les options du joueur, accessibles partout par `Settings.data` (variables statiques, pas
## d'autoload : rien à déclarer dans project.godot, donc rien que l'éditeur puisse perdre).
## Lues une fois dans user://settings.json (à part des parties), écrites à chaque changement,
## et appliquées au moteur : langue, plein écran, volume. Le joueur lit le champ de vision,
## la sensibilité et le balancement à chaque image.

const PATH := "user://settings.json"

## Les valeurs (SettingsLogic), chargées depuis le disque au premier accès.
static var data: SettingsLogic = _load()
## Prévient les menus quand une option change : `Settings.events.changed.connect(...)`.
static var events := Events.new()
## Faux dans les tests : rien n'est écrit sur le disque.
static var persist := true


class Events extends RefCounted:
	signal changed


static func _load() -> SettingsLogic:
	var s := SettingsLogic.new()
	if FileAccess.file_exists(PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if typeof(parsed) == TYPE_DICTIONARY:
			s.load_dict(parsed)
	return s


static func save_to_disk() -> void:
	if not persist:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data.to_dict(), "\t"))


## Change une option, l'applique et l'enregistre.
static func set_value(key: String, value: Variant) -> void:
	var d := data.to_dict()
	d[key] = value
	data.load_dict(d)
	apply()
	save_to_disk()
	events.changed.emit()


## Applique les options au moteur (appelé au lancement par main.gd, puis à chaque changement).
static func apply() -> void:
	TranslationServer.set_locale(data.language)
	var bus := AudioServer.get_bus_index(&"Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(data.volume, 0.0001)))
	AudioServer.set_bus_mute(bus, data.volume <= 0.0)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if data.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
