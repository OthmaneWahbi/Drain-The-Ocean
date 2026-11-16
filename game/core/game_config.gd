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
