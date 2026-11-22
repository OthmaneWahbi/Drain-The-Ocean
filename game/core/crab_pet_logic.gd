class_name CrabPetLogic
extends RefCounted
## Le crabe de compagnie (0.1.19, PRD §19.25) : sa faim, son affection et ses accessoires.
## Logique pure, sans scène. Inspiré des animaux de Stardew Valley (jamais de punition : un crabe
## affamé boude, il ne meurt pas et ne part pas) et de Neko Atsume (des objets qui le rendent
## heureux). Les réglages viennent de GameConfig (groupe « Crabe de compagnie »).

## Ce qui s'est passé quand on a voulu le nourrir.
enum Feed { FED, FULL, NO_TREATS }
## Son humeur, lue par la vue pour choisir l'animation de repos et par l'invite.
enum Mood { HAPPY, CONTENT, HUNGRY, SLEEPY }

## 1 = repu, 0 = affamé.
var hunger: float = 1.0
## Points d'affection, de 0 à `affection_max` (affichés en cœurs).
var affection: float = 0.0
## Croquettes en réserve (on les achète par sachet).
var treats: int = 0
## Accessoires achetés : id -> true (« chapeau », « lunettes »).
var accessories: Dictionary = {}
## Dernier jour où une caresse a compté (une seule par jour donne de l'affection).
var last_petted_day: int = -1

var hunger_empty_s: float
var treat_food: float
var full_ratio: float
var hungry_ratio: float
var affection_max: float
var affection_per_feed: float
var affection_per_pet: float
var affection_decay_per_s: float
var gift_affection: float
var hearts_count: int


func _init(cfg: GameConfig = null) -> void:
	if cfg == null:
		cfg = GameConfig.new()
	hunger_empty_s = maxf(cfg.pet_hunger_empty_s, 1.0)
	treat_food = cfg.pet_treat_food
	full_ratio = cfg.pet_full_ratio
	hungry_ratio = cfg.pet_hungry_ratio
	affection_max = cfg.pet_affection_max
	affection_per_feed = cfg.pet_affection_per_feed
	affection_per_pet = cfg.pet_affection_per_pet
	affection_decay_per_s = cfg.pet_affection_decay_per_s
	gift_affection = cfg.pet_gift_affection
	hearts_count = maxi(cfg.pet_hearts, 1)
	treats = cfg.pet_starting_treats


## Le temps passe : il a faim petit à petit. Le ventre vide, il perd un peu d'affection
## (jamais en dessous de zéro, jamais d'autre conséquence).
func step(delta: float) -> void:
	# Seul le temps passé le ventre vide compte (même en un grand pas de temps).
	var starving := maxf(delta - hunger * hunger_empty_s, 0.0)
	hunger = maxf(hunger - delta / hunger_empty_s, 0.0)
	affection = maxf(affection - affection_decay_per_s * starving, 0.0)


## Lui donner une croquette. Repu, il refuse (et la croquette reste dans le sachet).
func feed() -> Feed:
	if hunger >= full_ratio:
		return Feed.FULL
	if treats <= 0:
		return Feed.NO_TREATS
	treats -= 1
	hunger = minf(hunger + treat_food, 1.0)
	_add_affection(affection_per_feed)
	return Feed.FED


## Vrai s'il prendrait une croquette maintenant.
func wants_food() -> bool:
	return hunger < full_ratio


## Une caresse. Elle fait toujours plaisir, mais seule la première du jour compte en affection.
## Renvoie vrai si elle a compté.
func pet(day_index: int) -> bool:
	if day_index == last_petted_day:
		return false
	last_petted_day = day_index
	_add_affection(affection_per_pet)
	return true


func _add_affection(points: float) -> void:
	affection = clampf(affection + points, 0.0, affection_max)


## Cœurs pleins (0 à `hearts_count`).
func hearts() -> int:
	return clampi(int(floor(affection / affection_max * hearts_count + 1e-6)), 0, hearts_count)


func mood(is_night: bool) -> Mood:
	if is_night:
		return Mood.SLEEPY
	if hunger < hungry_ratio:
		return Mood.HUNGRY
	if hearts() >= hearts_count - 1:
		return Mood.HAPPY
	return Mood.CONTENT


## Chaque matin, un crabe qui vous aime (et qui a mangé) rapporte un coquillage.
func brings_gift() -> bool:
	return affection >= gift_affection and hunger >= hungry_ratio


func has_accessory(id: String) -> bool:
	return accessories.get(id, false)


func give_accessory(id: String) -> void:
	accessories[id] = true


func add_treats(n: int) -> void:
	treats = maxi(treats + n, 0)


func to_dict() -> Dictionary:
	return {"hunger": hunger, "affection": affection, "treats": treats, "accessories": accessories.keys(), "last_petted_day": last_petted_day}


func load_dict(data: Dictionary) -> void:
	if data.is_empty():
		return  # vieille sauvegarde : un crabe neuf, avec ses croquettes de départ
	hunger = clampf(float(data.get("hunger", 1.0)), 0.0, 1.0)
	affection = clampf(float(data.get("affection", 0.0)), 0.0, affection_max)
	treats = maxi(int(data.get("treats", 0)), 0)
	last_petted_day = int(data.get("last_petted_day", -1))
	accessories = {}
	for a in data.get("accessories", []):
		accessories[String(a)] = true
