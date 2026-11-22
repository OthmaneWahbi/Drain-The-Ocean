# Crédits des assets

## Modèles 3D — `models/cc0/` (CC0 1.0, domaine public)

| Fichier | Origine |
|---|---|
| `tree_palm.glb`, `rock_large.glb`, `rock_small.glb`, `rock_tall.glb`, `bush.glb`, `bush_large.glb`, `log.glb`, `flower_red.glb` | Kenney, *Nature Kit* (https://kenney.nl/assets/nature-kit), CC0 1.0 |
| `crystal_rock.glb` | Kenney, *Space Kit* (https://kenney.nl/assets/space-kit), CC0 1.0 |
| `fish.glb` (+ `fish_colormap.png`) | Kenney, *Food Kit* (https://kenney.nl/assets/food-kit), CC0 1.0 |
| `mini_male_a.glb`, `mini_male_d.glb` (+ leurs `_colormap.png`) | Kenney, *Mini Characters* (https://kenney.nl/assets/mini-characters), CC0 1.0 |
| `kaykit_bucket_empty.glb`, `kaykit_pallet.glb` (+ leurs `_hexagons_medieval.png`) | Kay Lousberg, *KayKit Medieval Hexagon Pack 1.0* (https://kaylousberg.itch.io, dépôt GitHub `KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0`), CC0 1.0 — convertis de glTF en GLB (texture incluse), sans autre retouche |
| `space_pipe_straight.glb`, `space_pipe_corner.glb`, `space_pipe_split.glb`, `space_pipe_cross.glb` | Kenney, *Space Kit 2.0* (https://kenney.nl/assets/space-kit), CC0 1.0, via le paquet npm `@anabis/kenney-space-kit-mirror` (copie non modifiée) |
| `quaternius_farm_windmill.glb` (0.1.10) | Quaternius, *Farm Buildings* (https://quaternius.com), CC0 1.0, via le dépôt GitHub `chibifire-stages/quaternius-stage` (format USD) — converti en GLB à aplats de couleur par `tools/models/usd2glb.py`, pales gardées dans un nœud à part |
| `kaykit_pallet_wood.glb`, `kaykit_gems_pile_small.glb` (+ leurs `_resource_bits_texture.png`) (0.1.10) | Kay Lousberg, *KayKit Resource Bits* (https://kaylousberg.itch.io), CC0 1.0, via le dépôt GitHub `GeorgeQLe/assets-kaykit-3d-props` — convertis de glTF en GLB (texture incluse) par `tools/models/embed.py` |
| `kaykit_wheelbarrow.glb` (+ `_hexagons_medieval.png`) (0.1.10) | Kay Lousberg, *KayKit Medieval Hexagon Pack 1.0.1*, CC0 1.0, via le dépôt GitHub `GeorgeQLe/assets-kaykit-3d-environments` — converti de glTF en GLB |
| `kenney_pirate_crate.glb`, `kenney_tent_canvas.glb`, `kenney_snow_pile.glb`, `kenney_resource_stone_large.glb`, `kenney_mussel.glb`, `kenney_mussel_open.glb` (+ leurs `_colormap.png`) (0.1.10) | Kenney, *Pirate Kit*, *Survival Kit*, *Holiday Kit*, *Food Kit* (https://kenney.nl), CC0 1.0, via le dépôt GitHub `shorepine/kenney` (copie de la bibliothèque, LICENSE de Kenney incluse) — textures incluses dans le GLB par `tools/models/embed.py` |
| `crab.glb`, `crystal.glb` (+ `crystal_Atlas.png`), `gem_pink.glb` (+ `gem_pink_Atlas_Pirate.png`) | Quaternius (https://quaternius.com), via Poly Pizza, CC0 1.0 |

Copies récupérées via le paquet npm `@netforge/asset-library-files` (qui liste l'origine et la licence de chaque pack dans son fichier NOTICE), puis décompressées (meshopt retiré) pour Godot. Les couleurs sont retouchées au chargement (`scenes/world/models.gd`). CC0 ne demande aucun crédit : on crédite quand même.

Depuis 0.1.10, le moulin-pompe, la caisse (avec un couvercle ajouté par code), la toile du condenseur, la brouette du catalogue, la palette de dépôt et une partie des tas (sel, minéraux, minéraux rares, coquillages) viennent de ces modèles CC0. Les miroirs GitHub sont tenus par des tiers : à comparer à la page d'origine avant une sortie publique.

Fabriqués par code (pas d'asset, rien de CC0 ne convenait) : la cabine téléphonique, les noix de coco, et depuis 0.1.4 (`scenes/world/props.gd`) les tas de ressources, coquillages, perles, étoiles de mer, le parachute, le biplan, les zones de séchage (dont la cuvette et les bacs à tas, 0.1.10), la pompe à bras, la pelle (0.1.10), le toboggan, le miroir, la jauge, le râteau, le condenseur, les rations, les mouettes, les coraux et les algues. Les fichiers `.png` à côté des `.glb` sont les textures que Godot extrait des modèles.

## Polices — `fonts/`

| Fichier | Police | Licence |
|---|---|---|
| `DynaPuff-Variable.ttf` | DynaPuff, The DynaPuff Project Authors | SIL Open Font License 1.1 (`OFL-DynaPuff.txt`) |
| `Nunito-Variable.ttf` | Nunito, The Nunito Project Authors | SIL Open Font License 1.1 (`OFL-Nunito.txt`) |
| `GochiHand-Regular.ttf` | Gochi Hand, Huerta Tipográfica | SIL Open Font License 1.1 (`OFL-GochiHand.txt`) |
| `Symboles-MPLUSRounded1c.ttf` | M PLUS Rounded 1c, The Rounded M+ Project Authors (sous-ensemble : symboles ♪ ▮ ★ ✓ → …) | SIL Open Font License 1.1 (`OFL-MPLUSRounded1c.txt`) |

Récupérées depuis le dépôt `google/fonts` (2026-11-21). Le sous-ensemble de M PLUS Rounded 1c est fait avec `pyftsubset` (fontTools). Les fichiers `police_*.tres` choisissent la graisse de chaque police.
