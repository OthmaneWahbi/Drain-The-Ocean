class_name CatalogDatabase
extends Resource
## La liste des articles du catalogue.

@export var items: Array[CatalogItem] = []


func find(id: StringName) -> CatalogItem:
	for item in items:
		if item.id == id:
			return item
	return null
