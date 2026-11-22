class_name WeatherLogic
extends RefCounted
## Le temps qu'il fait (0.1.22, PRD §19.29), sans aucun affichage. Chaque matin, un temps est
## tiré au sort dans la table des données (GameConfig.weather_table) :
## id -> {weight, dry, thirst, wind, overcast, heat, rain}. Seuls `dry` (séchage) et `thirst`
## (soif) sont des règles ; le reste ne sert qu'à la vue (vent, ciel gris, chaleur, averse au loin).

const DEFAULT := "calme"


## Tire le temps de la journée. `avoid` : un temps qu'on évite de répéter (le temps de la veille
## n'est pas interdit, il compte juste moitié moins).
static func pick(table: Dictionary, rng: RandomNumberGenerator, avoid := "") -> String:
	var keys: Array = table.keys()
	keys.sort()
	var total := 0.0
	for k in keys:
		total += _weight(table, k, avoid)
	if total <= 0.0:
		return DEFAULT
	var roll := rng.randf() * total
	for k in keys:
		roll -= _weight(table, k, avoid)
		if roll < 0.0:
			return String(k)
	return String(keys[keys.size() - 1])


static func _weight(table: Dictionary, k: Variant, avoid: String) -> float:
	var w := float((table[k] as Dictionary).get("weight", 0.0))
	return w * 0.5 if String(k) == avoid else w


## Une valeur de la table (1 pour les multiplicateurs, 0 pour le reste, si absente).
static func value(table: Dictionary, weather: String, key: String) -> float:
	var row: Dictionary = table.get(weather, {})
	var fallback := 1.0 if key in ["dry", "thirst"] else 0.0
	return float(row.get(key, fallback))
