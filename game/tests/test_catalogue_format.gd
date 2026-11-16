extends TestCase
## Affichage du panier : les articles identiques sont regroupés (« Nom ×N »).


func test_cart_groups_identical_items_in_order() -> void:
	var names := {"bache": "Bâche", "grand_seau": "Grand seau"}
	var text := CatalogueFormat.format_cart(["bache", "grand_seau", "bache", "bache"], func(i): return names[i])
	assert_eq(text, "Bâche ×3, Grand seau")


func test_single_item_has_no_multiplier() -> void:
	assert_eq(CatalogueFormat.format_cart(["bache"], func(i): return "Bâche"), "Bâche")
