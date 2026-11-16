class_name DialogueLogic
extends RefCounted
## Les conversations au téléphone de la cabine (PRD §9), sans aucun affichage.
## Les textes sont dans `data/dialogues.json` (des clés de traduction). Une conversation est une
## suite de répliques ; chaque réplique a un interlocuteur, un texte (ou plusieurs variantes,
## tirées au hasard), puis soit une suite (`next`), soit des choix de réponse, chacun menant à
## une autre réplique et/ou déclenchant une action (« open_catalogue », « hold_music »…).
## Sans suite ni choix, la conversation se termine.

const DEFAULT_PATH := "res://data/dialogues.json"

var data: Dictionary = {}
var conversation := ""
var node_id := ""
var _text_key := ""
var _rng := RandomNumberGenerator.new()


func _init(p_data: Dictionary = {}, rng_seed: int = 0) -> void:
	data = p_data
	if rng_seed != 0:
		_rng.seed = rng_seed
	else:
		_rng.randomize()


static func load_file(path: String = DEFAULT_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Commence une conversation. Faux si elle n'existe pas.
func start(conv: String) -> bool:
	if not data.has(conv):
		end()
		return false
	conversation = conv
	_go(String(data[conv].get("start", "")))
	return is_active()


func end() -> void:
	conversation = ""
	node_id = ""
	_text_key = ""


func is_active() -> bool:
	return node_id != ""


func _node() -> Dictionary:
	if not is_active():
		return {}
	return data[conversation].nodes.get(node_id, {})


func _go(id: String) -> void:
	if id == "" or not data[conversation].nodes.has(id):
		end()
		return
	node_id = id
	var text: Variant = _node().get("text", "")
	_text_key = String(text[_rng.randi_range(0, text.size() - 1)]) if text is Array else String(text)


func speaker() -> String:
	return String(_node().get("speaker", ""))


## La clé de la réplique en cours (la variante tirée en arrivant sur la réplique).
func text() -> String:
	return _text_key


## Les clés des réponses possibles (vide : on avance simplement).
func choices() -> Array:
	var out := []
	for c in _node().get("choices", []):
		out.append(String(c.get("text", "")))
	return out


## Passe à la réplique suivante (réplique sans choix). Renvoie l'action de la réplique quittée.
func advance() -> String:
	var node := _node()
	if node.is_empty() or not choices().is_empty():
		return ""
	var action := String(node.get("action", ""))
	_go(String(node.get("next", "")))
	return action


## Choisit la réponse `i`. Renvoie son action (vide s'il n'y en a pas).
func choose(i: int) -> String:
	var options: Array = _node().get("choices", [])
	if i < 0 or i >= options.size():
		return ""
	var c: Dictionary = options[i]
	_go(String(c.get("next", "")))
	return String(c.get("action", ""))


## Les erreurs d'un fichier de dialogues (répliques manquantes, textes vides…). Vide = valide.
static func errors(p_data: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for conv in p_data:
		var c: Dictionary = p_data[conv]
		var nodes: Dictionary = c.get("nodes", {})
		if not nodes.has(String(c.get("start", ""))):
			out.append("%s : réplique de départ absente" % conv)
		for id in nodes:
			var n: Dictionary = nodes[id]
			var text: Variant = n.get("text", "")
			if (text is Array and text.is_empty()) or (text is String and text == ""):
				out.append("%s/%s : pas de texte" % [conv, id])
			var nexts := [String(n.get("next", ""))]
			for ch in n.get("choices", []):
				nexts.append(String(ch.get("next", "")))
				if String(ch.get("text", "")) == "":
					out.append("%s/%s : réponse sans texte" % [conv, id])
			for nx in nexts:
				if nx != "" and not nodes.has(nx):
					out.append("%s/%s : suite « %s » absente" % [conv, id, nx])
	return out


## Toutes les clés de traduction utilisées (pour vérifier qu'elles sont toutes traduites).
static func text_keys(p_data: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for conv in p_data:
		for id in p_data[conv].get("nodes", {}):
			var n: Dictionary = p_data[conv].nodes[id]
			out.append(String(n.get("speaker", "")))
			var text: Variant = n.get("text", "")
			for k in (text if text is Array else [text]):
				out.append(String(k))
			for ch in n.get("choices", []):
				out.append(String(ch.get("text", "")))
	return out
