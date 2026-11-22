# Drain the Ocean

Jeu vidéo Godot 4 (version principale : PC Windows).

Un naufragé, une île, un téléphone rouge, un seau… et un océan entier à vider.

- Spécification complète : [`docs/PRD.md`](docs/PRD.md)
- Projet Godot : [`game/`](game) (Godot 4.7.2). Ouvrir `game/project.godot` dans l'éditeur.
- Journal des décisions, modifications et tests : [`HANDOFF.md`](HANDOFF.md)

## Revenir à une ancienne version

Chaque version du jeu a une **étiquette** git `vX.Y.Z` (et une « release » GitHub), posée automatiquement à chaque fusion dans `main` par le workflow « Versions » ; la liste des versions passées est dans [`tools/versions.txt`](tools/versions.txt). Les branches ne sont jamais supprimées.

- Sur GitHub : onglet **Releases** (ou **Tags**), choisir la version, télécharger « Source code (zip) », ouvrir `game/project.godot`.
- Avec git : `git checkout v0.1.19` (revenir ensuite avec `git checkout main`).
- Annuler une version dans `main` : `git revert -m 1 <commit de fusion>` (le commit est dans `tools/versions.txt`).
