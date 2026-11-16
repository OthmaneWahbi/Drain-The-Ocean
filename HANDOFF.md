# HANDOFF — Journal vivant du projet

> Ce fichier est le **journal de bord** de Drain the Ocean. On y consigne **tout** : chaque décision, chaque modification, chaque test qui échoue, chaque question ouverte.
> Le [`docs/PRD.md`](docs/PRD.md) décrit l'état *actuel* du jeu ; ce fichier raconte *comment et pourquoi* on en est arrivé là.

## Règles d'écriture

1. **On ajoute, on n'efface jamais.** Une décision annulée reçoit une nouvelle entrée qui la remplace (et cite l'ancienne).
2. **Plus récent en haut** du journal.
3. **Une entrée par événement**, au format ci-dessous.
4. Toute session (humaine ou IA) qui modifie le projet met ce fichier à jour **dans le même commit** que la modification.
5. Un test qui échoue est consigné **même s'il est corrigé juste après** (avec la cause et la correction).

### Types d'entrées

| Type | Quand l'utiliser |
|---|---|
| `DÉCISION` | Un choix validé par Othmane (gameplay, technique, organisation) |
| `MODIF` | Un changement dans le code, les données, les assets ou la documentation |
| `TEST ÉCHOUÉ` | Un test automatique ou manuel qui ne passe pas (cause, correction ou piste) |
| `QUESTION` | Une question ouverte qui attend une décision |
| `NOTE` | Une information utile pour la suite (piste, découverte, limite connue) |

### Format d'une entrée

```
### AAAA-MM-JJ — TYPE — Titre court
- **Quoi :** …
- **Pourquoi :** …
- **Impact :** fichiers / sections du PRD concernés
- **Par :** qui (Othmane, Claude, …)
```

---

## État actuel (résumé à tenir à jour)

- **Phase :** conception. Aucun code pour l'instant.
- **Documents :** PRD v0.2 en revue (PR #1).
- **Prochaine étape :** Othmane répond aux questions ouvertes du PRD (section 18), puis jalon M0 (fondations du projet Godot).
- **Décisions récentes :** 3D low-poly style *How to Fish* ; troc direct ; caméra première personne avec bascule en troisième personne.
- **Questions ouvertes :** 19 restantes (voir [PRD §18](docs/PRD.md#18-questions-ouvertes)). La plus structurante : Q-16 (que se passe-t-il juste après l'ouverture du drain).

---

## Journal

### 2026-11-16 — MODIF — PRD v0.2 : intégration des décisions et vocabulaire « drain »
- **Quoi :** PRD passé en v0.2. Q-01, Q-07 et Q-13 passées en **[DÉCIDÉ]** et retirées de la liste des questions. Le mot « bonde » est remplacé par « **drain** » partout (terme d'Othmane), la §6.2 explique concrètement le troc, et Q-16 est reformulée avec des options concrètes (générique direct, exploration libre, épilogue comique, partir vraiment, mode infini).
- **Pourquoi :** réponses d'Othmane ; la question « après la bonde » n'était pas claire.
- **Impact :** PRD §1, §6.2, §10, §11, §15, §18.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Caméra : première personne avec bascule en troisième personne (Q-13)
- **Quoi :** la caméra principale est à la première personne ; le joueur peut basculer en troisième personne à tout moment.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §10. Il faut à la fois des bras/objets en vue subjective et un personnage complet animé.
- **Par :** Othmane

### 2026-11-16 — DÉCISION — Économie en troc direct (Q-07)
- **Quoi :** pas de monnaie ; chaque article du catalogue se paie directement en ressources (sel, minéraux, minéraux rares, coquillages).
- **Pourquoi :** choix d'Othmane, sur recommandation (chaque ressource garde sa valeur, plus lisible).
- **Impact :** PRD §6.2.
- **Par :** Othmane

### 2026-11-16 — DÉCISION — Jeu principal en 3D low-poly, style *How to Fish* (Q-01)
- **Quoi :** le jeu PC est en 3D low-poly, dans le même esprit visuel que *How to Fish*.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §1, §10, §15.
- **Par :** Othmane

### 2026-11-16 — MODIF — Création du dépôt et des documents fondateurs
- **Quoi :** commit initial (`README.md`) sur `main`, puis création de `docs/PRD.md` (v0.1), `HANDOFF.md`, `CLAUDE.md` et `.gitignore` (Godot 4) sur une branche dédiée, proposés en pull request.
- **Pourquoi :** formaliser le jeu avant toute ligne de code, à la demande d'Othmane.
- **Impact :** tout le dépôt.
- **Par :** Claude

### 2026-11-16 — QUESTION — 22 questions ouvertes listées dans le PRD
- **Quoi :** l'analyse de l'idée a fait ressortir 22 décisions à prendre (Q-01 à Q-22), chacune avec options et recommandation, ainsi que 17 problèmes de conception (P-01 à P-17) et 10 problèmes techniques (T-01 à T-10).
- **Pourquoi :** les propositions du PRD marquées **[PROPOSÉ]** ne deviennent des décisions qu'après validation d'Othmane.
- **Impact :** PRD §17 et §18.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Fonctionnalités de base du jeu (énoncées par Othmane)
- **Quoi :** les éléments suivants sont décidés et font foi :
  - **Concept :** le joueur se réveille sur une île entourée d'océan à perte de vue. Il n'y a que lui, un téléphone rouge (style téléboutique) et un seau. Personne ne viendra l'aider ; il doit vider l'océan pour passer. Le problème : l'océan est trop grand.
  - **Téléphone :** il ne contacte qu'une agence de livraison, qui ne livre que des objets (pas de personnes). Aucun autre contact possible.
  - **Seau :** il sert à prendre l'eau de l'océan et à la mettre ailleurs pour qu'elle sèche.
  - **Ressources :** le séchage donne des items qui servent de monnaie. Peu d'items : sel, quelques minéraux, minéraux rares, coquillages.
  - **Échanges :** on commerce via le téléphone ; l'agence vient prendre le dépôt et dépose la livraison par avion, rapidement et de façon comique, sans attendre le joueur.
  - **Progression :** les achats permettent de vider plus vite grâce à des technologies de plus en plus poussées, jusqu'à de grandes machines.
  - **Fin :** quand il reste 5 % d'eau ou moins, un drain est visible au fond de l'océan ; le joueur peut simplement l'ouvrir pour vider le reste. C'est censé être drôle.
  - **Lore :** pas d'histoire à proprement parler. Uniquement des clins d'œil pour les joueurs attentifs, compréhensibles à l'œil. Pas de livres ni de textes à lire.
  - **Plateformes :** la version principale est sur PC (Windows). Elle contient un mini-jeu du même concept en clicker, pixel art très simple. Ce clicker sera ensuite porté sur téléphone, beaucoup plus tard.
  - **Moteur :** Godot.
- **Pourquoi :** vision d'origine du jeu.
- **Impact :** PRD §1, §3, §4, §6, §7, §9, §11, §12, §13, §14, §16.
- **Par :** Othmane

### 2026-11-16 — DÉCISION — Organisation de la documentation : PRD + HANDOFF
- **Quoi :**
  - `docs/PRD.md` est la **source unique de vérité** de toutes les fonctionnalités du jeu et du tech stack.
  - `HANDOFF.md` (ce fichier) est le **journal vivant** du projet : **toute décision prise, toute modification et tout test qui ne fonctionne pas doivent y être ajoutés automatiquement.** Cette règle elle-même y est consignée (cette entrée).
  - Aucune ligne de code n'est écrite avant que les fonctionnalités soient formalisées dans le PRD.
  - `CLAUDE.md` impose ces règles aux sessions d'IA qui travaillent sur le dépôt.
- **Pourquoi :** garder une trace complète de l'historique des choix et éviter de refaire les mêmes débats ou les mêmes erreurs.
- **Impact :** `docs/PRD.md`, `HANDOFF.md`, `CLAUDE.md`.
- **Par :** Othmane
