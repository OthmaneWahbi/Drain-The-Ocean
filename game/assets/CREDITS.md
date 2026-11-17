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
| `crab.glb`, `crystal.glb` (+ `crystal_Atlas.png`), `gem_pink.glb` (+ `gem_pink_Atlas_Pirate.png`) | Quaternius (https://quaternius.com), via Poly Pizza, CC0 1.0 |

Copies récupérées via le paquet npm `@netforge/asset-library-files` (qui liste l'origine et la licence de chaque pack dans son fichier NOTICE), puis décompressées (meshopt retiré) pour Godot. Les couleurs sont retouchées au chargement (`scenes/world/models.gd`). CC0 ne demande aucun crédit : on crédite quand même.

Fabriqués par code (pas d'asset, rien de CC0 ne convenait) : la cabine téléphonique, les noix de coco, et depuis 0.1.4 (`scenes/world/props.gd`) les tas de ressources, coquillages, perles, étoiles de mer, la caisse et son parachute, le biplan, les zones de séchage, la pompe, le moulin, le toboggan, le miroir, la jauge, le râteau, le condenseur, les rations, les mouettes, les coraux et les algues. Les fichiers `.png` à côté des `.glb` sont les textures que Godot extrait des modèles.

## Polices — `fonts/`

| Fichier | Police | Licence |
|---|---|---|
| `LilitaOne-Regular.ttf` | Lilita One, Juan Montoreano | SIL Open Font License 1.1 (`OFL-LilitaOne.txt`) |
| `Fredoka-Medium.ttf`, `Fredoka-Bold.ttf` | Fredoka, The Fredoka Project Authors | SIL Open Font License 1.1 (`OFL-Fredoka.txt`) |
| `PermanentMarker-Regular.ttf` | Permanent Marker, Font Diner | Apache 2.0 (`Apache-PermanentMarker.txt`) |

Récupérées via les paquets npm `@fontsource/*` (sous-ensemble latin), converties de WOFF2 en TTF.
