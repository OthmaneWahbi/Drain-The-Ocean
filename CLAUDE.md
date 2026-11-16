# CLAUDE.md — Règles du projet Drain the Ocean

Ces règles s'appliquent à toute session (Claude ou autre assistant) qui travaille sur ce dépôt.

## Documents de référence

- [`docs/PRD.md`](docs/PRD.md) est la **source unique de vérité** : fonctionnalités, règles de jeu, tech stack. Lis-le avant de travailler. Ne code rien qui le contredise ; si une tâche l'exige, mets d'abord le PRD à jour.
- [`HANDOFF.md`](HANDOFF.md) est le **journal vivant** du projet. Lis sa section « État actuel » au début de chaque session.
- [`docs/GUIDE_CODE.md`](docs/GUIDE_CODE.md) explique **côté code** comment chaque idée est implémentée (fichiers, nœuds, signaux, flux de données). Mets-le à jour à chaque version (y compris sa section « Par version »), et explique brièvement à Othmane la logique de code de chaque nouvelle version.

## Mise à jour obligatoire de HANDOFF.md

**À chaque tâche, sans qu'on te le demande**, ajoute une entrée à `HANDOFF.md` (en haut de la section « Journal », format décrit dans le fichier) pour :

- toute **décision** prise par Othmane (même donnée au détour d'une conversation) → `DÉCISION` ;
- toute **modification** du code, des données, des assets ou de la doc → `MODIF` ;
- tout **test qui échoue** (automatique ou manuel, même corrigé ensuite), avec la cause et la correction → `TEST ÉCHOUÉ` ;
- toute **question ouverte** nouvelle → `QUESTION` ;
- toute information utile pour la session suivante → `NOTE`.

Puis mets à jour la section « État actuel » si elle a changé, et la section « Architecture et logique » si l'architecture ou une règle du jeu a changé (logique uniquement, sans détail de code). La mise à jour de `HANDOFF.md` se fait **dans le même commit** que la modification qu'elle décrit.

Ne supprime ni ne réécris jamais une entrée existante : ajoute une nouvelle entrée qui la remplace.

## Mise à jour du PRD

- Quand une décision change une fonctionnalité, mets à jour le PRD (passer **[PROPOSÉ]** → **[DÉCIDÉ]**, retirer la question de la §18, etc.) et incrémente sa version.
- Seul Othmane prend les décisions. Une proposition d'IA reste **[PROPOSÉ]** tant qu'il ne l'a pas validée.

## Développement

- Projet Godot dans `game/` (Godot **4.7.2** stable, figée ; montée de version = décision consignée).
- Premier import (génère `.godot/` et les traductions) : `godot --headless --path game --import`
- Tests : `godot --headless --path game -s res://tests/run_tests.gd` (fichiers `game/tests/test_*.gd`, méthodes `test_*`, classe de base `TestCase`). La CI GitHub Actions lance les tests et un test de fumée sur chaque PR.
- Lancer le jeu : ouvrir `game/project.godot` dans l'éditeur, ou `godot --path game`.
- Phase greybox : formes simples (CSG, maillages primitifs) uniquement, pas d'assets.

## Conventions

- Langue de la documentation et des messages de commit : **français**.
- Moteur : Godot 4, GDScript typé (voir PRD §16).
- Les valeurs d'équilibrage vivent dans des fichiers de données, jamais en dur dans le code.
