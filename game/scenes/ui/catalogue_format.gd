class_name CatalogueFormat
extends RefCounted
## Mise en forme des paquets de ressources pour l'affichage.


## « 15 sel, 2 coquillages ». Avec `show_zero`, liste toutes les ressources.
static func format_items(items: Dictionary, show_zero := false) -> String:
	var parts := []
	for r in Economy.RESOURCES:
		var n := int(items.get(r, 0))
		if n > 0 or show_zero:
			parts.append("%d %s" % [n, TranslationServer.translate("RES_" + r.to_upper())])
	return ", ".join(parts) if not parts.is_empty() else "—"
