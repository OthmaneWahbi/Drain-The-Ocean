class_name GameConfig
extends Resource
## Valeurs d'équilibrage globales. Toutes les valeurs vivent dans data/game_config.tres,
## jamais en dur dans le code (règle du CLAUDE.md).

## Volume total de l'océan, en litres (PRD §8.1, N-06 : 10^18 à 10^19 L, provisoire).
@export var total_ocean_volume_l: float = 2.8e18
## Part du volume restant sous laquelle le drain devient visible (PRD §11 : 5 %).
@export_range(0.0, 1.0) var drain_threshold_ratio: float = 0.05
## Intervalle de sauvegarde automatique en secondes (M-77).
@export var autosave_interval_s: float = 120.0
## Durée d'une journée de jeu en secondes réelles (M-40).
@export var day_length_s: float = 1200.0
## Capacité du seau de départ en litres (M-30).
@export var starting_bucket_capacity_l: float = 10.0
## Nombre d'emplacements de sauvegarde (M-71).
@export var save_slot_count: int = 3
## Temps pour remplir le seau en le maintenant dans l'eau, en secondes (M-29, améliorable).
@export var bucket_fill_time_s: float = 1.0
## Niveau de la mer (hauteur du plan d'eau), en mètres.
@export var sea_level_y: float = 0.0
## Multiplicateur d'évaporation la nuit (M-40).
@export var night_evaporation_factor: float = 0.3
## Heure de départ d'une nouvelle partie.
@export var start_hour: float = 7.0

@export_group("Zones de séchage")
## Cuvette rocheuse de départ (M-36, M-37).
@export var basin_capacity_l: float = 40.0
@export var basin_dry_time_s: float = 45.0
@export var basin_position: Vector3 = Vector3(-6, 0.5, 2)
## Bâche de séchage (premier achat).
@export var tarp_capacity_l: float = 60.0
@export var tarp_dry_time_s: float = 45.0

@export_group("Ressources")
## Chances de tirage par 10 L évaporés (M-43).
@export var mineral_chance: float = 0.10
@export var rare_mineral_chance: float = 0.005
## Chance de remonter un coquillage à chaque puisage (M-43).
@export var shell_chance_per_scoop: float = 0.03
## Chance qu'un coquillage contienne une perle (N-07).
@export var pearl_chance_per_shell: float = 0.02
## Nombre d'objets portés à la main au maximum (M-28 : à la main au début).
@export var hand_carry_capacity: int = 10

@export_group("Livraison")
## Centre de la zone où les caisses sont larguées.
@export var delivery_center: Vector3 = Vector3(4, 0.5, 9)
## Durée totale entre la commande et l'atterrissage de la caisse (M-51).
@export var delivery_time_s: float = 5.0
