class_name ToolbarLogic
extends RefCounted
## La barre de 6 cases (5 avant 0.1.10) en main (M-27, M-18), sans aucun affichage.
##
## Chaque case contient un outil possédé ("seau", "rateau", "tuyaux"…), un tas de matériau
## porté ("sel", "mineraux"…) ou rien (""). Une case vide = les mains nues. On choisit avec 1-5
## ou la molette ; `swap()` sert au menu qui réorganise la barre. Ce qui va dans les cases
## (quel outil est possédé, quel matériau est porté) est décidé par GameState.

var slots: PackedStringArray
var selected: int = 0


func _init(p_slots: PackedStringArray = PackedStringArray(["seau", "", "", "", "", ""])) -> void:
	slots = p_slots.duplicate()


func current() -> String:
	return slots[selected] if selected >= 0 and selected < slots.size() else ""


## Choisit la case `index` si elle est utilisable. Renvoie vrai si ça a changé quelque chose.
func select(index: int, owned: Callable) -> bool:
	if index < 0 or index >= slots.size() or index == selected:
		return false
	if not is_available(index, owned):
		return false
	selected = index
	return true


## Case suivante (+1) ou précédente (-1) utilisable, en faisant le tour.
func cycle(direction: int, owned: Callable) -> bool:
	var n := slots.size()
	for step in range(1, n):
		var i := posmod(selected + direction * step, n)
		if is_available(i, owned):
			selected = i
			return true
	return false


## Une case vide (les mains) est toujours utilisable ; un outil seulement s'il est possédé.
func is_available(index: int, owned: Callable) -> bool:
	if index < 0 or index >= slots.size():
		return false
	var tool := slots[index]
	return tool == "" or bool(owned.call(tool))


## Si la case tenue n'est plus utilisable (nouvelle partie…), on revient à la première case.
func ensure_valid(owned: Callable) -> void:
	if not is_available(selected, owned):
		selected = 0


func index_of(name: String) -> int:
	return slots.find(name) if name != "" else -1


## Première case vide, ou -1.
func first_free() -> int:
	return slots.find("")


## Range `name` dans la première case vide. Renvoie la case, ou -1 s'il n'y a plus de place.
func put(name: String) -> int:
	var i := index_of(name)
	if i >= 0:
		return i
	i = first_free()
	if i >= 0:
		slots[i] = name
	return i


## Vide la case qui contient `name` (s'il y en a une).
func clear(name: String) -> void:
	var i := index_of(name)
	if i >= 0:
		slots[i] = ""


## Échange deux cases. La sélection suit ce qu'on tenait. Renvoie faux si un indice est mauvais.
func swap(a: int, b: int) -> bool:
	if a < 0 or b < 0 or a >= slots.size() or b >= slots.size() or a == b:
		return false
	var tmp := slots[a]
	slots[a] = slots[b]
	slots[b] = tmp
	if selected == a:
		selected = b
	elif selected == b:
		selected = a
	return true
