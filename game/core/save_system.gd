class_name SaveSystem
extends RefCounted
## Sauvegardes JSON versionnées (PRD §16.1). Une sauvegarde par emplacement.
## La sauvegarde manuelle (M-78) écrit au même endroit que l'automatique et la remplace.

const SAVE_VERSION := 1
const DEFAULT_DIR := "user://saves"


static func slot_path(slot: int, dir: String = DEFAULT_DIR) -> String:
	return "%s/slot_%d.json" % [dir, slot]


static func write(slot: int, data: Dictionary, dir: String = DEFAULT_DIR) -> Error:
	var err := DirAccess.make_dir_recursive_absolute(dir)
	if err != OK and err != ERR_ALREADY_EXISTS:
		return err
	var payload := data.duplicate(true)
	payload["save_version"] = SAVE_VERSION
	payload["saved_at_unix"] = Time.get_unix_time_from_system()
	var tmp_path := slot_path(slot, dir) + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	# Écriture atomique : on remplace l'ancien fichier seulement quand le nouveau est complet.
	return DirAccess.rename_absolute(tmp_path, slot_path(slot, dir))


## Renvoie un dictionnaire vide si l'emplacement est vide ou illisible.
static func read(slot: int, dir: String = DEFAULT_DIR) -> Dictionary:
	var path := slot_path(slot, dir)
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Sauvegarde illisible : %s" % path)
		return {}
	return migrate(parsed)


static func exists(slot: int, dir: String = DEFAULT_DIR) -> bool:
	return FileAccess.file_exists(slot_path(slot, dir))


static func delete(slot: int, dir: String = DEFAULT_DIR) -> void:
	if exists(slot, dir):
		DirAccess.remove_absolute(slot_path(slot, dir))


## Ce que le menu principal montre d'un emplacement (M-71) : temps de jeu, litres retirés, date.
## Vide si l'emplacement est vide ou illisible.
static func summary(slot: int, dir: String = DEFAULT_DIR) -> Dictionary:
	var data := read(slot, dir)
	if data.is_empty():
		return {}
	return {
		"play_time_s": float(data.get("play_time_s", 0.0)),
		"removed_l": float(data.get("ocean", {}).get("removed_l", 0.0)),
		"saved_at_unix": float(data.get("saved_at_unix", 0.0)),
		"best_time_s": float(data.get("best_time_s", 0.0)),
		"finished_runs": int(data.get("finished_runs", 0)),
	}


## Met à niveau une sauvegarde ancienne vers SAVE_VERSION. Chaque nouvelle version ajoute une étape ici.
static func migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("save_version", 0))
	if version > SAVE_VERSION:
		push_warning("Sauvegarde d'une version plus récente (%d)" % version)
	# v0 -> v1 : rien à faire pour l'instant.
	data["save_version"] = SAVE_VERSION
	return data
