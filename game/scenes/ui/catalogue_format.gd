class_name CatalogueFormat
extends RefCounted
## Mise en forme des paquets de ressources pour l'affichage.


## « 15 sel, 2 coquillages ». Avec `show_zero`, liste toutes les ressources.
static func format_items(items: Dictionary, show_zero := false) -> String:
	var parts := []
	for r in Economy.RESOURCES:
		var n := int(items.get(r, 0))
		# 0.1.22 (Q-29) : la fleur de sel et le sel rose ne s'affichent pas tant qu'on n'en a pas.
		if n > 0 or (show_zero and not Economy.FOUND_ONLY.has(r)):
			parts.append("%d %s" % [n, TranslationServer.translate("RES_" + r.to_upper())])
	return ", ".join(parts) if not parts.is_empty() else "—"


## Regroupe les articles identiques du panier, dans l'ordre d'ajout : [["bache", 2], ["grand_seau", 1]].
static func group_cart(ids: Array) -> Array:
	var groups := []
	var index := {}
	for id in ids:
		var key := String(id)
		if index.has(key):
			groups[index[key]][1] += 1
		else:
			index[key] = groups.size()
			groups.append([key, 1])
	return groups


## « Bâche de séchage ×2, Grand seau ». `name_of` donne le nom affiché d'un identifiant.
static func format_cart(ids: Array, name_of: Callable) -> String:
	var parts := []
	for g in group_cart(ids):
		var label: String = name_of.call(g[0])
		parts.append(label if g[1] == 1 else "%s ×%d" % [label, g[1]])
	return ", ".join(parts)
