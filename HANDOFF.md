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
- **Documents :** PRD v0.6 en revue (PR #1) ; questionnaire MVP (`docs/QUESTIONS_MVP.md`) en attente de réponses.
- **Prochaine étape :** Othmane répond au questionnaire MVP (M-01 à M-85), puis jalon M0 (fondations du projet Godot).
- **Décisions récentes :** 3D low-poly style *How to Fish* ; troc direct ; caméra première personne avec bascule en troisième personne ; fin = avion publicitaire de l'agence devenue société de transport, puis temps de partie, générique et retour au menu ; texte sobre autorisé dans les textures ; sauvegarde finie rouverte juste avant le drain ; vidage sans drain possible, mais les derniers litres seulement au seau.
- **Questions ouvertes :** 19 (voir [PRD §18](docs/PRD.md#18-questions-ouvertes)), plus les 85 questions du questionnaire MVP.

---

## Journal

### 2026-11-16 — QUESTION — Questionnaire MVP (M-01 à M-85)
- **Quoi :** création de `docs/QUESTIONS_MVP.md` : 85 questions regroupées par thème (périmètre, technique, contrôles, personnage, seau, séchage, ressources, téléphone, contenu du catalogue, monde, interface, audio, sauvegarde, hors MVP), chacune avec une recommandation. Tant qu'une question n'est pas tranchée, le prototype suit la recommandation.
- **Pourquoi :** Othmane veut tout décortiquer avant de construire le MVP/la démo.
- **Impact :** `docs/QUESTIONS_MVP.md`, PRD §18 et §19.
- **Par :** Claude

### 2026-11-16 — MODIF — PRD v0.6 : périmètre du MVP
- **Quoi :** §19.1 décrit le contenu du MVP/de la démo (T0-T2, île de départ, fin accessible en debug seulement, critère de réussite), et ce qui en est exclu ; Q-26 tranchée.
- **Pourquoi :** préparer la construction du MVP.
- **Impact :** PRD §11, §18, §19.
- **Par :** Claude

### 2026-11-16 — DÉCISION — « Plop » à sec ; succès décidés en fin de projet (Q-26)
- **Quoi :** si le joueur ouvre le drain après avoir tout vidé au seau, le drain fait juste un petit « plop ». Les succès (secrets ou non) seront décidés en fin de projet.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §11.
- **Par :** Othmane

### 2026-11-16 — MODIF — PRD v0.5 : reprise des sauvegardes finies et vidage manuel
- **Quoi :** §11 complétée (drain facultatif, derniers litres au seau ou par le drain, point de reprise avant le drain) ; ajout du problème P-18 et de la question Q-26 ; Q-25 retirée.
- **Pourquoi :** décisions d'Othmane.
- **Impact :** PRD §11, §17, §18.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Le drain est facultatif, mais les derniers litres se vident au seau ou par le drain
- **Quoi :** le joueur doit pouvoir vider le reste de l'océan sans ouvrir le drain s'il le veut. Les derniers litres ne peuvent partir qu'à la main (seau) ou par le drain, et les finir au seau doit être fastidieux.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §11 ; les machines doivent cesser de fonctionner sous un seuil (proposition).
- **Par :** Othmane

### 2026-11-16 — DÉCISION — Une sauvegarde terminée se rouvre juste avant le drain (Q-25)
- **Quoi :** recharger une partie finie ramène le joueur au fond de l'océan, juste avant d'ouvrir le drain.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §11 ; système de sauvegarde (point de reprise).
- **Par :** Othmane

### 2026-11-16 — MODIF — PRD v0.4 : texte dans les textures et fin de la run
- **Quoi :** §11 (banderole, écran du temps, retour au menu), §12 (règle du texte assouplie), §2, §4.4, §16.1, P-16, §18 (Q-23 et Q-24 retirées, ajout de Q-25), §19 mis à jour. Ajout d'un chronomètre de temps de jeu réel dans la sauvegarde **[PROPOSÉ]**.
- **Pourquoi :** décisions d'Othmane sur Q-23 et Q-24.
- **Impact :** PRD §2, §4.4, §11, §12, §16.1, §17, §18, §19, §20.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Fin de la run : temps affiché, générique, retour au menu (Q-24)
- **Quoi :** à la fin, le temps pris par le joueur s'affiche **avant** le générique ; après le générique, retour au menu et la run est terminée. Pas d'exploration après la fin.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §11.
- **Par :** Othmane

### 2026-11-16 — DÉCISION — Le texte dans les textures est permis, mais sobre (Q-23)
- **Quoi :** la banderole de l'avion final porte un slogan écrit. Ce n'est pas le seul texte : plusieurs textures auront besoin de texte, mais il doit rester rare et sobre. La règle « pas de lore à lire » (pas de livres, pas de notes) reste valable.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §11, §12. Remplace la proposition « aucun texte lisible dans le monde » de la v0.1.
- **Par :** Othmane

### 2026-11-16 — MODIF — PRD v0.3 : la fin du jeu
- **Quoi :** §11 réécrite avec la fin décidée ; Q-16 retirée ; ajout de Q-23 (banderole : texte ou pictogrammes, car le jeu n'a sinon aucun texte dans le monde) et Q-24 (retour au menu ou exploration libre après le générique) ; jalon M5 mis à jour.
- **Pourquoi :** décision d'Othmane sur Q-16.
- **Impact :** PRD §11, §18, §19.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Fin du jeu : l'avion publicitaire (Q-16)
- **Quoi :** une fois l'océan drainé, le joueur traverse l'océan asséché à pied. Un avion publicitaire passe juste au-dessus de lui : la banderole annonce que l'agence de livraison qu'il utilisait est maintenant aussi une société de transport, qui peut vous emmener de n'importe où à n'importe où. Le joueur le voit en marchant, puis générique. Fin.
- **Pourquoi :** choix d'Othmane ; dernier gag qui répond à « pourquoi l'agence ne m'emmène pas ? ».
- **Impact :** PRD §11.
- **Par :** Othmane

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
