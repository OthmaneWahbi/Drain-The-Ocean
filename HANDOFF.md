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

- **Phase :** le MVP est entièrement spécifié. Aucun code pour l'instant.
- **Documents :** PRD v0.8 en revue (PR #1). Décisions du MVP en PRD §19.2 et §19.3.
- **Prochaine étape :** jalon M0 (fondations du projet Godot : structure, tests, CI), dès le feu vert d'Othmane.
- **Décisions clés :** 3D low-poly style *How to Fish* ; troc direct ; caméra 1re personne + bascule 3e ; survie légère (endurance qui ne remonte pas dans l'eau, faim, soif, sans mort) ; noyade = retour sur la plage ; bassin immense (milliers de km), fin secrète à la nage ; fin principale = drain, avion publicitaire, temps, générique, menu ; démo T0-T2 de 30-45 min.
- **Questions ouvertes :** seulement celles de long terme (PRD §18) ; aucune ne bloque le MVP.

---

## Journal

### 2026-11-16 — MODIF — PRD v0.8 : questions de suite intégrées
- **Quoi :** §4.1 (nourriture, eau douce, endurance, faim/soif), §6.1 (perle), §8.1 (bassin immense, volume 10¹⁸-10¹⁹ L, traversée finale mise en scène), §8.2 (jauge à aiguille), §9 (offres spéciales), §10 (noyade, fin secrète), §16.3 (terrain détaillé seulement autour de l'île), §19.1 (contenu du MVP, ajouts au catalogue, tourbillon retiré), §19.3 (décisions N-01 à N-10).
- **Pourquoi :** réponses d'Othmane aux questions de suite.
- **Impact :** `docs/PRD.md`, `docs/QUESTIONS_MVP.md`.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Questions de suite N-01 à N-10
- **Quoi :** N-01 pas de tourbillon lointain dans le MVP ; N-02 noix de coco + rations, eau douce par bâche de condensation ; N-03 pas de mort de faim/soif, l'endurance max baisse ; N-04 noyade = retour sur la plage sans perte ; N-05 endurance ~20 s course / ~60 s nage, ne remonte **jamais dans l'eau** ; N-06 bassin réellement immense (milliers de km), volume ~10¹⁸-10¹⁹ L ; N-07 perle ~2 % des coquillages, pour un objet spécial ; N-08 offre spéciale ~1 fois par jour ; N-09 brouette (T1) puis toboggan à sacs (T2) ; N-10 jauge à aiguille.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §4, §6, §8, §9, §10, §16, §19.
- **Par :** Othmane

### 2026-11-16 — MODIF — Formulaire des questions de suite (N-01 à N-10)
- **Quoi :** les questions N-01 à N-10 sont proposées dans un second formulaire web (copie : `docs/questions-suite.html`). L'envoi du premier formulaire a été vérifié : les réponses reçues correspondent au texte collé par Othmane.
- **Pourquoi :** même format que le questionnaire MVP, plus simple pour répondre.
- **Impact :** `docs/questions-suite.html`.
- **Par :** Claude

### 2026-11-16 — QUESTION — 10 nouvelles questions issues du questionnaire (N-01 à N-10)
- **Quoi :** incohérence M-67/M-84 (tourbillon lointain), nourriture et eau douce, conséquences de la faim/soif, noyade, endurance, taille du monde pour la fin secrète à la nage, perle, offres spéciales du téléphone, achat qui automatise le transport, jauge de niveau d'eau.
- **Pourquoi :** les réponses d'Othmane ajoutent la survie légère, la noyade, la fin à la nage, la perle et les offres spéciales, qui demandent des précisions.
- **Impact :** PRD §19.3.
- **Par :** Claude

### 2026-11-16 — MODIF — PRD v0.7 : réponses au questionnaire MVP
- **Quoi :** les 85 réponses sont listées en PRD §19.2 et reportées dans les sections concernées (§4.1 survie et jour/nuit, §5.5, §6.1 perle, §8.2 repère de niveau, §9 catalogue, délai de 5 s, maquettes, §10 nage et fin secrète, §16.3 machine de référence et origine flottante, §18 questions tranchées, §19.1 périmètre).
- **Pourquoi :** Othmane a répondu au questionnaire.
- **Impact :** `docs/PRD.md`, `docs/QUESTIONS_MVP.md`.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Réponses au questionnaire MVP (M-01 à M-85)
- **Quoi :** recommandations acceptées partout sauf : M-24 nage avec endurance et noyade ; M-25 pas de limite artificielle, fin secrète si on nage des milliers de km ; M-26 survie légère (endurance façon BotW, faim, soif) ; M-28 transport à la main puis automatisé par un achat ; M-31 pas de ralentissement avec le seau ; M-32 gouttes purement visuelles ; M-33/M-34 l'eau reversée sur le sable compte aussi comme rendue à l'océan ; M-45 perle dans le MVP ; M-51 livraison en 5 s ; M-54 offres spéciales au téléphone ; M-62 le niveau doit bouger un tout petit peu dans la démo avec un repère ; M-67 pas de tourbillon lointain ; M-68 HUD petit et comique ; M-78 sauvegarde manuelle qui remplace la dernière auto. Machine de référence (M-11) : i9, RTX 4 Go VRAM, ~12 Go RAM. Assets sur-mesure faits sous Blender plus tard (M-07). Détail complet : PRD §19.2.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §4, §6, §8, §9, §10, §16, §18, §19.
- **Par :** Othmane

### 2026-11-16 — MODIF — Questionnaire MVP en formulaire interactif
- **Quoi :** les 85 questions de `docs/QUESTIONS_MVP.md` sont aussi disponibles en formulaire web (recommandations pré-cochées, commentaires, enregistrement automatique, export texte). Copie de la page dans `docs/questionnaire-mvp.html`.
- **Pourquoi :** Othmane ne pouvait pas répondre facilement au format Markdown.
- **Impact :** `docs/questionnaire-mvp.html`.
- **Par :** Claude

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
