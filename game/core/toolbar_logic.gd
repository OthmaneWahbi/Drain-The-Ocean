class_name ToolbarLogic
extends RefCounted
## La barre d'outils de 5 cases (M-27, M-18), sans aucun affichage.
##
## Chaque case a un outil fixe ("seau", "mains", "rateau"…) ou est vide (""). Une case n'est
## utilisable que si l'outil est possédé (le râteau s'achète). On choisit avec 1-5 ou la molette ;
## la molette saute les cases vides ou pas encore achetées.

var slots: PackedStringArray
var selected: int = 0


func _init(p_slots: PackedStringArray = PackedStringArray(["seau", "mains", "rateau", "", ""])) -> void:
	slots = p_slots


func current() -> String:
	return slots[selected] if selected >= 0 and selected < slots.size() else ""


## Choisit la case `index` si son outil est disponible. Renvoie vrai si ça a changé quelque chose.
func select(index: int, owned: Callable) -> bool:
	if index < 0 or index >= slots.size() or index == selected:
		return false
	if not is_available(index, owned):
		return false
	selected = index
	return true


## Case suivante (+1) ou précédente (-1) disponible, en faisant le tour.
func cycle(direction: int, owned: Callable) -> bool:
	var n := slots.size()
	for step in range(1, n):
		var i := posmod(selected + direction * step, n)
		if is_available(i, owned):
			selected = i
			return true
	return false


func is_available(index: int, owned: Callable) -> bool:
	if index < 0 or index >= slots.size():
		return false
	var tool := slots[index]
	return tool != "" and bool(owned.call(tool))


## Si l'outil tenu n'est plus disponible (nouvelle partie…), on revient à la première case.
func ensure_valid(owned: Callable) -> void:
	if not is_available(selected, owned):
		selected = 0
