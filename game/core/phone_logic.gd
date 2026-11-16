class_name PhoneLogic
extends RefCounted
## Le téléphone (PRD §9, M-48, M-54), sans aucun affichage.
##  - Nouvelle partie : il sonne pour le premier appel, un tutoriel muet. On décroche, on entend
##    la musique d'attente, et une caisse tombe avec le catalogue papier dedans.
##  - Ensuite, certains matins (`offer_chance`), il sonne pour une offre spéciale : un article
##    à prix réduit toute la journée. Un appel manqué, c'est une offre manquée.

enum Ring { NONE, TUTORIAL, OFFER }

var ringing: Ring = Ring.TUTORIAL
var tutorial_done: bool = false
## Offre du jour : id de l'article (vide = pas d'offre), jour où elle est valable, et l'offre
## proposée par la sonnerie en cours (elle ne devient valable qu'en décrochant).
var offer_item: String = ""
var offer_day: int = -1
var _pending_item: String = ""


func is_ringing() -> bool:
	return ringing != Ring.NONE


## On décroche. Renvoie la raison de l'appel (Ring.NONE si le téléphone ne sonnait pas).
func answer(day_index: int) -> Ring:
	var why := ringing
	ringing = Ring.NONE
	match why:
		Ring.TUTORIAL:
			tutorial_done = true
		Ring.OFFER:
			offer_item = _pending_item
			offer_day = day_index
	_pending_item = ""
	return why


## Un nouveau matin : peut-être une offre. `candidates` = ids des articles qu'on peut acheter.
## Renvoie vrai si le téléphone se met à sonner.
func on_new_morning(rng: RandomNumberGenerator, chance: float, candidates: Array) -> bool:
	if not tutorial_done:
		return false
	# Une sonnerie d'offre non décrochée s'arrête avec la nuit.
	if ringing == Ring.OFFER:
		ringing = Ring.NONE
		_pending_item = ""
	if candidates.is_empty() or rng.randf() >= chance:
		return false
	_pending_item = String(candidates[rng.randi_range(0, candidates.size() - 1)])
	ringing = Ring.OFFER
	return true


## Vrai si cet article est l'offre du jour (décrochée aujourd'hui).
func has_offer(item_id: String, day_index: int) -> bool:
	return offer_item != "" and offer_item == item_id and offer_day == day_index


func pending_offer() -> String:
	return _pending_item


## Prix réduit : chaque quantité est multipliée par `factor` (arrondi au supérieur, au moins 1).
static func discounted(price: Dictionary, factor: float) -> Dictionary:
	var out := {}
	for k in price:
		var n := int(price[k])
		out[k] = maxi(int(ceil(n * factor)), 1) if n > 0 else 0
	return out


func to_dict() -> Dictionary:
	return {"ringing": int(ringing), "tutorial_done": tutorial_done, "offer_item": offer_item, "offer_day": offer_day, "pending": _pending_item}


func load_dict(data: Dictionary) -> void:
	tutorial_done = bool(data.get("tutorial_done", true))  # vieille sauvegarde : tutoriel déjà vu
	ringing = clampi(int(data.get("ringing", 0)), 0, Ring.size() - 1) as Ring
	if tutorial_done and ringing == Ring.TUTORIAL:
		ringing = Ring.NONE
	offer_item = String(data.get("offer_item", ""))
	offer_day = int(data.get("offer_day", -1))
	_pending_item = String(data.get("pending", ""))
	if ringing == Ring.OFFER and _pending_item == "":
		ringing = Ring.NONE
