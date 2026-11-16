class_name SettingsLogic
extends RefCounted
## Les options du joueur (M-21, M-72, M-73), sans aucun effet sur le moteur : juste les valeurs,
## leurs bornes, et la lecture/écriture. `Settings` (autoload) les applique.

const LANGUAGES := ["fr", "en"]

var fov: float = 75.0
var mouse_sensitivity: float = 0.0025
var head_bob: bool = true
var fullscreen: bool = false
var language: String = "fr"
## Chronomètre précis affiché en haut de l'écran (option « speedrun », M-73).
var show_timer: bool = false
var volume: float = 0.8


## Remet chaque valeur dans ses bornes.
func sanitize() -> void:
	fov = clampf(fov, 60.0, 110.0)
	mouse_sensitivity = clampf(mouse_sensitivity, 0.0005, 0.008)
	volume = clampf(volume, 0.0, 1.0)
	if not LANGUAGES.has(language):
		language = "fr"


func to_dict() -> Dictionary:
	return {"fov": fov, "mouse_sensitivity": mouse_sensitivity, "head_bob": head_bob, "fullscreen": fullscreen, "language": language, "show_timer": show_timer, "volume": volume}


func load_dict(d: Dictionary) -> void:
	fov = float(d.get("fov", fov))
	mouse_sensitivity = float(d.get("mouse_sensitivity", mouse_sensitivity))
	head_bob = bool(d.get("head_bob", head_bob))
	fullscreen = bool(d.get("fullscreen", fullscreen))
	language = String(d.get("language", language))
	show_timer = bool(d.get("show_timer", show_timer))
	volume = float(d.get("volume", volume))
	sanitize()


## Balancement de la tête en marchant (décalage vertical, en mètres).
static func bob_offset(walk_time: float, speed_ratio: float, enabled: bool) -> float:
	if not enabled:
		return 0.0
	return sin(walk_time * 9.0) * 0.035 * clampf(speed_ratio, 0.0, 1.5)
