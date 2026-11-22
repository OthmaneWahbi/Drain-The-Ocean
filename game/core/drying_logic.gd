class_name DryingLogic
extends RefCounted
## Une zone de séchage (cuvette, bâche, bassin…), sans aucun affichage (PRD §6.3).
##
## Règle (interprétation de M-37) : l'évaporation est limitée par la SURFACE, pas par la quantité d'eau.
## Une zone vide son plein en `dry_time_s` secondes au soleil, quel que soit son remplissage.
## Donc une cuvette de 40 L sèche 40 L en 45 s : verser 4 seaux d'affilée sèche aussi vite qu'un seul.
## Tous les `liters_per_salt` litres évaporés, on obtient 1 sel et on tire au sort minéraux et minéraux rares.

var capacity_l: float
var dry_time_s: float
var liters_per_salt: float = 10.0
var mineral_chance: float = 0.10
var rare_mineral_chance: float = 0.005
## 0.1.22 : chance, par sel produit, d'une fleur de sel en plus (réglée par GameState selon le
## temps qu'il fait), et part des sels qui sortent roses (marais au fond de terre).
var flower_chance: float = 0.0
var rose_chance: float = 0.0
var water_l: float = 0.0
var deposit: Dictionary = {}  # ressource (String) -> quantité (int), en attente de récolte
var _evaporated_acc: float = 0.0


func _init(capacity: float = 40.0, dry_time: float = 45.0) -> void:
	capacity_l = capacity
	dry_time_s = dry_time


func free_space_l() -> float:
	return maxf(capacity_l - water_l, 0.0)


func fill_ratio() -> float:
	return water_l / capacity_l if capacity_l > 0.0 else 0.0


## Verse de l'eau. Renvoie ce qui a été accepté : une zone pleine refuse le reste (M-38).
func add_water(liters: float) -> float:
	var accepted := clampf(liters, 0.0, free_space_l())
	water_l += accepted
	return accepted


func evaporation_rate_lps() -> float:
	return capacity_l / dry_time_s


## 0.1.24 : secondes avant d'être sèche au rythme `multiplier` (INF si elle ne sèche pas).
func seconds_to_dry(multiplier: float) -> float:
	if water_l <= 0.0:
		return 0.0
	var rate := evaporation_rate_lps() * multiplier
	return water_l / rate if rate > 0.0 else INF


## Avance le temps. `multiplier` = 1 en plein jour, 0,3 la nuit (M-40), plus tard les miroirs solaires.
func step(delta: float, multiplier: float, rng: RandomNumberGenerator) -> void:
	if water_l <= 0.0 or delta <= 0.0:
		return
	var evaporated := minf(water_l, evaporation_rate_lps() * multiplier * delta)
	water_l -= evaporated
	_evaporated_acc += evaporated
	while _evaporated_acc >= liters_per_salt - 0.0001:
		_evaporated_acc -= liters_per_salt
		_add(&"sel_rose" if rose_chance > 0.0 and rng.randf() < rose_chance else &"sel", 1)
		if flower_chance > 0.0 and rng.randf() < flower_chance:
			_add(&"fleur_de_sel", 1)
		if rng.randf() < mineral_chance:
			_add(&"mineraux", 1)
		if rng.randf() < rare_mineral_chance:
			_add(&"mineraux_rares", 1)


func has_deposit() -> bool:
	return Economy.count(deposit) > 0


## Récupère tout le dépôt et vide la zone de ses ressources.
func take_deposit() -> Dictionary:
	var taken := deposit
	deposit = {}
	return taken


## Récupère au plus `n` unités (les plus rares d'abord : c'est plus gratifiant).
## `only` : ne prendre que ce matériau (un tas par matériau) ; vide = les plus rares d'abord.
func take_some(n: int, only: String = "") -> Dictionary:
	var taken := {}
	var order := Economy.RESOURCES.duplicate()
	order.reverse()
	if only != "":
		order = [only]
	for key in order:
		if n <= 0:
			break
		var have := int(deposit.get(key, 0))
		var take := mini(have, n)
		if take > 0:
			taken[key] = take
			n -= take
			if have - take > 0:
				deposit[key] = have - take
			else:
				deposit.erase(key)
	return taken


func _add(resource: StringName, amount: int) -> void:
	var key := String(resource)
	deposit[key] = int(deposit.get(key, 0)) + amount


func to_dict() -> Dictionary:
	return {"water_l": water_l, "deposit": deposit.duplicate(), "evaporated_acc": _evaporated_acc}


func load_dict(data: Dictionary) -> void:
	water_l = clampf(float(data.get("water_l", 0.0)), 0.0, capacity_l)
	deposit = Economy.sanitize(data.get("deposit", {}))
	_evaporated_acc = float(data.get("evaporated_acc", 0.0))
