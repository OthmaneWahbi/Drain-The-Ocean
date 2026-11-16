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
@export var basin_position: Vector3 = Vector3(-5.5, 0.5, 2.5)
## Position de départ de la palette de dépôt (on peut la déplacer ensuite).
@export var depot_position: Vector3 = Vector3(8.5, 0.5, 4.5)
## Bâche de séchage (premier achat).
@export var tarp_capacity_l: float = 60.0
@export var tarp_dry_time_s: float = 45.0
## Bassin en bois (T2) : grande zone de séchage.
@export var wood_basin_capacity_l: float = 200.0
@export var wood_basin_dry_time_s: float = 45.0
## Miroir solaire (T2) : +50 % d'évaporation pour chaque zone à moins de `mirror_radius_m`.
@export var mirror_bonus: float = 0.5
@export var mirror_radius_m: float = 6.0

@export_group("Ressources")
## Litres à évaporer pour obtenir 1 sel (réglé pour un premier achat vers 1 min 30).
@export var liters_per_salt: float = 4.0
## Unités ramassées par clic sans râteau (M-39 : récolte au clic, puis râteau).
@export var manual_harvest_per_click: int = 3
## Chances de tirage à chaque sel produit (M-43).
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

@export_group("Océan visible")
## Surface du bassin, en m² : sert à convertir le volume retiré en baisse du niveau (PRD §8.3).
## Rayon ~3 000 km (N-06) : π × (3 × 10⁶)² ≈ 2,8 × 10¹³ m², soit ~100 m de profondeur moyenne.
@export var ocean_surface_m2: float = 2.83e13
## Debug (F7 maintenu) : part du volume retirée par seconde, pour voir l'eau baisser (M1).
@export var debug_drain_ratio_per_s: float = 0.002

@export_group("Personnage")
@export var walk_speed: float = 4.5
@export var sprint_speed: float = 7.0
@export var swim_speed: float = 2.6
## Profondeur des pieds sous la surface à partir de laquelle on nage (au lieu de marcher).
@export var swim_depth_m: float = 1.2
## Profondeur des pieds quand on flotte : la tête dépasse de l'eau.
@export var float_depth_m: float = 1.35
## Vitesse de montée pour se hisser sur le rivage depuis l'eau.
@export var swim_climb_velocity: float = 4.0
## Endurance (N-05) : secondes de course, secondes de nage, temps pour remonter à fond à l'arrêt sur terre.
@export var stamina_run_s: float = 10.0
@export var stamina_swim_s: float = 30.0
@export var stamina_regen_s: float = 5.0
## Après épuisement, on ne peut plus courir avant d'être remonté à cette part (style BotW).
@export var stamina_exhausted_ratio: float = 0.25
## Noyade (N-04) : durée du fondu au noir, puis retour sur la plage.
@export var drown_fade_s: float = 0.8

## La vraie fin (M-04, touche de debug F4) : durée de chaque phase (EndingLogic), en secondes,
## où est la bonde, et de combien l'eau descend (bonde visible, puis océan vidé).
@export var ending_durations: Dictionary = {"drain": 4.0, "gurgle": 5.0, "walk": 6.0, "plane": 8.0, "time": 5.0, "credits": 12.0}
@export var drain_position: Vector3 = Vector3(0, -3.0, -70)
@export var ending_reveal_drop_m: float = 2.2
@export var ending_empty_drop_m: float = 4.0
@export var respawn_position: Vector3 = Vector3(0, 1, 6)

@export_group("Survie légère")
## Secondes pour que la faim (puis la soif) passe de pleine à vide (M-26, N-03).
@export var food_empty_s: float = 900.0
@export var water_empty_s: float = 600.0
## À zéro : l'endurance max perd jusqu'à cette part par besoin, en `starving_penalty_time_s` secondes.
@export var starving_penalty_max: float = 0.3
@export var starving_penalty_time_s: float = 120.0
## Noix de coco (N-02) : ce qu'elle nourrit et désaltère ; où elles tombent sous les palmiers.
@export var coconut_food: float = 0.35
@export var coconut_water: float = 0.25
@export var coconut_spots: PackedVector3Array = PackedVector3Array()
## Rations : portions par caisse et ce que chacune nourrit.
@export var ration_portions: int = 5
@export var ration_food: float = 0.6
## Bâche de condensation : une gorgée toutes les `condenser_period_s` s, au plus `condenser_capacity`.
@export var condenser_period_s: float = 90.0
@export var condenser_capacity: int = 3
@export var condenser_water: float = 0.5

@export_group("Plage")
## Coquillages déposés sur la plage chaque matin (M-44), dans un anneau autour du centre.
@export var shells_per_morning: int = 5
@export var beach_radius_min: float = 16.5
@export var beach_radius_max: float = 19.3

@export_group("Placement")
## Taille d'une case de la grille de placement, en mètres.
@export var grid_cell_m: float = 1.0
## On ne pose rien au-delà de ce rayon (le sable sec de l'île fait 20 m de rayon).
@export var build_radius_m: float = 19.5
## Rayon d'emprise de chaque type d'objet déplaçable (tas de sel compris pour les zones).
@export var footprints: Dictionary = {
	"cuvette": 3.0, "bache": 3.0, "bassin_bois": 4.0,
	"condenseur": 1.1, "rations": 0.5, "miroir": 0.7, "bateau_en_bouteille": 0.4, "palette": 2.0,
	"caisse": 0.6, "catalogue_papier": 0.4, "toboggan": 1.0, "flamant": 0.5, "coquillage": 0.25, "pompe_bras": 0.8, "moulin_pompe": 0.8,
}
## Le tas de sel d'une zone occupe sa propre case, à ce nombre de cases du centre (dans l'emprise).
@export var pile_offset_cells: Dictionary = {"cuvette": 2, "bache": 2, "bassin_bois": 3}
## Un tas par matériau, côte à côte : décalage en cases (perpendiculaire) de chaque tas.
@export var pile_slots: Dictionary = {"sel": 0, "mineraux": 1, "mineraux_rares": -1}
## Les noix de coco au pied des palmiers bloquent aussi leur case (rayon en mètres).
@export var coconut_radius_m: float = 0.3
## Types qui se posent au bord de l'eau : distance minimale de leur centre au milieu de l'île.
@export var shore_only_kinds: Dictionary = {"pompe_bras": 15.5, "moulin_pompe": 15.5}

@export_group("Jalons")
## Jalons comparatifs (M-70), du plus petit au plus grand. Les trois premiers sont ceux de la démo.
## `icon` : le pictogramme dessiné par l'interface (baignoire, piscine gonflable, piscine…).
@export var milestones: Array = [
	{"id": "baignoire", "icon": "baignoire", "liters": 150.0, "reward": {"sel": 10}},
	{"id": "piscine_gonflable", "icon": "piscine_gonflable", "liters": 2000.0, "reward": {"perles": 1}},
	{"id": "piscine", "icon": "piscine", "liters": 30000.0, "reward": {"mineraux_rares": 5}},
	{"id": "piscine_olympique", "icon": "piscine_olympique", "liters": 2500000.0, "reward": {"perles": 3}},
]

@export_group("Toboggan à sacs")
## Une zone dont le bord est à moins de cette distance du toboggan y verse son sel toute seule.
@export var slide_reach_m: float = 3.0
## Intervalle entre deux envois automatiques à la palette (s).
@export var slide_period_s: float = 8.0

@export_group("Téléphone")
## Chance, chaque matin, que le téléphone sonne pour une offre spéciale (M-54).
@export var offer_chance_per_day: float = 0.7
## Prix de l'offre du jour : chaque quantité est multipliée par ce facteur.
@export var offer_price_factor: float = 0.5
## Durée de la musique d'attente du premier appel, avant que la caisse tombe (s).
@export var hold_music_s: float = 6.0
## Ce que contient la caisse du premier appel.
@export var tutorial_crate_item: String = "catalogue_papier"

@export_group("Barre d'outils")
## Les 5 cases de la barre au début d'une partie (M-27) : "" = case vide (les mains nues).
## Les outils achetés et les matériaux portés prennent ensuite les cases vides.
@export var toolbar_slots: PackedStringArray = PackedStringArray(["seau", "", "", "", ""])

@export_group("Pompes et tuyaux")
## Litres par seconde quand on actionne la pompe (le seau fait ~5 L/s en comptant les allers-retours).
@export var pump_rates_lps: Dictionary = {"pompe_bras": 20.0, "moulin_pompe": 10.0}
## Pompes qui tournent toutes seules (sans le joueur).
@export var auto_pump_kinds: PackedStringArray = PackedStringArray(["moulin_pompe"])
## Litres pompés tout seuls avant l'écran de fin de démo (M-05).
@export var demo_end_auto_pumped_l: float = 200.0
## Quand une commande fait plusieurs caisses, les avions passent à cet intervalle (secondes).
@export var crate_stagger_s: float = 1.2
## Hauteur du sable de l'île (là où se posent les objets et les tuyaux du niveau 0).
@export var ground_y: float = 0.5
## Les tuyaux se posent à la main, une pièce par case de la grille (1 m), jusqu'à ce niveau de hauteur.
@export var pipe_max_level: int = 4
## Emprise d'une pièce de tuyau au sol (pour que rien ne se pose dessus).
@export var pipe_radius_m: float = 0.2
## Une pièce de tuyau dont le centre est à moins de ce rayon d'une zone y verse son eau.
@export var inlet_radius: Dictionary = {"cuvette": 1.5, "bache": 1.5, "bassin_bois": 2.5}

@export_group("Placement (suite)")
## Le joueur occupe ce rayon : on ne pose rien et rien n'apparaît sur lui.
@export var player_radius_m: float = 0.5
## Anti-blocage : après combien de secondes immobile (en voulant avancer) on vérifie si on est
## coincé, et jusqu'où on cherche une place libre (au-delà : retour sur la plage).
@export var unstuck_check_after_s: float = 1.0
@export var unstuck_step_m: float = 0.5
@export var unstuck_search_m: float = 4.0
## Angle d'un appui sur R pendant un déplacement, en degrés.
@export var rotation_step_deg: float = 90.0
## Obstacles fixes : (x, z, rayon) — téléphone, palmiers, jauge, rochers.
@export var fixed_obstacles: PackedVector3Array = PackedVector3Array()
