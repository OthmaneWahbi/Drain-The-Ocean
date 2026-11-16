class_name Economy
extends RefCounted
## Outils pour manipuler des « paquets » de ressources : {"sel": 15, "coquillages": 2}.
## Troc direct (Q-07) : un prix est simplement un paquet de ressources.

const RESOURCES: Array[String] = ["sel", "mineraux", "mineraux_rares", "coquillages", "perles"]


static func empty_stock() -> Dictionary:
	var d := {}
	for r in RESOURCES:
		d[r] = 0
	return d


static func count(items: Dictionary) -> int:
	var total := 0
	for k in items:
		total += int(items[k])
	return total


static func can_afford(stock: Dictionary, price: Dictionary) -> bool:
	for k in price:
		if int(stock.get(String(k), 0)) < int(price[k]):
			return false
	return true


## Retire le prix du stock. Ne fait rien et renvoie faux si le stock ne suffit pas.
static func pay(stock: Dictionary, price: Dictionary) -> bool:
	if not can_afford(stock, price):
		return false
	for k in price:
		var key := String(k)
		stock[key] = int(stock.get(key, 0)) - int(price[k])
	return true


static func add(target: Dictionary, items: Dictionary) -> void:
	for k in items:
		var key := String(k)
		target[key] = int(target.get(key, 0)) + int(items[k])


static func sum(prices: Array) -> Dictionary:
	var total := {}
	for p: Dictionary in prices:
		add(total, p)
	return total


## Nettoie un paquet lu depuis une sauvegarde (clés texte, valeurs entières positives).
static func sanitize(raw: Variant) -> Dictionary:
	var out := {}
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	for k in raw:
		var v := int(raw[k])
		if v > 0:
			out[String(k)] = v
	return out
