class_name StationLogic
extends RefCounted
## Un objet posé qui contient des portions qu'on prend avec E (N-02) :
## - la bâche de condensation produit une gorgée d'eau douce toutes les `period_s` secondes,
##   jusqu'à `capacity` ;
## - la caisse de rations ne produit rien (`period_s` = 0) : quand elle est vide, elle disparaît.

var amount: int
var capacity: int
var period_s: float
var _timer: float = 0.0


func _init(start_amount: int = 0, max_amount: int = 1, period: float = 0.0) -> void:
	amount = start_amount
	capacity = max_amount
	period_s = period


func produces() -> bool:
	return period_s > 0.0


func step(delta: float) -> void:
	if not produces() or amount >= capacity:
		_timer = 0.0
		return
	_timer += delta
	while _timer >= period_s and amount < capacity:
		_timer -= period_s
		amount += 1


## Prend une portion. Renvoie faux s'il n'y en a pas.
func take_one() -> bool:
	if amount <= 0:
		return false
	amount -= 1
	return true


## Vide et ne produisant rien : à retirer du monde.
func is_spent() -> bool:
	return amount <= 0 and not produces()


func to_dict() -> Dictionary:
	return {"amount": amount, "timer": _timer}


func load_dict(data: Dictionary) -> void:
	amount = clampi(int(data.get("amount", amount)), 0, capacity)
	_timer = maxf(float(data.get("timer", 0.0)), 0.0)
