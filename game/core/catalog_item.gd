class_name CatalogItem
extends Resource
## Un article du catalogue de l'agence (PRD §9). Les valeurs vivent dans data/catalog.tres.

## Ce que fait l'objet une fois la caisse ouverte.
## (Ne jamais réordonner : le fichier de données stocke ces valeurs par numéro.)
enum Effect { DRYING_ZONE, BUCKET_CAPACITY, DECOR, BUCKET_COUNT, CARRY_CAPACITY, WALK_SPEED, RAKE }

@export var id: StringName
@export var name_key: String
@export var desc_key: String
@export var tier: int = 1
## Prix en troc direct : {"sel": 15}.
@export var price: Dictionary = {}
@export var effect: Effect = Effect.DECOR
## Paramètre de l'effet : type de zone, contenance du seau…
@export var effect_param: String = ""
@export var effect_value: float = 0.0
## Une seule fois par partie (ex. le grand seau).
@export var unique: bool = false
