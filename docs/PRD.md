# Drain the Ocean — PRD (Product Requirements Document)

> **Source unique de vérité.** Toute fonctionnalité du jeu, toute règle de gameplay et tout choix technique est décrit ici. Si ce n'est pas dans ce document, ce n'est pas (encore) dans le jeu.
> Chaque modification de ce document doit être consignée dans [`HANDOFF.md`](../HANDOFF.md).

| Champ | Valeur |
|---|---|
| Version du document | 0.41 (0.1.10 : la pelle, les remarques d'Othmane, les modèles CC0, des tuyaux plus pratiques) |
| Date | 2026-11-20 |
| Statut | En revue : les sections marquées **[PROPOSÉ]** attendent la validation d'Othmane |
| Langue | Français |

### Légende des statuts

- **[DÉCIDÉ]** : validé par Othmane. Ne change que par une nouvelle décision consignée dans HANDOFF.
- **[PROPOSÉ]** : proposition de conception, à valider ou rejeter.
- **[QUESTION Q-xx]** : décision ouverte, détaillée en [section 18](#18-questions-ouvertes).
- Les chiffres marqués *(provisoire)* servent à raisonner ; ils seront fixés par l'équilibrage.

---

## Sommaire

1. [Pitch](#1-pitch)
2. [Piliers de conception](#2-piliers-de-conception)
3. [Plateformes et versions](#3-plateformes-et-versions)
4. [Univers et mise en scène](#4-univers-et-mise-en-scène)
5. [Boucles de gameplay](#5-boucles-de-gameplay)
6. [Ressources et économie](#6-ressources-et-économie)
7. [Progression technologique](#7-progression-technologique)
8. [L'océan : échelle, niveau, fond marin, destination de l'eau](#8-locéan--échelle-niveau-fond-marin-destination-de-leau)
9. [Le téléphone et l'agence de livraison](#9-le-téléphone-et-lagence-de-livraison)
10. [Le personnage, la caméra et les contrôles](#10-le-personnage-la-caméra-et-les-contrôles)
11. [La fin : le drain](#11-la-fin--le-drain)
12. [Clins d'œil (lore uniquement visuel)](#12-clins-dœil-lore-uniquement-visuel)
13. [Mini-jeu clicker (dans la version PC)](#13-mini-jeu-clicker-dans-la-version-pc)
14. [Version mobile (future)](#14-version-mobile-future)
15. [Direction artistique et audio](#15-direction-artistique-et-audio)
16. [Tech stack et architecture](#16-tech-stack-et-architecture)
17. [Problèmes identifiés et propositions](#17-problèmes-identifiés-et-propositions)
18. [Questions ouvertes](#18-questions-ouvertes)
19. [Périmètre MVP et feuille de route](#19-périmètre-mvp-et-feuille-de-route)
20. [Glossaire](#20-glossaire)

---

## 1. Pitch

**[DÉCIDÉ]** Le joueur se réveille sur une petite île. Autour de lui, de l'océan à perte de vue. Sur l'île il n'y a que lui, **un téléphone rouge** (style cabine / téléboutique) et **un seau**. Personne ne viendra l'aider. Pour partir, il n'a qu'une solution : **vider l'océan**. Le problème, évidemment : l'océan est beaucoup trop grand.

Le seau sert à puiser l'eau et à la déposer ailleurs pour qu'elle sèche. En séchant, l'eau laisse des **ressources** (sel, minéraux, minéraux rares, coquillages) qui servent de monnaie. Le téléphone ne joint qu'**une agence de livraison** qui ne livre que des objets (jamais des personnes). On échange nos ressources contre des outils et des machines, livrés par avion de façon comiquement rapide, sans que personne ne descende. Chaque achat permet de vider plus vite, jusqu'aux machines gigantesques.

Quand il reste **5 % d'eau ou moins**, un **drain** (une sorte de bonde géante, comme au fond d'une baignoire) devient visible au fond de l'océan. Le joueur n'a qu'à l'ouvrir pour vider tout le reste. C'est la chute comique du jeu.

**Une phrase :** un jeu incrémental en 3D low-poly où l'on passe d'un seau à des machines absurdes pour vider un océan… qui avait un drain depuis le début.

---

## 2. Piliers de conception

**[PROPOSÉ]** Les piliers servent à trancher les débats futurs : une fonctionnalité qui n'en sert aucun est coupée.

1. **L'absurde pris au sérieux.** Le jeu ne fait jamais de clin d'œil appuyé. Le personnage vide l'océan avec application ; l'humour naît du décalage (avion qui ne s'arrête pas, chiffres démesurés, drain final).
2. **Toujours voir le progrès.** Même quand le niveau de l'océan ne bouge pas, le joueur voit quelque chose grandir : son stock, ses machines, son île, ses records.
3. **Montrer, ne pas raconter.** Aucun texte de lore, aucun livre, aucun dialogue. Le texte dans le décor existe mais reste rare et sobre. Tout se comprend à l'œil (voir [section 12](#12-clins-dœil-lore-uniquement-visuel)).
4. **Simple à prendre, profond à optimiser.** Peu de ressources (4), peu de règles, mais des choix d'agencement et d'investissement qui comptent.
5. **Un rythme qui s'accélère.** Chaque palier technologique change *la façon* de jouer, pas seulement la vitesse.

---

## 3. Plateformes et versions

| Version | Plateforme | Gameplay | Priorité | Statut |
|---|---|---|---|---|
| **Jeu principal** | PC Windows | 3D, exploration de l'île, puisage, machines, téléphone | 1 | **[DÉCIDÉ]** |
| **Mini-jeu clicker** | Intégré au jeu PC | 2D pixel art très simple, même concept | 2 | **[DÉCIDÉ]** |
| **Version mobile** | Android (puis iOS ?) | Le clicker, étendu en jeu autonome | 3 (beaucoup plus tard) | **[DÉCIDÉ]** sur le principe, **[QUESTION Q-14]** sur les détails |
| Linux / macOS / Steam Deck | PC | Identique au jeu principal | Bonus | **[PROPOSÉ]** : Godot exporte presque gratuitement vers Linux ; macOS demande signature et notarisation |

---

## 4. Univers et mise en scène

### 4.1 L'île de départ

- **[DÉCIDÉ]** Petite île, le joueur y est seul avec le téléphone rouge et le seau.
- **[PROPOSÉ]** Taille de départ : ~40 m de diamètre, quelques palmiers, rochers, une petite crique. Assez petite pour que la place manque vite (voir [8.5](#85-lîle-qui-grandit)).
- **[DÉCIDÉ]** Survie **légère** (M-26, 2026-11-16) : **endurance** (style *Zelda: Breath of the Wild*, consommée en courant et en nageant), **faim et soif légères**. Le jeu reste détendu.
  - **[DÉCIDÉ]** **Nourriture** : noix de coco sur les palmiers et rations au catalogue. **Eau douce** : bâche de condensation (achat T1) (N-02).
  - **[DÉCIDÉ]** Faim ou soif à zéro : **pas de mort**, l'endurance maximale baisse jusqu'à ce qu'on mange ou boive (N-03).
  - **[PROPOSÉ]** Valeurs du prototype : la faim se vide en 15 min, la soif en 10 min. À zéro, l'endurance max perd jusqu'à 30 % par besoin, progressivement en 2 min ; manger ou boire efface aussitôt cette pénalité.
  - **[PROPOSÉ]** Noix de coco : une par emplacement sous les palmiers (5), qui revient chaque matin si elle a été mangée ; E pour la manger (+35 % de faim, +25 % de soif).
  - **[PROPOSÉ]** Rations : 8 sel la caisse de 5 repas (+60 % de faim chacun) ; la caisse disparaît vide.
  - **[PROPOSÉ]** Bâche de condensation : 20 sel ; produit une gorgée d'eau douce toutes les 90 s (3 au plus) ; E pour boire (+50 % de soif).
  - **[DÉCIDÉ]** **Endurance** : ~10 s de course ou ~30 s de nage (Othmane, 2026-11-16 : moitié des ~20 s / ~60 s de N-05, « trop généreux »). Elle remonte à l'arrêt **sur la terre ferme** ; **dans l'eau, elle ne remonte jamais**, même immobile. Améliorable avec la nourriture et des objets du catalogue (N-05).
- **[DÉCIDÉ]** Cycle jour/nuit : **20 min réelles par jour**, évaporation ×0,3 la nuit (M-40). La nuit est belle et calme, pas punitive.

### 4.2 Le téléphone

- **[DÉCIDÉ]** Rouge, style téléboutique. Il ne peut appeler **que** l'agence de livraison.
- **[PROPOSÉ]** C'est le cœur de l'interface du jeu : décrocher = ouvrir le catalogue et la gestion des commandes.
- **[PROPOSÉ]** Le câble du téléphone part dans le sable puis dans la mer (clin d'œil : voir [12](#12-clins-dœil-lore-uniquement-visuel)).

### 4.3 Le seau

- **[DÉCIDÉ]** Le seau permet de prendre l'eau de l'océan et de la verser ailleurs pour la faire sécher.
- **[PROPOSÉ]** Le seau de départ reste dans l'inventaire toute la partie. Il devient un objet sentimental : améliorable cosmétiquement, et utilisé dans la scène de fin.

### 4.4 L'agence de livraison

- **[DÉCIDÉ]** Elle livre uniquement des objets, jamais des personnes, et ne permet de contacter personne d'autre.
- **[DÉCIDÉ]** Les livraisons arrivent par avion, rapidement et de façon comique, sans attendre le joueur.
- **[PROPOSÉ]** L'agence n'a pas de visage. On ne voit que ses avions, son logo (pictogramme, éventuellement avec le nom de l'agence) et ses caisses. Le pilote fait un signe de la main à chaque passage.

---

## 5. Boucles de gameplay

### 5.1 Boucle courte (10 à 60 secondes)

1. Puiser de l'eau (seau, puis pompes…).
2. La déposer dans une zone de séchage (bassin, bâche, évaporateur…).
3. Attendre / faire autre chose pendant que l'eau sèche.
4. Récolter les ressources déposées (sel, minéraux…).

### 5.2 Boucle moyenne (5 à 20 minutes)

1. Accumuler assez de ressources.
2. Décrocher le téléphone, choisir dans le catalogue.
3. Déposer le paiement sur la zone de dépôt ; l'avion l'emporte et largue la commande.
4. Installer le nouvel outil ou la nouvelle machine, réorganiser l'île.

### 5.3 Boucle longue (la partie entière)

1. Débloquer des paliers technologiques (seau → pompes → machines → mégastructures).
2. Voir l'océan baisser, découvrir le fond marin (nouvelles zones, nouvelles ressources, clins d'œil).
3. Atteindre ≤ 5 % : trouver le drain, l'ouvrir, fin.

### 5.4 Durée cible

- **[PROPOSÉ]** 6 à 10 heures pour finir, 12 à 15 heures pour tout trouver (clins d'œil, succès). *[QUESTION Q-02]*
- **[DÉCIDÉ]** Premier achat **vers 1 min 30** (Othmane, 2026-11-16, après avoir testé M2 : 3 min, « beaucoup trop long »). **[PROPOSÉ]** Premier palier technologique en moins de 15 minutes. Le joueur ne doit jamais rester plus de ~10 minutes sans objectif atteignable visible.

### 5.5 Actif contre inactif (idle)

- **[PROPOSÉ]** Début de partie très **actif** (le joueur porte le seau lui-même), puis de plus en plus **automatisé** : le joueur devient gestionnaire et architecte de son île.
- **[DÉCIDÉ]** Pas de progression quand le jeu est fermé sur PC (M-79). Le mobile sera décidé au moment du portage.

---

## 6. Ressources et économie

### 6.1 Les ressources

**[DÉCIDÉ]** Peu de ressources : le sel, quelques minéraux, des minéraux rares et des coquillages.
**[PROPOSÉ]** Exactement **4 ressources**, chacune avec un rôle clair :

| Ressource | Rareté | Source principale | Rôle économique |
|---|---|---|---|
| **Sel** | Commune | Séchage de n'importe quelle eau | Monnaie de base, achats courants |
| **Minéraux** (gros cristaux gris/blancs, type gypse) | Peu commune | Séchage ; meilleur rendement avec des outils de raffinage | Achats de machines |
| **Minéraux rares** (cristal coloré qui brille) | Rare | Séchage avec raffinage avancé ; zones profondes du fond marin | Paliers technologiques, grosses machines |
| **Coquillages** | Variable | Un peu au puisage ; surtout ramassés sur le fond marin découvert | Monnaie « de l'exploration », récompense les sorties hors de l'île |

- **[PROPOSÉ]** Les ressources sont **physiques** : on voit des tas de sel, des sacs, des caisses sur l'île. Le stock devient un élément du décor (et un problème de place, voir [17](#17-problèmes-identifiés-et-propositions)).
- **[DÉCIDÉ]** Une 5ᵉ ressource ultra-rare, la **perle**, existe et est présente dès le MVP (M-45). **[DÉCIDÉ]** Elle se trouve rarement dans les coquillages ramassés (~2 %) et sert à acheter un objet spécial ou cosmétique du catalogue (N-07).

### 6.2 Le troc (pas de monnaie)

**[DÉCIDÉ]** **Troc direct** (Q-07, 2026-11-16).

Concrètement : il n'existe **aucune monnaie** (pas de pièces, pas de crédits). Chaque article du catalogue a un prix exprimé **directement en ressources**. Exemple : « Pompe manuelle = 300 sel + 20 minéraux + 5 coquillages ». On pose ces ressources sur la zone de dépôt, l'avion les emporte, et la livraison arrive.

L'alternative écartée était de *vendre* d'abord ses ressources à l'agence contre une monnaie unique, puis d'acheter avec cette monnaie. Le troc a été retenu parce que chaque ressource garde sa valeur toute la partie et que c'est plus lisible et plus « naufragé ».

### 6.3 Le séchage

- **[DÉCIDÉ]** On verse l'eau quelque part pour la sécher ; le séchage produit les ressources.
- **[PROPOSÉ]** Règles :
  - Une **zone de séchage** a une **surface** (m²) et une **capacité** (litres).
  - La vitesse d'évaporation dépend de la **surface** et de l'**ensoleillement** (jour/nuit, et plus tard miroirs, chauffage). C'est le premier goulot d'étranglement du jeu : vider plus vite demande plus de surface, donc plus de place, donc plus d'île.
  - Une fois l'eau évaporée, il reste un dépôt à **récolter** (manuellement au début, automatiquement ensuite).
  - Rendement *(provisoire)* : 1 L d'eau de mer ≈ 35 g de sel en vrai. En jeu : **1 seau (10 L) = 1 unité de sel**, avec une probabilité de minéraux. Les outils de raffinage augmentent la part de minéraux et minéraux rares.
- **[PROPOSÉ]** Lecture de M-37 retenue pour le prototype M2 (à valider par Othmane) :
  - Une zone **pleine** sèche entièrement en **45 s** de jour. L'évaporation est donc un débit fixe par zone, `capacité ÷ 45 s` (la cuvette de 40 L évapore environ 0,9 L/s), qu'elle soit pleine ou presque vide. Plus de surface = plus de débit, conformément à la règle ci-dessus.
  - La nuit, ce débit est multiplié par 0,3 (M-40).
  - Chaque tranche de **4 L évaporés** donne 1 sel (valeur `liters_per_salt` dans les données), plus un tirage de minéral (10 %) et de minéral rare (0,5 %). D'abord 10 L ; passé à 4 L pour le premier achat vers 1 min 30.
  - **[DÉCIDÉ]** Le sel s'entasse **à côté** de la zone, pas dedans (idée d'Othmane, 2026-11-16) : verser (clic, l'outil) et ramasser (le tas) sont deux cibles différentes. **[PROPOSÉ]** On ramasse le tas avec **E** (les mains), **3 unités par appui** ; le râteau prend tout le tas d'un coup (M-39).
  - Puiser donne 3 % de chance de coquillage par seau, et chaque coquillage 2 % de chance de perle.
  - Conséquence : les 15 sel de la bâche sèchent en ~68 s dans la cuvette ; avec les trajets, le premier achat arrive vers 1 min 30.
  - L'autre lecture (« chaque seau versé sèche en 45 s, indépendamment ») rendrait la surface inutile ; elle a été écartée pour cette raison.

### 6.4 Équilibrage

- **[PROPOSÉ]** Les coûts suivent une croissance **exponentielle** par palier et par exemplaire acheté (modèle classique des jeux incrémentaux : `coût = coût_base × facteur^n`, facteur entre 1,07 et 1,15).
- **[PROPOSÉ]** L'équilibrage se fait dans un **simulateur** (tableur ou script) *avant* d'être réglé en jeu : on simule une partie entière pour vérifier la durée de chaque palier. Les valeurs vivent dans des fichiers de données (voir [16.4](#164-données-du-jeu-pilotées-par-fichiers)), jamais en dur dans le code.

---

## 7. Progression technologique

**[DÉCIDÉ]** Les achats donnent accès petit à petit à des technologies plus poussées, jusqu'à de grandes machines capables de finir l'océan.

**[PROPOSÉ]** 7 paliers. Chaque palier multiplie le débit d'environ ×20 à ×50 et **change la façon de jouer** :

| Palier | Nom | Exemples d'objets | Ce qui change dans le jeu | Débit indicatif *(provisoire)* |
|---|---|---|---|---|
| **T0** | Le seau | Seau, trou creusé dans le sable | Tout à la main | ~1 L/s |
| **T1** | Bricolage | Grand seau, palanche (2 seaux), bâche de séchage, râteau à sel, brouette | Le joueur optimise ses trajets | ~10 L/s |
| **T2** | Hydraulique manuelle | Pompe à bras, tuyaux, bassins en série, miroirs solaires | Premières installations fixes, agencement de l'île | ~200 L/s |
| **T3** | Moteurs | Pompe motorisée, éolienne, panneaux solaires, collecteur de sel automatique, tapis roulant | Automatisation, notion d'énergie *[QUESTION Q-08]* | ~5 000 L/s |
| **T4** | Industriel | Évaporateurs thermiques, raffinerie de minéraux, plateformes flottantes, drones de récolte | L'île devient une usine, extension sur le fond découvert | ~10⁵ L/s |
| **T5** | Colossal | Pompes géantes, tours d'évaporation, barges-éponges | Machines visibles de très loin, transforment l'horizon | ~10⁷ L/s |
| **T6** | Absurde | Paille géante, machine à nuages, « aspirateur d'océan », tornade en bouteille | Pure démesure comique, on voit enfin le niveau chuter à vue d'œil | ~10⁹ L/s |
| — | Le drain | Rien à acheter : il était là depuis le début | Fin du jeu | ∞ |

- **[PROPOSÉ]** Pompe à bras et tuyaux (prototype, v0.19) :
  - La **pompe à bras** (500 sel + 40 minéraux) se pose **au bord de l'eau** (sur la plage, à plus de 15,5 m du centre de l'île). On **maintient le clic** dessus pour pomper **20 L/s** (M-58 : elle reste active, pas automatique).
  - ~~Liaisons automatiques par tronçons de 4 m (v0.19)~~ : remplacé en v0.22 par la pose à la main ci-dessous.
  - **[DÉCIDÉ]** Les tuyaux se posent **à la main** par le joueur, à l'**horizontale ou à la verticale**, librement : on compose le réseau comme on veut (Othmane, 2026-11-16).
  - **[PROPOSÉ]** Détails de la pose (v0.22) : un lot de tuyaux (50 sel) donne **5 pièces**. Une pièce occupe **une case de la grille** (1 m) à un **niveau de hauteur** de 0 (au sol) à 4. On prend l'outil « Tuyaux » dans la barre, on vise : un cube fantôme vert (ou rouge) montre où la pièce ira ; clic pour poser. En visant une pièce, la nouvelle se colle sur la face visée (au-dessus, à côté…). Une pièce en hauteur doit toucher une autre pièce ou être juste au-dessus d'une pompe. Avec l’outil en main, **E sur une pièce** la reprend dans le stock.
  - **[PROPOSÉ]** Une pompe envoie l'eau dans les pièces qui la touchent (les 4 cases autour et la case au-dessus) ; l'eau suit les pièces reliées entre elles. ~~Une pièce **au-dessus ou au bord d'une zone** (assez près de son centre) y verse l'eau.~~ **[DÉCIDÉ]** Une pièce ne verse dans une zone que **vers son centre** et **un seul bloc au-dessus** (Othmane, 2026-11-17 ; voir [19.11](#1911-version-016--tuyaux-solides-qui-versent-au-milieu-portée-de-pose)). Les zones les plus proches de la pompe en suivant les tuyaux sont remplies d'abord. Les tuyaux mouillés sont bleus, les autres gris.
  - **[PROPOSÉ]** Au sol, une pièce bloque les objets (sauf les zones de séchage, qu'un tuyau peut surplomber pour les remplir). En hauteur, elle passe au-dessus de tout. Déplacer une pompe, une zone ou un autre objet ne casse rien : le réseau est recalculé à chaque fois à partir des pièces posées (Othmane, 2026-11-16 : « le pompage ne doit pas casser quand on déplace quelque chose » **[DÉCIDÉ]**).
  - **[DÉCIDÉ]** Les pompes **affichent leur débit** quand on s'en approche ; la pompe à bras l'affiche quand on s'en sert (Othmane, 2026-11-16). **[PROPOSÉ]** Une étiquette « Moulin-pompe : 10 L/s » flotte au-dessus de la pompe à moins de 7 m ; 0 L/s quand rien n'est relié ou que les zones sont pleines.
  - On remplit la zone la plus proche d'abord. Quand toutes les zones reliées sont pleines, la pompe ne prend plus rien à l'océan.
- **[PROPOSÉ]** Moulin-pompe (prototype, v0.20) : 1 500 sel + 100 minéraux + 10 minéraux rares, un seul par partie. Il se pose au bord de l'eau et pompe **10 L/s tout seul**, même quand le joueur est loin, par le même réseau de tuyaux.
- **[PROPOSÉ]** Fin de la démo (M-05) : quand le moulin-pompe a pompé 200 L tout seul, un gros avion sombre passe au-dessus de l'île avec des silhouettes de machines T3, puis un écran « Fin de la démo » donne le bilan (temps, eau retirée, baisse du niveau) et annonce T3. « Continuer à jouer » ferme l'écran ; il ne revient plus, même après un chargement.
- **[DÉCIDÉ]** (prototype, 2026-11-16) Le **Manuel du bricoleur** (250 sel + 25 minéraux + 10 coquillages, liste M-57) débloque T2. Avant, les articles T2 sont visibles en grisé avec « Requiert le Manuel du bricoleur ». **[PROPOSÉ]** Bassin en bois : 200 L, séché en 45 s. Miroir solaire : +50 % d'évaporation pour chaque zone à moins de 6 m (plusieurs miroirs s'additionnent).
- **[PROPOSÉ]** Chaque palier se débloque par un **achat clé** au catalogue (ex. « le manuel de la pompe » sous forme de schéma illustré), pas par un arbre de compétences abstrait.
- **[PROPOSÉ]** Les objets d'un palier inférieur restent utiles un moment, puis deviennent décoratifs. Le joueur peut les revendre ou les garder.
- **[PROPOSÉ]** Le catalogue montre en silhouette grisée le palier suivant pour donner envie (« Qu'est-ce que c'est que ce truc énorme ? »).

---

## 8. L'océan : échelle, niveau, fond marin, destination de l'eau

### 8.1 Le problème d'échelle

Un vrai océan contient ~1,3 milliard de km³. Même un « petit » océan de jeu est hors de portée d'un seau. **C'est voulu** (c'est la blague), mais cela pose un vrai problème de conception : pendant des heures, le niveau ne bouge pas.

**[PROPOSÉ]** L'océan du jeu est un **bassin fini** :

- **[DÉCIDÉ]** Le bassin est **réellement immense** : rayon de **plusieurs milliers de km** (N-06, 2026-11-16), pour que la fin secrète à la nage soit possible et que « l'océan est trop grand » soit vrai au pied de la lettre. L'horizon à hauteur d'homme est à ~5 km : le joueur ne voit jamais le bord.
- **[PROPOSÉ]** Rayon ~3 000 km, profondeur moyenne ~100 m près de l'île, plus profond au large.
- **[PROPOSÉ]** Volume ≈ **10¹⁸ à 10¹⁹ L** *(provisoire, à fixer par le simulateur)*. Remplace les ~2 × 10¹³ L de la v0.6 (M-63).
- **[PROPOSÉ]** Seule la zone autour de l'île (quelques km) a un fond modélisé ; le drain reste au centre de cette zone détaillée. Le reste est un plan d'eau vide.
- **[PROPOSÉ]** La traversée finale « à pied à travers l'océan asséché » ne peut pas durer des milliers de km en temps réel : elle sera mise en scène (marche, puis fondu ou accélération) avant le passage de l'avion publicitaire.

Ordre de grandeur (à recalculer avec le nouveau volume) : pour une dernière phase d'environ 1 h, le débit final devra atteindre ~10¹⁴ à 10¹⁵ L/s. Avec un seau à 1 L/s, il faudrait des dizaines de milliards d'années. **L'écart entre les deux est toute la progression du jeu.**

### 8.2 Rendre le progrès visible malgré l'échelle

**[PROPOSÉ]** Plusieurs couches de retour :

1. **Compteur en litres** avec gros chiffres (notation lisible : 1,2 M ; 3,4 Md ; puis notation scientifique en option).
2. **Jalons comparatifs** visuels (icônes, pas de texte) : une baignoire, une piscine, une piscine olympique, un lac, une mer intérieure… Chaque jalon débloque une petite récompense.
3. **Pourcentage restant** avec beaucoup de décimales au début (99,99999 %), ce qui est drôle en soi.
4. **Le niveau réel** de l'eau, honnête, qui commence à bouger visiblement au palier T3/T4.
5. **Le fond marin conçu pour révéler beaucoup tôt** : un plateau peu profond autour de l'île (voir 8.4) fait que les premiers centimètres dévoilent beaucoup de sable.
6. **[DÉCIDÉ]** Dès la démo, un **repère de niveau d'eau** doit montrer que le niveau bouge, même d'un tout petit peu (M-62). Une **jauge à aiguille** plantée près de la plage (comme un comparateur d'atelier) : les chiffres restent honnêtes, mais l'aiguille amplifie des dixièmes de millimètre pour que le mouvement se voie. **[DÉCIDÉ]** (N-10)
   - **[PROPOSÉ]** Avec le volume de N-06, un seau ne fait baisser le niveau que de ~3,5 × 10⁻¹³ mm : même amplifiée, une aiguille linéaire ne bougerait pas de la démo. L'aiguille suit donc une **échelle logarithmique** (chaque graduation = ×10, de 10⁻¹⁶ m à 1 m) : elle bouge dès le premier seau. Le chiffre affiché sous le cadran reste la vraie baisse en millimètres.

### 8.3 Le niveau de l'eau

- **[PROPOSÉ]** Une seule variable de vérité : **le volume restant** (en litres). La hauteur de l'eau est calculée à partir du volume grâce à une table de correspondance pré-calculée depuis la forme du fond (`hauteur = f(volume)`).
- **[PROPOSÉ]** Le seuil de fin « ≤ 5 % » est un pourcentage du **volume**, pas de la hauteur.
- **[PROPOSÉ]** L'océan reste **un seul plan d'eau connecté** : le fond est modelé sans cuvettes isolées, pour éviter des lacs résiduels qu'il faudrait simuler séparément. Exception volontaire : quelques **flaques** décoratives ou récoltables (voir Q-10).

### 8.4 Le fond marin

**[PROPOSÉ]** Le fond est conçu comme un niveau, en zones concentriques qui apparaissent à mesure que l'eau baisse :

| Zone | Profondeur | Apparaît vers | Contenu |
|---|---|---|---|
| Plage étendue | 0 – 2 m | T2-T3 | Coquillages, place pour les premières machines |
| Plateau | 2 – 20 m | T3-T4 | Rochers, épaves légères, coquillages en masse |
| Talus | 20 – 100 m | T4-T5 | Falaises sous-marines, épaves, minéraux rares affleurants |
| Abysse central | 100 – 300 m | T5-T6 | Géants clins d'œil, et finalement le drain |

- **[PROPOSÉ]** Le joueur peut **marcher** sur le fond découvert. Explorer devient une activité à part entière (coquillages, minéraux rares, clins d'œil).
- **[PROPOSÉ]** Le sable découvert est d'abord mouillé et sombre, puis sèche et s'éclaircit (shader), pour que la baisse se lise même de près.

### 8.5 L'île qui grandit

**[PROPOSÉ]** Mécanique centrale : **la terre gagnée sur l'eau est de la place constructible.** Au début, l'île est trop petite pour tout poser ; vider l'océan donne de la place pour vider l'océan. C'est la boucle de rétroaction qui donne du sens au niveau de l'eau.

### 8.6 Où va l'eau ?

C'est le plus gros trou logique du concept. Si on évapore l'eau, elle devrait retomber en pluie.

**[PROPOSÉ]** Réponse en couches :

1. **Évaporation** (T0 à T4) : l'eau s'évapore et forme des nuages qui **s'éloignent toujours vers l'horizon**. Il ne pleut jamais sur l'île. On ne l'explique pas. (Clin d'œil possible : on aperçoit très loin de la pluie tomber… en dehors du bassin.)
2. **Machines** (T5-T6) : les machines géantes rejettent la vapeur en colonnes ou « expédient » l'eau de façon absurde (machine à nuages qui envoie les nuages ailleurs, tuyau qui monte vers le ciel et disparaît).
3. **Le drain** : la seule vraie réponse, à la fin. L'eau part par le trou.

**[QUESTION Q-09]** Ajouter un « gag de la pluie » (une averse rare qui fait remonter le niveau d'un chouïa) ? C'est drôle une fois, frustrant si ça coûte du progrès. Recommandation : purement visuel, sans effet sur le niveau.

### 8.7 La vie marine

**[QUESTION Q-10]** Que deviennent les poissons ? Vider un océan, c'est aussi tuer ce qu'il y a dedans, et le ton doit rester léger. Proposition : les poissons **reculent** toujours vers le centre (on les voit de plus en plus serrés, comique), et à la fin ils partent **par le drain** dans le tourbillon, en faisant coucou. Aucun poisson mort à l'écran.

---

## 9. Le téléphone et l'agence de livraison

### 9.1 Passer commande

- **[PROPOSÉ]** Décrocher le téléphone ouvre le **catalogue** : des pages illustrées, avec des pictogrammes et des prix en icônes de ressources. **[DÉCIDÉ]** Mixte : on décroche en 3D, puis un menu illustré façon catalogue papier (M-47).
- ~~**[PROPOSÉ]** Le premier appel est un tutoriel muet~~ → **[DÉCIDÉ]** (Othmane, 2026-11-16, version 0.1.2) : on parle au téléphone de la **cabine** avec un **système de dialogue** (sous-titres et choix de réponse, voir §19.6). Le premier appel : Ginette, de l'Agence, se présente, puis musique d'attente, puis une caisse tombe avec le catalogue papier, qui part **enchaîné dans la cabine** (jamais posé au sol).
- **[DÉCIDÉ]** Le catalogue ne s'ouvre **que face à la cabine téléphonique** (Othmane, 2026-11-16).

### 9.2 Payer

- **[PROPOSÉ]** Le joueur dépose ses ressources sur une **zone de dépôt** (une palette, puis une plateforme). Lors de la commande, l'avion passe en rase-mottes et **arrache le dépôt avec un crochet** sans ralentir (gag récurrent). Plus tard, un tapis roulant alimente automatiquement la zone.
- **[PROPOSÉ]** Le paiement se valide dès que le dépôt contient assez ; l'excédent reste sur place.
- **[DÉCIDÉ]** La palette est **grande** et montre **chaque ressource à part** : un tas par ressource, avec sa couleur et son compteur (Othmane, 2026-11-16).
- **[DÉCIDÉ]** On paie avec **ce qu'on porte plus la palette** (Othmane, 2026-11-16) : avec X sel dans les bras et Y sur la palette, on peut acheter un objet à X + Y. Les bras sont vidés en premier.
- **[DÉCIDÉ]** Dans le panier, les articles identiques sont regroupés : « Bâche de séchage ×3 » (Othmane, 2026-11-16).

### 9.3 Recevoir

- **[DÉCIDÉ]** Livraison par avion, rapide et comique, sans attendre le joueur.
- **[DÉCIDÉ]** Délai : **5 secondes** (M-51).
- **[DÉCIDÉ]** **Offres spéciales** : environ une fois par jour de jeu, le téléphone sonne ; on décroche pour voir un article à prix réduit pendant une journée (M-54, N-08).
- **[PROPOSÉ]** La caisse est larguée en parachute **à peu près** au bon endroit. Au début elle tombe parfois à l'eau près du rivage et flotte jusqu'à la plage (gag sans pénalité).
- **[DÉCIDÉ]** Quand une commande contient plusieurs objets à poser, l'avion largue **plusieurs caisses** (Othmane, 2026-11-16). **[PROPOSÉ]** Une caisse par objet à poser (zone, miroir, pompe, décor…) ; les améliorations (tongs, grand seau, tuyaux…) partagent une seule caisse. Les avions passent l'un après l'autre (1,2 s d'écart).
- **[DÉCIDÉ]** Une caisse qui tombe sur quelque chose **reste posée dessus** au lieu de passer au travers (Othmane, 2026-11-16).
- **[PROPOSÉ]** Les avions grossissent avec les paliers : petit hydravion → avion cargo → escadrille → avion absurde qui largue une machine géante entière.
- **[PROPOSÉ]** Les achats ne peuvent jamais être perdus : un objet qui tombe mal finit toujours par revenir sur la plage.

### 9.4 Ce que l'agence refuse de livrer

Gros trou logique : « Si l'agence livre des objets, pourquoi ne pas commander un bateau ? »

**[PROPOSÉ]** Le catalogue contient bien un **bateau**, un **hélicoptère** et un **avion**… à un prix ridicule. On les achète, et on reçoit… **une maquette** (bateau en bouteille, hélico en plastique, avion en papier). Gag visuel, et ça ferme la question sans un mot. **[DÉCIDÉ]** au moins le bateau dès le MVP (M-53).

Autres cas à couvrir de la même façon : gilet de sauvetage (taille enfant), radio (ne capte que la musique d'attente de l'agence), fusée de détresse (feu d'artifice qui dessine le logo de l'agence).

---

## 10. Le personnage, la caméra et les contrôles

- **[DÉCIDÉ]** Jeu principal en **3D low-poly**, dans le même esprit visuel que *How to Fish* (Q-01, 2026-11-16). Voir [15](#15-direction-artistique-et-audio).
- **[DÉCIDÉ]** Caméra **à la première personne** par défaut, avec la possibilité de **basculer en troisième personne** à tout moment (une touche) (Q-13, 2026-11-16).
  - Conséquences : le seau, les mains et les objets tenus doivent être soignés en vue subjective (modèle « bras + objet ») **et** le personnage complet doit exister et être animé pour la vue à la troisième personne.
  - **[PROPOSÉ]** En plus, une **vue de dessus** (mode « construction ») pour placer les machines sur l'île, activée quand on pose un objet.
  - **[PROPOSÉ]** La scène finale du drain bascule automatiquement en troisième personne (plan large) pour montrer le tourbillon, puis rend la main au joueur.
- **[DÉCIDÉ]** On peut **déplacer les objets posés sur l'île**, avec une **grille** (Othmane, 2026-11-16, « Maybe a grid system would be good ? »).
  - **[PROPOSÉ]** Détails du prototype : l'île est découpée en cases de **1 m**. On vise un objet et on appuie sur **G** : l'objet suit le regard case par case, la grille s'affiche autour, et ~~un disque~~ (0.1.5 : les cases qu'il occupera) montre son **emprise** (vert = possible, rouge = impossible). **Clic** pour poser, **G** ou Échap pour annuler (l'objet revient à sa place).
  - **[PROPOSÉ]** Un emplacement est valide si l'emprise (~~un cercle autour de l'objet~~ 0.1.5 : un rectangle de cases qui colle au modèle, voir [19.10](#1910-version-015--la-grille-de-placement-colle-aux-modèles)) tient entièrement sur le sable sec ~~et~~ (0.1.10 **[PROPOSÉ]** : sur des cases **plates et au même niveau**, le plateau de départ ou du sable aplani à la pelle, voir [19.15](#1915-version-0110--la-pelle-les-remarques-dothmane-les-modèles-cc0)) et ne touche ni un autre objet posé, ni un élément fixe (téléphone, palette, palmiers, rochers, repère de niveau d'eau).
  - **[DÉCIDÉ]** On peut **tourner** un objet pendant son déplacement (Othmane, 2026-11-16). **[PROPOSÉ]** Touche R, par quart de tour.
  - **[DÉCIDÉ]** La **palette** est déplaçable ; le **téléphone** reste fixe (Othmane, 2026-11-16).
  - **[DÉCIDÉ]** Tout ce qui apparaît tout seul (tas de sel et de minéraux, caisses livrées, objets sortis des caisses, coquillages) prend **une case de la grille** et ne tombe jamais sur un autre objet (Othmane, 2026-11-16). **[PROPOSÉ]** ~~Un seul tas de sel par zone~~ (v0.22). **[DÉCIDÉ]** Chaque matériau récolté a **son propre tas** à côté de la zone de séchage (Othmane, 2026-11-16). **[PROPOSÉ]** Les tas (sel, minéraux, minéraux rares) sont côte à côte, chacun sur sa case, à 2 ou 3 cases du centre, dans l'emprise de la zone (~~elle grandit : cuvette et bâche 3 m, bassin 4 m~~ 0.1.5 : une colonne de 3 cases à côté du bac) et tournent avec elle ; E ramasse 3 unités du tas visé, le râteau tout le tas ; une caisse ou un objet livré prend la case libre la plus proche de l'endroit prévu.
  - **[DÉCIDÉ]** Avant d'apparaître, les coquillages, noix de coco, caisses et objets livrés vérifient ce qui occupe déjà la place (Othmane, 2026-11-16). **[PROPOSÉ]** S'il n'y a vraiment plus de place (plage pleine), rien n'apparaît plutôt que d'apparaître sur quelque chose. Le joueur compte aussi : rien n'apparaît ni ne se pose sur lui, et une caisse encore en vol réserve déjà sa place.
  - **[DÉCIDÉ]** Quand on ouvre une caisse qui contient un objet à poser (zone de séchage, miroir, condenseur…), le jeu passe **tout seul en mode déplacement** (Othmane, 2026-11-16). **[PROPOSÉ]** S'il y en a plusieurs, ils passent l'un après l'autre ; annuler laisse l'objet sur la case libre où il est apparu.
  - **[PROPOSÉ]** Objets déplaçables : cuvettes, bâches, bassins, miroirs, condenseur, caisse de rations, décors, palette.
- **[PROPOSÉ]** Barre d'outils (M-27, M-18 ; prototype v0.21) : 5 cases en bas de l'écran, choisies avec 1-5 ou la molette. ~~Cases fixes (seau, mains, râteau…)~~ : remplacé en v0.23.
  - **[DÉCIDÉ]** Chaque matériau porté **prend une des 5 cases** en main ; un **menu** permet de **réorganiser** les 5 cases (Othmane, 2026-11-16).
  - **[PROPOSÉ]** 0.1.10 : la barre passe à **6 cases** (touches 1 à 6), et la **pelle** est un outil de départ, en case 2 (voir [19.15](#1915-version-0110--la-pelle-les-remarques-dothmane-les-modèles-cc0)).
  - **[PROPOSÉ]** Détails (v0.23) : au départ, le seau et 4 cases vides (une case vide = les mains nues). Un outil acheté (râteau, tuyaux) prend la première case vide. Un matériau ramassé (sel, minéraux, coquillages…) prend une case vide, avec sa quantité (« Sel ×3 ») ; la même case garde ensuite tout ce matériau. Sans case libre, on ne peut pas le prendre (« Plus de case libre »). La case se libère quand on pose tout à la palette ou qu'on le dépense. ~~La limite de ce qu'on porte en tout (10, 40 avec la brouette) ne change pas.~~ Remplacé en 0.1.4 : plus de limite totale, chaque case porte jusqu'à **64** unités de son matériau (voir [19.9](#199-version-014--tous-les-modèles-64-par-case-pompes-dans-leau)). Un outil obtenu quand la barre est pleine prend la première case qui se libère.
  - **[PROPOSÉ]** Menu « Ranger la barre » : **Tab**. On clique une case puis une autre pour les échanger ; ce qu'on tenait reste en main. Tab ou Échap pour fermer. La disposition est sauvegardée.
  - Le seau ne sert (puiser, verser, vider) que s'il est en main. Les mains servent à ne rien renverser ; E et la pompe à bras marchent avec n'importe quel outil.
  - Le râteau ne ramasse tout d'un coup que s'il est **en main** (clic ou E sur le tas) ; sinon on ramasse 3 par 3.
- **[PROPOSÉ]** Contrôles : clavier/souris et manette (pour le Steam Deck).
- **[DÉCIDÉ]** Le personnage **nage**, avec une **limite d'endurance** (la même que pour courir) : s'il part loin sans plan, il **se noie** (M-24). **[DÉCIDÉ]** Noyade : écran noir, on revient sur la plage de l'île, **sans perte de ressources** (N-04).
- **[PROPOSÉ]** Détails de la nage (prototype) : on nage quand les pieds sont à plus de 1,2 m sous la surface ; on flotte la tête hors de l'eau ; Espace fait monter ; avancer contre le rivage fait se hisser hors de l'eau. L'endurance baisse dans l'eau profonde même immobile (on fait du sur-place), reste stable en marchant sur terre, et ne remonte qu'à l'arrêt sur terre. À zéro dans l'eau : noyade. Course impossible tant qu'on n'est pas remonté à 25 % après épuisement.
- **[DÉCIDÉ]** Pas de mur invisible ni de « réveil sur l'île » pour limiter l'exploration (M-25) : le joueur peut aller **vraiment loin**, mais il n'y trouve rien. S'il est assez malin pour parcourir **des milliers de kilomètres** sans se noyer ni épuiser son endurance, il **termine le jeu** tout simplement (fin secrète). La distance nécessaire doit être immense, et cette liberté ne doit pas coûter de performances. **[DÉCIDÉ]** Pour que ce soit cohérent, le bassin à vider est **réellement immense** (rayon de plusieurs milliers de km) ; seule la zone autour de l'île est détaillée, le reste est un plan d'eau vide (N-06). Voir [8.1](#81-le-problème-déchelle) et [16.3](#163-performances).
- **[PROPOSÉ]** Le personnage ne parle pas, ne pense pas en bulles. Ses émotions passent par l'animation.

---

## 11. La fin : le drain

- **[DÉCIDÉ]** Quand il reste **5 % d'eau ou moins**, un drain est visible au fond de l'océan. Le joueur peut simplement l'ouvrir pour vider le reste. C'est censé être drôle.
- **[DÉCIDÉ]** **Le drain n'est pas obligatoire** (2026-11-16) : le joueur doit pouvoir vider le reste de l'océan sans l'ouvrir s'il le veut. Mais **les derniers litres** ne peuvent partir que de deux façons : **à la main avec le seau**, ou **par le drain**. Les finir au seau doit être volontairement **fastidieux**.
  - **[PROPOSÉ]** Mécanique : sous un certain seuil (ex. les dernières flaques, quelques milliers de litres *(provisoire)*), l'eau est trop peu profonde et trop éparpillée pour les machines. Les pompes aspirent de l'air (gag sonore), les évaporateurs n'ont plus rien à traiter, et ils s'arrêtent d'eux-mêmes. Il ne reste que des flaques au fond, et le seau.
  - **[PROPOSÉ]** Le seau de départ (cosmétiquement usé, voir [12](#12-clins-dœil-lore-uniquement-visuel)) redevient l'outil du moment : boucle de fin qui fait écho au tout début du jeu.
  - **[PROPOSÉ]** Si le joueur vide tout à la main, le drain est à sec. Il l'ouvre quand même (ou marche simplement vers le bord) et la fin se déroule normalement (traversée à pied, avion publicitaire, temps, générique). Le temps affiché sera bien sûr plus long.
  - **[DÉCIDÉ]** Si le drain est ouvert à sec, il fait juste un petit **« plop »** (Q-26, 2026-11-16). Les **succès** (secrets ou non) seront décidés **en fin de projet**.
- **[PROPOSÉ]** Déroulé :
  1. À ≤ 5 %, l'eau restante est assez basse et claire pour révéler, au centre, un **énorme drain** (style bonde de baignoire) avec sa **chaîne**.
  2. Le joueur marche jusqu'au centre sur le fond découvert (trajet long et solennel, musique qui monte).
  3. Il tire la chaîne. Petit « plop ». Silence. Puis **un énorme glouglou de baignoire** : tourbillon géant, l'eau, les poissons et les objets flottants disparaissent dans le trou en quelques secondes.
  4. Le joueur reste au milieu du fond à sec, avec son seau, devant toutes ses machines désormais inutiles.
- **[PROPOSÉ]** Indice dès le début : un **minuscule tourbillon** permanent à la surface, très loin, à l'emplacement du drain. Visible pour les joueurs attentifs. Il grossit très légèrement à mesure que le niveau baisse.
- **[PROPOSÉ]** Peut-on atteindre le drain avant 5 % (scaphandre, plongée) ? Non : avant 5 %, l'eau est trop profonde et trouble pour le voir, et aucun objet du catalogue ne permet de plonger aussi bas. *[QUESTION Q-15]*
- **[DÉCIDÉ]** **Le gag final : l'avion publicitaire** (Q-16, 2026-11-16).
  1. Une fois l'océan drainé, le joueur **traverse à pied** le fond asséché, en direction du bord (vers le monde qu'il voulait rejoindre depuis le début).
  2. Pendant qu'il marche, un **avion publicitaire** de l'agence de livraison passe juste au-dessus de lui, en traînant une banderole.
  3. La banderole annonce que l'agence qu'il utilisait depuis le début est **maintenant aussi une société de transport** et peut vous emmener **de n'importe où à n'importe où**. Autrement dit : il aurait pu juste appeler.
  4. Le joueur voit l'avion s'éloigner. **Générique. Fin.**
- **[PROPOSÉ]** Détails de mise en scène :
  - La caméra peut passer brièvement en troisième personne (plan large : petit personnage avec son seau, immense fond asséché, avion au-dessus), puis rester sur l'avion qui s'éloigne.
  - Le pilote est celui de toutes les livraisons (avec sa barbe blanchie, voir [12](#12-clins-dœil-lore-uniquement-visuel)), et fait son petit signe de la main.
  - Le téléphone rouge, resté sur l'île au loin, peut sonner une seule fois au même moment (optionnel).
- **[DÉCIDÉ]** La banderole porte un **vrai slogan écrit** (court, traduit). Ce n'est pas le seul texte du jeu : le texte dans les textures est permis mais reste sobre (voir [12](#12-clins-dœil-lore-uniquement-visuel)) (Q-23, 2026-11-16).
- **[DÉCIDÉ]** **Fin de la run** (Q-24, 2026-11-16) :
  1. Dès que l'avion publicitaire s'éloigne, **avant le générique**, un écran affiche le **temps de partie** du joueur.
  2. Générique.
  3. **Retour au menu principal.** La run est terminée ; il n'y a pas d'exploration après la fin.
- **[PROPOSÉ]** Le temps affiché est le **temps de jeu réel** (chronomètre qui ne tourne que quand la partie est ouverte et non en pause), enregistré dans la sauvegarde. La sauvegarde terminée est marquée « finie » et le meilleur temps est conservé dans le menu.
- **[DÉCIDÉ]** Une sauvegarde déjà terminée **se rouvre juste avant l'ouverture du drain** au fond de l'océan (Q-25, 2026-11-16).
  - **[PROPOSÉ]** Techniquement : un **point de reprise** est enregistré automatiquement quand le joueur arrive devant le drain (ou au passage sous le seuil des derniers litres). Charger une sauvegarde finie recharge ce point. Le temps de la première fin reste celui affiché dans le menu.

---

## 12. Clins d'œil (lore uniquement visuel)

**[DÉCIDÉ]** Pas d'histoire à proprement parler. Pas de livres, pas de notes, pas de textes à lire. Seulement des clins d'œil compréhensibles à l'œil, pour les joueurs attentifs.

**[PROPOSÉ]** Règles :

- **[DÉCIDÉ]** Pas de texte *de lore* (rien à lire pour comprendre une histoire). Du texte peut apparaître dans les textures quand c'est nécessaire (logo et nom de l'agence, caisses, banderole finale…), mais il reste **rare et sobre** (2026-11-16).
- Aucun clin d'œil n'est obligatoire pour finir le jeu.
- Chaque clin d'œil se comprend en une image.

**[PROPOSÉ]** Pistes (à trier) :

| Thème | Clin d'œil | Où / quand |
|---|---|---|
| Le drain | Le petit tourbillon visible dès le début | Surface, toute la partie |
| La baignoire | Le fond de l'abysse est carrelé ; un gigantesque canard en caoutchouc échoué ; un rocher en forme de savon ; le trou de trop-plein dans une falaise | Abysse, T5-T6 |
| Le téléphone | Le câble du téléphone court sur le fond marin… jusqu'à un autre téléphone, ou jusqu'au drain | Fond découvert |
| Les naufragés d'avant | D'autres petites îles découvertes avec un téléphone d'une autre couleur, rouillé, et un seau abandonné ; un squelette assis tenant un seau | Plateau, talus |
| Les réveils | Des traits gravés sur un palmier (comme un calendrier de prisonnier) qui augmentent à chaque fois que le joueur « se noie » et se réveille | Île de départ |
| L'agence | Le pilote vieillit au fil de la partie (barbe qui pousse, puis cheveux blancs) | Chaque livraison |
| L'agence | Le logo de l'agence ressemble de près à… un drain | Caisses, avions |
| Le temps | Le seau de départ s'abîme, se rapièce, se décolore | Toute la partie |
| Bouteille à la mer | Une bouteille contenant un dessin (pas de texte) : quelqu'un qui tire une chaîne | Plateau |
| Le catalogue | Une page du catalogue montre un drain barré, ou en rupture de stock | Catalogue, tardif |

---

## 13. Mini-jeu clicker (dans la version PC)

- **[DÉCIDÉ]** Le jeu PC contient un mini-jeu : même concept, en clicker, pixel art très simple.
- **[PROPOSÉ]** Accès diégétique : on achète au catalogue une **console portable** (design original, pas une copie d'une vraie console). Le personnage s'assoit et joue ; l'écran de la console prend tout l'écran.
- **[PROPOSÉ]** Contenu : cliquer pour puiser, achats d'améliorations, automatisation, et un drain à la fin. Durée 20 à 40 minutes.
- **[QUESTION Q-17]** Le clicker influence-t-il le jeu principal ? Recommandation : **seulement des récompenses cosmétiques** (chapeau, couleur de seau) ou une petite aide unique, pour ne pas inciter à « farmer » le mini-jeu.
- **[PROPOSÉ]** Le clicker est codé dès le départ comme un **module autonome** (sa propre scène, ses propres données) pour être réutilisé tel quel sur mobile.
- **[PROPOSÉ]** Clin d'œil : dans le clicker, le personnage pixel art a lui aussi… une console portable.

---

## 14. Version mobile (future)

- **[DÉCIDÉ]** On reprendra le clicker pour le mettre sur téléphone. C'est pour beaucoup plus tard.
- **[PROPOSÉ]** Ce qu'il faut préparer *dès maintenant* pour ne pas tout refaire :
  - Logique du clicker séparée de son affichage.
  - Interface pensée pour le tactile (gros boutons, pas de survol souris obligatoire).
  - Résolution de base pixel art compatible portrait (ex. 180×320 ou 360×640, mise à l'échelle entière).
- **[QUESTION Q-14]** Modèle économique mobile : payant, gratuit sans pub, gratuit avec pub récompensée ? Android seulement ou aussi iOS (compte Apple Developer requis, 99 $/an, et un Mac pour l'export) ?

---

## 15. Direction artistique et audio

- **[DÉCIDÉ]** Jeu principal : 3D low-poly, dans le même esprit visuel que *How to Fish* (Q-01).
- **[PROPOSÉ]** Couleurs vives, eau très soignée (c'est le personnage principal du jeu). Ciel et lumière qui changent avec le jour.
- **[DÉCIDÉ]** La nuit, une **lune** à la place du soleil (le soleil disparaît sous l'horizon), et pas de lueur étrange à l'horizon (Othmane, 2026-11-16).
- **[PROPOSÉ]** Mini-jeu et mobile : pixel art très simple, palette restreinte (ex. 16 couleurs).
- **[PROPOSÉ]** Audio : vagues, vent, mouettes au début, puis bruits de machines de plus en plus présents. Musique d'attente du téléphone qui devient un thème récurrent (et peut-être la musique du générique). Le son du drain est le moment sonore le plus important du jeu.
- **[PROPOSÉ]** Contraste voulu : l'île est paisible au début et devient une usine bruyante. Le silence après le drain doit frapper.

---

## 16. Tech stack et architecture

### 16.1 Choix techniques

| Sujet | Choix | Statut |
|---|---|---|
| Moteur | **Godot 4.7.2** stable (dernière stable au démarrage, figée ; montée de version = décision consignée) | **[DÉCIDÉ]** (M-09) |
| Langage | **GDScript** typé statiquement. C# écarté : plus lourd pour l'export mobile et inutile ici | **[PROPOSÉ]** |
| Rendu PC | Moteur de rendu **Forward+** | **[PROPOSÉ]** |
| Rendu clicker / mobile | **Compatibility** (OpenGL) ou **Mobile** | **[PROPOSÉ]** |
| Plateforme cible | Windows 10/11 64 bits, export `.exe` | **[DÉCIDÉ]** |
| Distribution | Steam ? itch.io ? *[QUESTION Q-18]* | Ouvert |
| Versionnage | Git + GitHub. **Git LFS** pour les gros fichiers (modèles 3D, textures, sons) | **[PROPOSÉ]** |
| Tests | **Lanceur de tests maison** (`game/tests/run_tests.gd`, sans dépendance) pour la logique (océan, sauvegarde, contrôles) ; GUT ou gdUnit4 restent possibles si les besoins grandissent | **[PROPOSÉ]** |
| CI | GitHub Actions : tests + lancement de la scène principale à chaque PR ; export Windows plus tard | **[DÉCIDÉ]** (M-13) |
| Sauvegarde | Fichier JSON versionné dans `user://`, sauvegarde automatique régulière | **[PROPOSÉ]** |
| Langues | Interface en français et anglais (peu de texte dans le monde, mais les textures avec texte devront exister en plusieurs langues ou rester en une langue neutre) | **[PROPOSÉ]** |

### 16.2 Simulation de l'eau (le point technique critique)

Une vraie simulation de fluide d'un océan est **impossible** en temps réel et inutile.

**[PROPOSÉ]** On simule les *chiffres*, on fait *semblant* à l'écran :

- **L'océan** = un grand plan d'eau unique, placé à la hauteur calculée depuis le volume (voir [8.3](#83-le-niveau-de-leau)). Les vagues, l'écume sur le rivage et la transparence sont faites par **shader** (déplacement de sommets + texture de profondeur pour l'écume).
- **Le seau, les bassins, les tuyaux** = des maillages dont le niveau d'eau monte/descend (un simple plan qui se déplace), avec particules pour les éclaboussures.
- **Le tourbillon final** = shader de distorsion + animation de maillage + particules, scène scriptée.
- **La production** des machines est calculée par la logique de jeu à intervalle fixe (ex. 10 fois par seconde), indépendamment de leurs animations.

### 16.3 Performances

**[PROPOSÉ]** Points d'attention :

- **Fond marin** : terrain détaillé seulement autour de l'île (quelques km) → maillage découpé en morceaux avec niveaux de détail (LOD), ou plugin de terrain (ex. Terrain3D). Brouillard pour cacher l'horizon.
- **Nombre de machines** : des centaines au palier T4 → **MultiMeshInstance3D** pour les objets répétés, animations simples, production calculée en lot.
- **Ressources physiques** : afficher les tas de sel par paliers (petit tas, gros tas, montagne) plutôt qu'un objet par unité.
- **Grands nombres** : `float` de Godot (64 bits) suffit jusqu'à ~10³⁰⁸ ; pas besoin d'une bibliothèque de grands nombres si le volume reste ≤ 10¹⁸ L. À surveiller : précision des petits ajouts sur un gros total (on stocke le volume **retiré**, pas le volume restant, pour éviter les erreurs d'arrondi).
- **[DÉCIDÉ]** **Machine de référence** : le PC d'Othmane (processeur i9, carte RTX avec **4 Go de mémoire vidéo**, ~12 Go de RAM) (M-11). Cible : 60 i/s en 1080p sur cette machine. Les 4 Go de VRAM imposent des textures sobres (le low-poly aide).
- **[PROPOSÉ]** **Distances immenses** (fin secrète à la nage, voir [10](#10-le-personnage-la-caméra-et-les-contrôles)) : les nombres à virgule de Godot perdent en précision au-delà de quelques dizaines de km. Solution : **origine flottante** (le monde est recentré sur le joueur régulièrement) ; loin du bassin, l'océan n'est qu'un plan d'eau qui suit le joueur, sans contenu, donc sans coût.

### 16.4 Données du jeu pilotées par fichiers

**[PROPOSÉ]** Tout ce qui s'équilibre vit dans des **Resources Godot** (`.tres`) ou des fichiers de données, pas dans le code :

- articles du catalogue (nom, icône, prix, palier, débit),
- ressources (rendements, rareté),
- paliers, jalons, zones du fond marin.

Ça permet d'équilibrer sans recompiler et de partager les données entre le jeu PC et le clicker.

### 16.5 Arborescence prévue du dépôt

```
/
├── README.md
├── HANDOFF.md            # journal vivant des décisions / modifications / tests
├── CLAUDE.md             # règles pour les sessions d'IA (mise à jour de HANDOFF)
├── docs/
│   └── PRD.md            # ce document
├── game/                 # projet Godot principal (PC)
│   ├── project.godot
│   ├── core/             # logique pure : économie, océan, sauvegarde (testable)
│   ├── data/             # Resources d'équilibrage (.tres)
│   ├── scenes/           # île, océan, machines, UI, téléphone
│   ├── clicker/          # mini-jeu autonome (réutilisé sur mobile)
│   ├── assets/           # modèles, textures, sons (Git LFS)
│   └── tests/            # tests GUT / gdUnit4
└── tools/                # simulateur d'économie, scripts
```

*[QUESTION Q-20]* Le projet mobile sera-t-il un **second projet Godot** qui réutilise `core/` et `clicker/`, ou le **même projet** avec des préréglages d'export différents ? Recommandation : même projet tant que possible, décision à reprendre au moment du portage.

---

## 17. Problèmes identifiés et propositions

Liste exhaustive des risques repérés en décortiquant l'idée. Chaque ligne renvoie à la section qui traite la proposition.

### 17.1 Conception

| # | Problème | Gravité | Proposition | Voir |
|---|---|---|---|---|
| P-01 | **L'échelle** : un seau ne fait rien à un océan, le niveau ne bouge pas pendant des heures | Haute | Bassin fini calibré, compteurs, jalons comparatifs, plateau peu profond qui révèle beaucoup tôt | 8.1, 8.2 |
| P-02 | **L'ennui du début** : porter un seau est répétitif | Haute | Premier achat < 3 min, T1 < 15 min, le seau ne reste pas longtemps la seule action | 5.4 |
| P-03 | **L'ennui du milieu** : quand tout est automatisé, il n'y a plus rien à faire | Haute | Exploration du fond découvert, réagencement de l'île, chaque palier change la façon de jouer | 5.5, 7, 8.4 |
| P-04 | **Où va l'eau ?** L'évaporation devrait faire pleuvoir | Moyenne | Les nuages partent toujours au loin ; machines absurdes ; le drain comme vraie réponse | 8.6 |
| P-05 | **Pourquoi ne pas commander un bateau ?** | Haute (casse le concept) | L'agence livre des maquettes | 9.4 |
| P-06 | **Pourquoi ne pas nager ?** | Moyenne | Trop loin = on se réveille sur l'île | 10 |
| P-07 | **La fin peut frustrer** : « J'ai tout fait pour rien ? » | Moyenne | C'est le but, mais on adoucit : indices visibles depuis le début, récompense post-générique, exploration libre | 11 |
| P-08 | **Le drain atteignable trop tôt** (plongée, exploit) | Moyenne | Invisible et inaccessible avant 5 % | 11 |
| P-18 | **Finir sans le drain** : si les machines vident tout, la blague du drain disparaît | Moyenne | Les machines s'arrêtent sur les derniers litres ; seul le seau (fastidieux) ou le drain les finit | 11 |
| P-09 | **La place sur l'île** : trop de machines, trop de stock | Moyenne | L'île grandit avec la baisse ; stock affiché par paliers ; entrepôts au catalogue | 8.5, 16.3 |
| P-10 | **Économie à une seule ressource utile** : le sel perd sa valeur | Moyenne | Troc direct et chaque palier exige une ressource plus rare | 6.2 |
| P-11 | **La vie marine** : ton morbide si les poissons meurent | Moyenne | Les poissons reculent et partent par le drain | 8.7 |
| P-12 | **Lacs résiduels** dans les creux du fond | Moyenne | Fond modelé sans cuvettes ; flaques seulement décoratives | 8.3 |
| P-13 | **Le lore « uniquement visuel »** peut passer inaperçu | Basse | Plusieurs niveaux de lecture, un clin d'œil évident (canard géant) et des subtils | 12 |
| P-14 | **Le mini-jeu clicker** peut devenir une meilleure source de ressources que le jeu | Basse | Récompenses cosmétiques seulement | 13 |
| P-15 | **Une livraison qui tombe à l'eau** fait perdre l'achat | Basse | Les objets reviennent toujours sur la plage | 9.3 |
| P-16 | **Peu de texte** dans le monde, mais l'UI doit être claire ; les textures avec texte doivent être traduites | Moyenne | Pictogrammes en priorité ; textes de texture rares, regroupés dans une liste pour la traduction ; UI de menu traduite | 9.1, 16.1 |
| P-17 | **Ressemblance involontaire** avec un jeu existant (incrémental insulaire, console portable) | Moyenne | Design original des objets, de la console, de l'agence ; pas de référence directe à une marque | 13 |

### 17.2 Technique

| # | Problème | Gravité | Proposition | Voir |
|---|---|---|---|---|
| T-01 | **Physique de l'eau en Godot** : pas de fluide réaliste à cette échelle | Haute | Plan d'eau unique + shaders ; la simulation est numérique, pas physique | 16.2 |
| T-02 | **Taille du monde** : terrain de 16 km | Haute | Terrain découpé + LOD + brouillard ; prototype de performance tôt | 16.3 |
| T-03 | **Des centaines de machines animées** | Moyenne | MultiMesh, production calculée en lot | 16.3 |
| T-04 | **Grands nombres et précision** | Moyenne | Float 64 bits, stocker le volume retiré | 16.3 |
| T-05 | **Hauteur d'eau ↔ volume** pour un fond irrégulier | Moyenne | Table pré-calculée depuis le terrain | 8.3 |
| T-06 | **Sauvegardes qui cassent** quand les données changent | Moyenne | Fichier versionné + migrations | 16.1 |
| T-07 | **Portage mobile** coûteux si le clicker est mêlé au jeu PC | Moyenne | Module autonome dès le départ | 13, 14 |
| T-08 | **Équilibrage à l'aveugle** | Haute | Simulateur d'économie avant les réglages en jeu | 6.4 |
| T-09 | **Gros fichiers dans Git** | Basse | Git LFS dès le premier asset | 16.1 |
| T-10 | **Signature et antivirus Windows** : un `.exe` non signé déclenche SmartScreen | Basse | Normal pour un jeu indé ; Steam règle le problème | 16.1 |

---

## 18. Questions ouvertes

Questions qui demandent **la décision d'Othmane**. Une réponse = une entrée dans HANDOFF.md + mise à jour de ce document.

> **Les questions détaillées pour construire le MVP (M-01 à M-85) sont dans [`QUESTIONS_MVP.md`](QUESTIONS_MVP.md).** Plusieurs reprennent des questions ci-dessous (Q-03, Q-04, Q-05, Q-06, Q-08 à Q-12, Q-19, Q-21, Q-22) : y répondre là-bas les tranche aussi ici.

**Déjà tranchées :** Q-01 → 3D low-poly style *How to Fish* · Q-07 → troc direct · Q-13 → première personne avec bascule en troisième personne · Q-16 → gag final de l'avion publicitaire · Q-23 → slogan écrit, texte sobre autorisé dans les textures · Q-24 → temps de partie affiché avant le générique, puis retour au menu · Q-25 → une sauvegarde finie se rouvre juste avant le drain · Q-26 → « plop » à sec, succès décidés en fin de projet · via le questionnaire MVP : Q-03 (pas de progression hors ligne sur PC), Q-04 (perle : oui), Q-05 (survie légère), Q-06 (jour/nuit avec effet), Q-11 (catalogue mixte), Q-12 (maquettes : oui), Q-19 (PC d'Othmane comme référence), Q-21 (« Drain the Ocean ») (toutes le 2026-11-16).

**Questions de suite N-01 à N-10 : tranchées, voir [19.3](#193-décisions-des-questions-de-suite-n-01-à-n-10).**

| ID | Question | Options | Recommandation |
|---|---|---|---|
| **Q-02** | Durée de jeu visée ? | 3-5 h / 6-10 h / 15 h+ | **6-10 h** |
| **Q-08** | Gérer l'énergie à partir de T3 (éoliennes, panneaux) ? | Oui (couche logistique) / Non (machines autonomes) | **Oui, mais simple** (une jauge globale, pas de câbles) |
| **Q-09** | Pluie qui fait remonter le niveau ? | Effet réel / Purement visuel / Pas de pluie | **Purement visuel** |
| **Q-10** | Les poissons ? | Partent par le drain / Absents / Autre | **Partent par le drain** |
| **Q-14** | Mobile : modèle économique et plateformes ? | Payant / Gratuit / Gratuit + pub ; Android / Android + iOS | À décider plus tard |
| **Q-15** | Le drain peut-il être atteint avant 5 % ? | Jamais / Secret pour speedrunners | **Jamais** (peut-être un succès secret si on le *voit* tôt) |
| **Q-17** | Le clicker donne-t-il des bonus au jeu principal ? | Cosmétiques / Petits bonus / Rien | **Cosmétiques** |
| **Q-18** | Distribution PC ? | Steam / itch.io / les deux | **itch.io pour les tests, Steam pour la sortie** |
| **Q-20** | Mobile : même projet Godot ou projet séparé ? | Même projet / Séparé | **Même projet**, à revoir au portage |
| **Q-22** | Le personnage : apparence, genre, personnalisable ? | Fixe / Personnalisable | Fixe et neutre pour le MVP (M-23), à concevoir plus tard |

---

## 19. Périmètre MVP et feuille de route

### 19.1 Le MVP / la démo

**[DÉCIDÉ]** Le [questionnaire MVP](QUESTIONS_MVP.md) a reçu ses réponses le 2026-11-16 ; elles sont listées en [19.2](#192-décisions-du-questionnaire-mvp) et priment sur la liste ci-dessous en cas de différence.

**But :** vérifier que la boucle *puiser → sécher → commander → s'équiper* est amusante, puis s'en servir comme démo publique.

**Dans le MVP :**

- **Monde :** l'île de départ (~40 m) avec téléphone, seau, cuvette rocheuse, palmiers, palette de dépôt ; océan shader ; fond marin seulement autour de l'île ; cycle jour/nuit ; nuages ; mouettes, poissons, un crabe ; une jauge à aiguille pour le niveau d'eau ; noix de coco sur les palmiers.
- **Personnage :** caméra 1re personne + bascule 3e personne ; marcher, courir, sauter, nager ; endurance (ne remonte pas dans l'eau), faim et soif légères ; noyade avec retour sur la plage ; barre d'outils de 5 cases.
- **Seau :** puiser (maintenir le clic dans l'eau), verser, aucun ralentissement, quelques gouttes purement visuelles.
- **Séchage :** zones avec surface et capacité, évaporation selon le soleil, récolte manuelle puis au râteau.
- **Ressources :** sel, minéraux, minéraux rares, coquillages (réapparition sur la plage chaque matin), perle ; transport à la main au début, stock automatique après un achat.
- **Téléphone :** premier appel tutoriel, catalogue illustré, panier, palette de dépôt arrachée par l'avion, livraison en parachute en 5 s, offres spéciales environ une fois par jour, ouverture des caisses, pose avec aperçu fantôme.
- **Contenu :** paliers T0 à T2, une quinzaine d'objets (voir [questionnaire, section I](QUESTIONS_MVP.md#i-le-contenu-du-catalogue-du-mvp)), jusqu'au moulin-pompe, première machine automatique. Ajouts validés (N-02, N-07, N-09) : **brouette** (T1 ; **[PROPOSÉ]** 30 sel, porte 40 unités au lieu de 10 ; 0.1.4 : 128 par case au lieu de 64), **bâche de condensation** (T1, eau douce), **rations** (T1), **toboggan à sacs** jusqu'à la palette (T2), un **objet spécial payé en perle**.
- **Progrès :** compteur de litres retirés, % restant, 3 premiers jalons comparatifs.
- **[DÉCIDÉ]** **Outils admin** pour tester (beaucoup de ressources, accélérer le temps, vider l'océan…), regroupés dans un seul module facile à retirer avant la démo (Othmane, 2026-11-16). Ils sont coupés d'office dans une version exportée « release ».
- **Fin de démo :** teaser des machines T3, puis écran de fin de démo. La vraie fin (drain, avion publicitaire, temps, générique) est construite mais accessible seulement par une touche de debug.
- **Système :** menu principal, 3 emplacements, sauvegarde automatique, chronomètre, options de base, FR + EN.
- **Clins d'œil :** les traits sur le palmier, le pilote qui fait coucou. Le tourbillon lointain est **hors MVP** (N-01).

**Hors MVP :** tourbillon lointain, clicker, énergie, paliers T3-T6, fond marin complet, île qui grandit, pluie, manette, vue de dessus, succès, fin secrète à la nage (l'architecture la prévoit).

**Critère de réussite :** 30 à 45 minutes de jeu qu'un testeur extérieur trouve amusantes, sans explication.

### 19.2 Décisions du questionnaire MVP

Toutes **[DÉCIDÉ]** le 2026-11-16 par Othmane. Les commentaires d'Othmane sont repris en italique.

**Périmètre.** M-01 prototype interne qui devient la démo · M-02 30-45 min · M-03 paliers T0-T2 · M-04 vraie fin construite, accessible par touche de debug seulement · M-05 fin de démo en teaser (silhouettes T3, gros avion, écran de fin) · M-06 greybox puis packs low-poly CC0 · M-07 packs pour le MVP, *sur-mesure fait par nous sous Blender, plus tard* · M-08 FR + EN, traduction en place dès le début.

**Technique.** M-09 dernière Godot 4.x stable, figée · M-10 GDScript typé · M-11 référence : i9, RTX 4 Go VRAM, ~12 Go RAM · M-12 Git LFS (*quota à surveiller*) · M-13 tests automatiques sur chaque PR · M-14 1080p de référence, fenêtré + plein écran, 16:9 et ultra-large.

**Contrôles.** M-15 disposition du clavier détectée + touches réassignables · M-16 manette plus tard · M-17 courir + petit saut · M-18 clic gauche = outil, E = interagir, molette/1-5 = outils · M-19 3e personne au-dessus de l'épaule, orbite souris · M-20 bascule avec V · M-21 FOV, balancement de tête désactivable, sensibilité · M-22 placement en 1re personne avec aperçu fantôme. **[DÉCIDÉ]** On pourra **déplacer les objets déjà posés sur l'île** (zones de séchage, palette, décors…), à implémenter plus tard (Othmane, 2026-11-16). **[DÉCIDÉ]** Implémenté avec une **grille** (v0.16, voir [10](#10-le-personnage-la-caméra-et-les-contrôles)) ; G = déplacer.

**Personnage.** M-23 fixe et neutre pour le MVP · M-24 nage avec **endurance** (aussi pour courir), noyade si on part loin sans plan · M-25 pas de limite artificielle : *on peut aller très loin sans rien trouver ; des milliers de km sans se noyer = fin du jeu* · M-26 **survie légère : endurance façon BotW, faim et soif légères** · M-27 barre de 5 cases · M-28 **ressources portées à la main au début, stock automatique après un achat** (brouette, tapis).

**Seau.** M-29 maintenir le clic dans l'eau ~1 s, *temps améliorable* · M-30 10 L · M-31 **aucun ralentissement** · M-32 *quelques gouttes purement visuelles, sans effet sur la quantité* · M-33/M-34 l'eau compte comme retirée dès qu'elle est puisée ; **la reverser dans la mer ou sur le sable la rend à l'océan** (*sur le sable, elle finit par y retourner*) · M-35 grand seau 20 L + palanche.

**Séchage.** M-36 cuvette rocheuse de départ, bâche en premier achat · M-37 45 s, *améliorable plus tard* · M-38 capacité maximale · M-39 récolte au clic puis au râteau · M-40 jour de 20 min, ×0,3 la nuit · M-41 pose libre sur sable plat · M-42 le séchage continue partout.

**Ressources.** M-43 sel 1 garanti, minéraux 10 %, rares 0,5 %, coquillage 3 % au puisage · M-44 coquillages qui réapparaissent chaque matin (**[PROPOSÉ]** 5 sur la plage chaque matin, ramassés avec E, 2 % de perle) · M-45 **perle dans le MVP** · M-46 pas de limite de stockage.

**Téléphone.** M-47 catalogue mixte · M-48 premier appel en tutoriel muet · M-49 panier · M-50 palette arrachée au crochet · M-51 **livraison en 5 s** · M-52 caisse ouverte avec E · M-53 gag du bateau · M-54 **le téléphone sonne parfois pour des offres spéciales** · M-55 musique d'attente devenue thème · M-56 pas de revente.

**Catalogue.** M-57 liste validée telle quelle · M-58 pompe à bras active · M-59 rythme : premier achat < 3 min, T1 ~15 min, T2 ~20 min, moulin-pompe ~40 min.

**Monde.** M-60 île ~40 m · M-61 contenu de départ validé · M-62 niveau honnête, *mais il doit bouger un tout petit peu dans la démo, avec un repère de niveau d'eau* · M-63 ~2 × 10¹³ L (*remplacé par N-06 : 10¹⁸-10¹⁹ L*) · M-64 fond modélisé autour de l'île seulement · M-65 nuages, pas de pluie · M-66 mouettes, poissons, un crabe · M-67 **pas de tourbillon lointain** (*confirmé par N-01*).

**Interface.** M-68 HUD *petit, simple et comique* · M-69 tutoriel muet par icônes · M-70 3 premiers jalons · M-71 menu avec 3 emplacements · M-72 options complètes · M-73 chronomètre caché, option speedrun · M-74 pas de pause dans le catalogue.

**Audio.** M-75 ambiance + courts morceaux · M-76 banques CC0.

**Sauvegarde.** M-77 auto toutes les 2 min, après achat, en quittant · M-78 **sauvegarde manuelle en plus, qui remplace la dernière sauvegarde auto** · M-79 pas de progression hors ligne.

**Hors MVP.** M-80 clicker · M-81 énergie · M-82 pluie · M-83 fond complet, T3-T6, île qui grandit · M-84 clins d'œil du MVP : traits sur le palmier, pilote qui fait coucou (*tourbillon retiré par N-01*) · M-85 nom : « Drain the Ocean ».

### 19.3 Décisions des questions de suite (N-01 à N-10)

Toutes **[DÉCIDÉ]** le 2026-11-16 par Othmane.

| ID | Décision |
|---|---|
| N-01 | Le tourbillon lointain n'est **pas** dans le MVP |
| N-02 | Nourriture : noix de coco + rations au catalogue ; eau douce : bâche de condensation (T1) |
| N-03 | Faim/soif à zéro : pas de mort, l'endurance maximale baisse |
| N-04 | Noyade : écran noir, retour sur la plage, sans perte |
| N-05 | Endurance ~20 s de course / ~60 s de nage ; remonte à l'arrêt sur terre, **jamais dans l'eau** ; améliorable |
| N-06 | Bassin réellement immense (milliers de km de rayon), seule la zone de l'île détaillée, volume ~10¹⁸-10¹⁹ L |
| N-07 | Perle : ~2 % des coquillages ramassés, sert à un objet spécial ou cosmétique |
| N-08 | Offres spéciales : le téléphone sonne ~1 fois par jour de jeu, un article à prix réduit pendant une journée |
| N-09 | Brouette (T1), toboggan à sacs jusqu'à la palette (T2), tapis roulant en T3 |
| N-10 | Repère de niveau : jauge à aiguille qui amplifie les dixièmes de millimètre |

### 19.4 Feuille de route

| Jalon | Contenu | Critère de réussite |
|---|---|---|
| **M0 — Fondations** | Projet Godot, structure du dépôt, CI, tests, sauvegarde, scène greybox jouable | Les tests passent en CI ; on se promène sur l'île greybox en 1re/3e personne. **Fait (PR #2, 2026-11-16)** |
| **M1 — Prototype de l'eau** | Île grise, plan d'eau shader, terrain de fond, variable volume → hauteur, perf mesurée | 60 i/s avec le terrain complet ; on peut faire baisser l'eau avec une touche de debug. **En partie fait (2026-11-16)** : hauteur honnête volume → niveau, jauge à aiguille, touche F7 ; restent le shader d'eau, le terrain de fond et la mesure de perf. |
| **M2 — Boucle de base** | Personnage, seau, bassin de séchage, ressources, téléphone, une livraison | On peut puiser → sécher → payer → recevoir un objet. **Prototype livré en PR (2026-11-16)** : seau, cuvette, bâche, grand seau, bateau en bouteille, palette de dépôt, téléphone et catalogue, avion et caisse en parachute, cycle jour/nuit. |
| **M3 — Tranche verticale** | T0 à T2 complets, simulateur d'économie, 3 clins d'œil, sons de base | 45 min de jeu amusantes testées par quelqu'un d'autre |
| **M4 — Contenu** | T3 à T6, fond marin complet, toutes les zones | On peut finir le jeu (avec debug d'accélération) |
| **M5 — La fin** | Drain, tourbillon, traversée à pied, avion publicitaire, écran du temps de partie, générique, retour au menu | La scène fait rire un testeur |
| **M6 — Clicker** | Mini-jeu pixel art complet dans la console portable | Jouable du début au drain |
| **M7 — Finition** | Équilibrage, polish, options, langues, succès | Version 1.0 PC |
| **M8 — Mobile** | Portage du clicker | Plus tard |

---

### 19.5 Réalisation de la démo

Ce qui a été construit pour finir la démo (Othmane, 2026-11-16 : « continue à implémenter toutes les fonctionnalités restantes » **[DÉCIDÉ]**). Les détails sont **[PROPOSÉ]** tant qu'Othmane ne les a pas validés.

- **[DÉCIDÉ]** Sous l'eau, l'image prend un **filtre bleu** (Othmane, 2026-11-16). **[PROPOSÉ]** Filtre bleu-vert qui ondule, bords assombris et brouillard bleu épais quand les yeux sont sous la surface ; la surface se voit d'en dessous.
- **[PROPOSÉ]** Monde vivant (v0.24) : océan à vagues (trois vagues de Gerstner, 20 cm environ), turquoise sur le sable et bleu profond au large selon l'épaisseur d'eau, écume au bord du rivage ; fond marin (rochers, algues, coraux) seulement autour de l'île, de 28 à 110 m ; nuages en boules qui dérivent avec le vent ; 5 mouettes qui tournent au-dessus de l'île ; 3 bancs de poissons qui suivent l'eau quand elle baisse (et disparaissent quand il n'y en a plus assez) ; un crabe qui trottine de côté au bord de la plage. Rien de tout cela n'a d'effet sur le jeu.

- **[PROPOSÉ]** Téléphone (v0.25) :
  - **Premier appel (M-48)** : en nouvelle partie, le téléphone sonne (il tremble, « Dring ! »). E décroche : 6 s de musique d'attente, puis une caisse tombe avec le **catalogue papier** (un décor qu'on peut déplacer, inutile : tout se commande au téléphone). Ensuite, E sur le téléphone ouvre le catalogue.
  - **Offres spéciales (M-54)** : chaque matin, 70 % de chances que le téléphone sonne pour une offre. Décrocher ouvre le catalogue : un article achetable est **à moitié prix** jusqu'à la fin de la journée (arrondi au-dessus, jamais gratuit). Un appel manqué, c'est une offre manquée (la sonnerie s'arrête avec la nuit).
  - **Crochet (M-50)** : l'avion de la première caisse d'une commande passe en rase-mottes et arrache le paiement de la palette avec un crochet au bout d'une corde ; le paquet (aux couleurs des ressources payées) part avec lui. Le pilote fait coucou par la vitre.
  - Les vieilles sauvegardes considèrent le premier appel comme déjà fait.

- **[PROPOSÉ]** Toboggan à sacs (v0.26 ; N-09, M-28 « stock automatique après un achat ») : T2, 250 sel + 25 minéraux, se pose et se déplace comme les autres objets. E dessus : on y jette tout ce qu'on porte, ça glisse jusqu'à la palette (plus besoin d'y marcher). Toutes les 8 s, il envoie aussi à la palette les tas des zones de séchage dont le bord est à moins de 3 m de lui. Plusieurs toboggans peuvent servir plusieurs zones.
- **[PROPOSÉ]** Objet payé en perle (v0.26 ; N-07) : le **flamant rose gonflable**, 1 perle, T1, un seul par partie, purement décoratif.

- **[PROPOSÉ]** Jalons comparatifs (v0.27 ; M-70) : en haut à droite, le pictogramme du prochain jalon se remplit d'eau à mesure qu'on vide l'océan (pas de texte). En le franchissant, un grand pictogramme plein apparaît avec sa récompense, posée sur la palette. Les trois de la démo : **baignoire** (150 L, +10 sel), **piscine gonflable** (2 000 L, +1 perle), **piscine** (30 000 L, +5 minéraux rares) ; ensuite la piscine olympique (2,5 millions de litres). La liste est dans les données (`GameConfig.milestones`). Un jalon franchi le reste, même si l'eau retourne à l'océan.

- **[PROPOSÉ]** Menus et options (v0.28 ; M-21, M-71, M-72, M-73, M-77) : au lancement, un **menu principal** avec 3 emplacements de sauvegarde (temps de jeu, litres retirés, date), Jouer / Effacer, Options, Quitter ; le jeu est en pause derrière et rien n'est sauvegardé tant qu'aucun emplacement n'est choisi. **Échap** ouvre le menu pause (vraie pause : le chronomètre s'arrête) : Reprendre, Sauvegarder, Options, Menu principal, Quitter ; il ne s'ouvre pas par-dessus le catalogue (M-74). **Options** (à part des parties, `user://settings.json`) : champ de vision 60-110, sensibilité, volume, balancement de la tête, plein écran, langue FR/EN, chronomètre speedrun. Le chronomètre de partie est **caché** par défaut (le HUD montre l'heure du jeu) ; l'option speedrun l'affiche au centième. Sauvegarde automatique aussi **après chaque achat**.

- **[DÉCIDÉ]** Anti-blocage (v0.29, demande d'Othmane, 2026-11-16 : « Make sure no softlocking is possible ») : on ne doit jamais pouvoir rester coincé. (1) Les **petits objets se traversent** : tas de matériaux, ~~tuyaux~~ (solides depuis 0.1.6, décision d'Othmane), coquillages, noix de coco ; on les vise toujours (E, clic) mais on ne s'y cogne pas. (2) **Détection automatique** : si l'on essaie d'avancer sans bouger pendant 1 s et qu'aucune des 8 directions ne laisse partir de ~~80 cm~~ 1,5 m (0.1.6), le personnage se pose sur la place libre la plus proche (avec du sol, cercles de 50 cm jusqu'à 4 m). (3) **Filet de sécurité** : bouton « Me débloquer » dans le menu pause, qui ramène sur la plage (à côté si un objet bloque le point de retour). Valeurs dans `GameConfig` (`unstuck_*`).

- **[PROPOSÉ]** Vraie fin construite (v0.30 ; M-04, Q-24, Q-25) : touche de debug **F4** seulement. Phases minutées (données : `GameConfig.ending_durations`) : la **bonde** et sa chaîne se découvrent quand l'eau descend · **glouglou** (tourbillon, l'océan disparaît) · **traversée** à pied du fond à sec, plan large en 3e personne · **avion publicitaire** de l'agence (même pilote qui fait coucou) avec sa banderole « maintenant aussi transporteur : de n'importe où à n'importe où » · écran du **temps de partie** (chronomètre arrêté au début de la fin) · **générique** · retour au menu principal. Clic : passer le temps ou le générique. Le meilleur temps est gardé et affiché (★) dans le menu ; une partie finie se rouvre **juste avant de tirer la chaîne**.
- **[PROPOSÉ]** Traits sur le palmier (v0.30 ; M-84) : un trait gravé par réveil après une noyade, par paquets de 5 (4 debout, le 5e en travers), sur le palmier le plus proche de la plage ; sauvegardé avec la partie.
- **[DÉCIDÉ]** « Nouvelle partie » dans le menu (v0.30, Othmane, 2026-11-16) : gros bouton « Nouvelle partie » (premier emplacement vide, sinon le plus ancien), et pour chaque emplacement Continuer / Nouvelle / Effacer. Écraser ou effacer une partie demande toujours confirmation. Le menu pause a aussi « Nouvelle partie » (sauvegarde, puis menu principal).

- **[PROPOSÉ]** Sons de base (v0.31 ; M-75, en attendant les banques CC0 M-76) : fabriqués par calcul, sans fichier : vagues en boucle (qui se taisent quand l'océan est vidé), seau qu'on remplit / qu'on vide, téléphone qui sonne tant qu'on ne décroche pas, ramassage, petit arpège à chaque jalon, avion, « plop » de la bonde puis glouglou. Volume général dans les options.
- **[PROPOSÉ]** Mesure de perf (v0.31 ; M-11) : scénario `tests/scenarios/perf.gd`. Sans affichage, la logique du jeu prend ~1 ms par image (simulation seule : ~11 µs avec 12 zones et 40 tuyaux). Avec affichage (rendu logiciel du conteneur, sans carte graphique : chiffres d'images/s non représentatifs) : ~210 appels de dessin sur l'île de départ, ~340 sur une île remplie, ~67 000 primitives (surtout l'océan proche), ~55-60 Mo. À refaire sur le PC de référence (RTX 4 Go).



### 19.6 Versions 0.1.X : les modèles

- **[DÉCIDÉ]** La démo greybox finie est gardée telle quelle comme **version 0.1.0** (branche `version/0.1.0` sur GitHub, Othmane, 2026-11-16).
- **[DÉCIDÉ]** Les versions 0.1.X remplacent les formes grises par de vrais modèles. Style : **low poly, mais pas laid, et cartoon**. On commence par **le terrain** (sable à plusieurs niveaux, eau, ciel, soleil) ; les autres modèles viennent une fois les terres validées par Othmane.
- **[DÉCIDÉ]** Pour les modèles, utiliser **autant que possible des modèles low poly gratuits trouvés en ligne** (retouchés si besoin) plutôt que tout créer à la main (Othmane, 2026-11-16). Licence CC0 de préférence ; sinon licence qui autorise l'usage commercial, avec le crédit noté dans le dépôt.
- **[PROPOSÉ]** 0.1.1, le terrain : l'île est générée (bruit déterministe) au lieu d'un cylindre gris. Le plateau constructible reste plat (rayon 19,5 m) ; autour, une plage en pente douce jusqu'au rivage (côte irrégulière, ~25 m), un plateau sous-marin peu profond, puis le fond marin. Des dunes en terrasses, coiffées d'herbe, sur les côtés de l'île, jamais du côté de la plage de départ (+Z). Facettes plates, couleurs par hauteur et par pente (herbe, sable sec, sable de pente, sable mouillé, sable immergé, fond).
- **[PROPOSÉ]** Eau cartoon : couleurs en bandes selon la profondeur (turquoise → bleu profond), facettes, écume nette au rivage avec un deuxième anneau.
- **[PROPOSÉ]** Ciel cartoon : dégradé jour / coucher / nuit, disque du soleil net avec halo, étoiles la nuit. La couleur du soleil se réchauffe près de l'horizon.

---

### 19.7 Version 0.1.2 : palmiers, cabine, catalogue et interface

Demande d'Othmane (2026-11-16) : « palmiers, noix de coco, cabine téléphonique et interface ; le catalogue accessible seulement face à la cabine, pas un objet posé au sol ; un catalogue drôle avec des images et des prix ; toute l'interface prend la direction artistique du catalogue (polices, couleurs) ; un système de dialogue avec sous-titres quand on parle à la cabine ; garder le "riiing" au-dessus de la cabine ». Ces points sont **[DÉCIDÉ]**. Les détails ci-dessous sont **[PROPOSÉ]**.

- **[PROPOSÉ]** Modèles : palmiers, rochers, buissons des dunes et bois flotté du *Nature Kit* de Kenney (CC0), recolorés en cartoon au chargement ; couronne des palmiers doublée, noix de coco accrochées dessous. Aucune cabine téléphonique gratuite n'était accessible : la cabine (rouge, vitrée, bandeau « TÉLÉPHONE », téléphone mural, catalogue enchaîné sur une tablette) et les noix de coco sont faites en facettes par code. Crédits : `game/assets/CREDITS.md`.
- **[PROPOSÉ]** Direction artistique de l'interface : un vieux catalogue de vente par correspondance. Papier crème, encre violet-nuit, bandeaux rouges, étiquettes de prix jaunes au feutre, tampons. Polices libres : Lilita One (titres), Fredoka (texte), Permanent Marker (prix, tampons).
- **[PROPOSÉ]** Le Grand Catalogue de l'Agence : une double page. À gauche, les produits en vitrine (photo 3D qui tourne, nom, slogan drôle, description, prix sur étiquette, tampons « PROMO », « BIENTÔT », « DÉJÀ À VOUS ») ; à droite le bon de commande (ce qu'on a, le panier, le total).
- **[PROPOSÉ]** Dialogues : Ginette, de l'Agence, au bout du fil. Sous-titres en bas de l'écran, texte qui s'écrit lettre par lettre, réponses au clic ou avec 1 à 4, Échap pour raccrocher. Trois conversations : premier appel, offre du jour (« Montrez-moi ça ! » ouvre le catalogue), appel normal (commander, demander s'il reste de l'eau, raccrocher). Les textes sont dans `data/dialogues.json`.
- **[PROPOSÉ]** « Driiing ! Driiing ! » au-dessus de la cabine qui tremble ; la sonnerie se tait pendant la conversation.

---



### 19.8 Version 0.1.3 : une île plus grande, un HUD plus léger

Demande d'Othmane (2026-11-16) : « agrandir l'île d'environ 50 % et soigner le terrain ; faim et soif animées à côté de la barre d'objets ; les données inutiles seulement dans le menu ». **[DÉCIDÉ]**. Détails **[PROPOSÉ]** :

- **[PROPOSÉ]** Rivage moyen à 38 m (25,5 avant), zone constructible de 24 m de rayon (19,5 avant). Une **crique** devant la plage de départ (+Z) rapproche l'eau du camp (rivage à ~30 m de ce côté), pour que la boucle seau → cuvette garde le même rythme ; le camp (cuvette, palette, cabine, largages, réapparition) avance de 4,5 m vers la plage. Un **îlot** avec deux palmiers au large. Dunes plus hautes (3,2 m), sable sur les flancs, herbe sur le haut et en touffes sur les terrasses. Neuf palmiers de décor de plus, plus de buissons et de bois flotté.
- ~~**[PROPOSÉ]** Pompes : « au bord de l'eau » veut dire à au moins 20 m du centre (15,5 avant).~~ Remplacé en 0.1.4 : les pompes se posent dans l'eau (§19.9).
- **[PROPOSÉ]** HUD : seulement l'océan restant (et le chrono en option speedrun). Faim et soif en **jauges rondes animées** à gauche de la barre d'outils (liquide qui ondule, battement rouge sous 25 %). L'eau du seau s'affiche dans sa case. Le reste (heure, temps de jeu, palette, bras, seau, faim et soif en %) est dans le panneau « Mon île » du menu pause.

---



### 19.9 Version 0.1.4 : tous les modèles, 64 par case, pompes dans l'eau

Demandes d'Othmane (2026-11-16) **[DÉCIDÉ]** :
- une passe sur **tous les modèles**, en cherchant d'abord des modèles gratuits en ligne dans notre style ; les tas (sel, minéraux…) doivent ressembler à ce qu'ils contiennent, les coquillages à des coquillages ;
- les seaux se remplissent pour de vrai, et le reste comme décrit dans le PRD (§13 : personnage animé en 3e personne ; §15 : un plan d'eau qui monte et descend ; M-32 : quelques gouttes) ;
- en pause, le texte d'aide ne doit plus passer sous la barre d'objets ;
- **plus de limite de 40 portés : 64 par case sur les 5 cases** ;
- les tuyaux se raccordent plus clairement aux zones où ils versent ;
- **les pompes se posent dans l'eau** (elles pompent de l'eau) : elles dépassent de l'eau mais reposent sur le fond.

Détails **[PROPOSÉ]** :
- **[PROPOSÉ]** Modèles CC0 ajoutés (retouchés au chargement) : cristaux et gemmes (minéraux rares), rocher à cristaux (minéraux), crabe animé, poisson, fleurs des dunes, deux petits personnages animés (le joueur et le pilote). Le reste (tas, coquillages, caisse et parachute, biplan, palette, zones, pompe, moulin, toboggan, miroir, jauge, seaux, râteau, condenseur, rations, mouettes, coraux, algues, étoiles de mer) est fabriqué par code dans le même style : rien de gratuit et d'accessible ne correspondait.
- **[PROPOSÉ]** Les photos du catalogue utilisent les mêmes modèles que le jeu : on reçoit ce qu'on a vu.
- **[PROPOSÉ]** Le seau de départ est en zinc, avec une rustine (clin d'œil de §12) ; le grand seau est jaune. L'eau monte pendant qu'on puise, et quelques gouttes tombent quand on marche avec un seau bien rempli.
- **[PROPOSÉ]** La brouette passe à **128 par case** (au lieu de 64), pour garder son intérêt.
- **[PROPOSÉ]** Une pompe se pose dans l'eau : au moins 25 cm de fond, et au plus 7 m du rivage (`pump_min_depth_m`, `pump_max_offshore_m`). Sa plateforme reste à hauteur du sable, sur des pilotis plantés dans le fond. Livrée, elle va dans l'eau la plus proche du point de largage. Les tuyaux peuvent aller au-dessus de l'eau jusqu'aux pompes (portés par des piquets), mais pas à travers une dune : on passe par-dessus, en hauteur.
- **[PROPOSÉ]** Raccords : une bride au contact de la pompe ; au-dessus d'une zone, une descente avec un bec évasé jusqu'au bord du bac, et un filet d'eau qui coule pendant que la pompe débite.

### 19.10 Version 0.1.5 : la grille de placement colle aux modèles

Demande d'Othmane (2026-11-17) **[DÉCIDÉ]** : travailler la grille. Beaucoup d'objets prennent bien plus de place qu'ils ne devraient, et bien plus que ce qu'on voit, ce qui rend le placement pénible.

Détails **[PROPOSÉ]** :
- **[PROPOSÉ]** Chaque objet occupe un **rectangle de cases entières** qui colle à son modèle, au lieu d'un cercle. Il tourne avec l'objet (R) : un toboggan d'1 × 3 cases tourné d'un quart de tour occupe 3 × 1 cases.
- **[PROPOSÉ]** Tailles (en cases) : cuvette et bâche 4 × 3 (le bac 3 × 3 et la colonne de ses tas), bassin en bois 6 × 3, condenseur 2 × 2, miroir 2 × 1, toboggan 1 × 3, palette 4 × 2, pompe à bras 1 × 2 (avec son bec), moulin 3 × 3 (ses pilotis), rations, caisse, flamant, bateau en bouteille et catalogue 1 × 1. Avant, la cuvette bloquait un disque de 6 m de diamètre (28 m²) ; maintenant 12 cases.
- **[PROPOSÉ]** Deux objets peuvent se poser **case contre case** : se toucher par un bord n'est pas un chevauchement.
- **[PROPOSÉ]** Les bords d'une emprise tombent toujours sur les lignes de la grille : un objet de largeur paire (miroir, condenseur, palette) a son centre sur une ligne, un objet de largeur impaire au milieu d'une case.
- **[PROPOSÉ]** Pendant le déplacement (G), on voit au sol les **cases** que l'objet occupera (vert ou rouge), la grille autour, les emprises voisines en bleu et, en rouge, ce qui gêne. Le point visé est le milieu de l'objet.
- **[PROPOSÉ]** Le joueur, les palmiers, les rochers, les noix de coco et les tuyaux restent de petits cercles : ils ne bloquent que leur case, ou un bout.
- **[PROPOSÉ]** Les tuyaux se branchent sur **toutes les cases qui bordent la pompe** (et celle du dessus), plus seulement sur les 4 cases autour de son centre : c'est nécessaire pour le moulin, qui fait 3 × 3 cases.
- **[PROPOSÉ]** Le toboggan sert les zones dont le **bord** est à moins de 3 m de lui (comme avant, mais compté depuis le vrai bord).
- **[PROPOSÉ]** Un test vérifie que chaque emprise couvre son modèle (à 12 cm près) et qu'aucun de ses côtés ne pourrait reculer d'une case : si un modèle change, le test le signale.

### 19.11 Version 0.1.6 : tuyaux solides qui versent au milieu, portée de pose

Demandes d'Othmane (2026-11-17) **[DÉCIDÉ]** :
- afficher le nombre de tuyaux en main ;
- les ombres des tuyaux reliés ne s'affichaient pas ;
- un tuyau ne doit verser dans une zone que s'il est **vers le centre** et **un seul bloc au-dessus** (avant, il versait dès qu'il passait au-dessus du bac) ;
- **limiter la distance** à laquelle on pose un objet ;
- les tas se déformaient au-delà d'une certaine quantité ;
- **les tuyaux ont une collision** (« c'est plus fun »).

Détails **[PROPOSÉ]** :
- **[PROPOSÉ]** Le nombre de tuyaux en main s'écrit dans leur case de la barre (« 12 en main »).
- **[PROPOSÉ]** Arrivée d'eau : la case du milieu pour la cuvette et la bâche, les 3 cases du milieu pour le bassin en bois (qui est plus long) ; elle tourne avec la zone. Un tuyau ne se pose plus dans une zone (au sol), et une zone ne se pose plus sur un tuyau au sol : on passe par-dessus et on descend d'un bloc au-dessus du milieu.
- **[PROPOSÉ]** Portée de pose : le bord de l'objet doit être à moins de **6 m** du joueur (`place_reach_m`). Plus loin, l'aperçu est rouge et l'invite dit « Trop loin : approche-toi ».
- **[PROPOSÉ]** Les tas de la palette grandissent d'un bloc jusqu'à remplir leur place, puis presque plus (au plus 15 % plus hauts que larges) : le compteur dit le reste.
- **[PROPOSÉ]** Tuyaux solides : on s'y cogne et on peut monter dessus. Une pièce ne se pose jamais dans le joueur (au sol ou à hauteur de tête). Si l'on s'enferme dans un enclos de tuyaux, l'anti-blocage nous en sort : il juge « coincé » quand aucune direction ne laisse partir de 1,5 m, et ne nous repose jamais dans un autre enclos.

### 19.12 Version 0.1.7 : plus de clignotement en mode G

Demande d'Othmane (2026-11-17) **[DÉCIDÉ]** : en mode G (déplacement), les graphismes clignotent ; corriger ce clipping et s'assurer qu'il ne revient pas.

Détails **[PROPOSÉ]** :
- **[PROPOSÉ]** L'aperçu (cases, voisins, grille, contours) épouse le relief du sable et flotte 6 à 9 cm au-dessus, une couche au-dessus de l'autre, dans un ordre de dessin fixe.
- **[PROPOSÉ]** Le rayon de visée ignore tout l'objet déplacé, tas compris : l'objet ne saute plus entre deux places.
- **[PROPOSÉ]** Au ras d'une ligne de la grille, il faut viser 15 cm dans la nouvelle case pour que l'objet y passe : le balancement de la tête ne le fait plus trembler.

### 19.13 Version 0.1.8 : chasse aux bugs, modèles revus

Demande d'Othmane (2026-11-17) **[DÉCIDÉ]** : faire beaucoup de tests et de parties d'essai (enregistrées et regardées) pour trouver les bugs ; chercher à fond des modèles gratuits meilleurs que les nôtres ; revoir les tuyaux, les coquillages (posés au sol), les tas et ce qui porte les tas (la palette).

Détails **[PROPOSÉ]** :
- **[PROPOSÉ]** Deux parties automatiques avec le vrai jeu (écran virtuel), lancées par la CI à chaque PR : un robot qui joue la boucle (puiser, verser, récolter, palette, téléphone, commande, caisse, déplacer, tuyaux, pause, nage, sauvegarde) et un « singe » qui appuie au hasard pendant 60 s. Une erreur de script fait échouer la CI.
- **[PROPOSÉ]** Bugs corrigés : la jauge de faim et de soif envoyait un polygone invalide à chaque image (erreur moteur en boucle) ; le joueur pouvait garder en cible un objet disparu ; une caisse ouverte avant d'être larguée faisait une erreur à l'arrivée de l'avion.
- **[PROPOSÉ]** Tuyaux : un peu plus gros, un manchon foncé à chaque raccord entre deux pièces (on les compte), une boule de jonction seulement sur les coudes, T et croix, et un piquet en bois avec collier et semelle sous toute pièce qui ne repose sur rien (sauf au-dessus d'une zone ou d'une pompe).
- **[PROPOSÉ]** Coquillages : fermés dessous, côtes en deux tons, conque refaite (cône, spire, bourrelets, ouverture rose vers le ciel) ; posés **sur** le sable, penchés comme la pente, sans qu'aucun bord ne s'enfonce.
- **[PROPOSÉ]** Palette : un seul bois (fini les rayures crème), des cloisons basses entre les cinq tas, le nom de chaque ressource sur une petite planche crème. Tas de coquillages sur du sable rosé, perles sur un coussin bleu nuit.
- **[PROPOSÉ]** Modèles gratuits : rapport `recherche/Modèles gratuits low poly.md`. Aucun modèle n'est importé dans cette version : à décider par Othmane (seau et palette KayKit, tuyaux du Space Kit de Kenney, qui font 1 m comme nos cases). → **[DÉCIDÉ]** importés en 0.1.9 (voir 19.14).

### 19.14 Version 0.1.9 : seau et palette KayKit, tuyaux Kenney

Décision d'Othmane (2026-11-17) **[DÉCIDÉ]** : essayer les modèles CC0 proposés par la recherche de la 0.1.8, c'est-à-dire le seau et la palette de KayKit et les tuyaux de 1 m du Space Kit de Kenney.

Détails **[PROPOSÉ]** :
- **[PROPOSÉ]** Seau : le seau en bois de KayKit, à la même taille qu'avant, avec notre eau qui monte dedans. La rustine du seau de départ est gardée. Le grand seau est teinté jaune.
- **[PROPOSÉ]** Palette : des palettes KayKit posées côte à côte en damier. Une sur deux est tournée d'un quart de tour, pour que les planches se croisent. Les cloisons et les noms de la 0.1.8 restent.
- **[PROPOSÉ]** Tuyaux : les pièces Kenney, réduites en travers à 35 %. Un tuyau droit est un tronçon d'un mètre. Un coude, un T ou une croix à plat utilisent le raccord Kenney, tourné vers les voisins, avec un tronçon jusqu'au bord de la case. Les montées et les pièces seules gardent une boule de jonction. Le bras vers la pompe, la descente vers une zone et les piquets restent faits par code. Le métal prend la couleur du réseau (gris sec, bleu mouillé).
- **[PROPOSÉ]** Restent faits par code faute de modèle gratuit : coquillages, tas, perles, pompe, moulin, zones de séchage, bâche.

### 19.15 Version 0.1.10 : la pelle, les remarques d'Othmane, les modèles CC0

Décision d'Othmane (2026-11-20) **[DÉCIDÉ]** : intégrer **toutes** ses remarques (document « REmarks »), **ajouter les modèles CC0** trouvés par la recherche du 20 novembre (« ils ont l'air super bien ») et **faire mieux marcher les tuyaux**. La remarque la plus importante : pouvoir travailler le sable pour poser les objets où on veut.

Détails **[PROPOSÉ]** (nos choix, à valider) :
- **[PROPOSÉ]** **La pelle** (remarque 5) : un outil de départ, en case 2 de la barre (qui passe à 6 cases, touche 6). En visant le sable à moins de 4 m, un carreau montre la case de 1 m et le niveau qu'elle aura, vert si c'est possible, rouge sinon (le texte dit pourquoi). **Clic gauche maintenu** : aplanir, au niveau de la première case cliquée, en glissant sur les cases voisines. **Clic droit** : creuser d'un cran de 25 cm. **Maj + clic droit** : remonter d'un cran. Bornes : jamais à moins de 20 cm au-dessus de l'eau, jamais plus de 2,5 m au-dessus du sol de l'île. On ne travaille ni la mer, ni une case sous un objet (palmier, rocher, noix de coco, tuyau, objet posé, caisse), ni un coin partagé avec un objet si ce coin devait bouger. Les coquillages posés suivent le sable ; le joueur remonte si le sol monte sous lui. Le sable travaillé est un peu plus clair, en damier très léger. Il est sauvegardé ; Nouvelle partie remet l'île d'origine.
- **[PROPOSÉ]** **Où poser** (remarque 5) : il n'y a plus de cercle constructible fixe. Un objet se pose sur des **cases plates, toutes au même niveau**, au-dessus de l'eau : le plateau de départ ou du sable aplani à la pelle, n'importe où sur l'île. L'objet se pose à ce niveau. Ailleurs, le texte dit « Sol pas plat : aplanis-le à la pelle ».
- **[PROPOSÉ]** **Le sol de l'île** : une grille de sommets tous les mètres (les mêmes cases que le placement), un peu décalés au hasard pour le style low poly ; un sommet travaillé à la pelle n'est plus décalé. Tout ce qui se pose au sol lit la hauteur exacte du maillage.
- **[PROPOSÉ]** **Décor posé au sol** (remarque 1) : palmiers, rochers, buissons, bois flotté et fleurs sont posés au point le plus bas du sol sous eux (plus rien ne flotte). Les fleurs ne poussent que sur les facettes d'herbe, sans déborder sur le sable. Le décor d'une case travaillée à la pelle disparaît (il revient si on recommence une partie).
- **[PROPOSÉ]** **Noix de coco** (remarque 2) : une coque à facettes couverte de fibres, avec trois vrais trous creusés au sommet.
- **[PROPOSÉ]** **Tas** (remarques 3 et 9) : le tas de coquillages n'est fait que de coquillages (moules de Kenney, coquilles et conques), en couronnes. Le sel est un tas de neige de Kenney teint en blanc crème, les minéraux des pierres de Kenney, les minéraux rares le tas de gemmes de KayKit. Chaque tas d'une zone est **dans un petit bac en bois**, toujours visible.
- **[PROPOSÉ]** **Matériau en main** (remarque 4) : quand on tient du sel, des minéraux, des coquillages…, on porte un petit bac avec un tas qui grossit avec la quantité.
- **[PROPOSÉ]** **Palette** (remarque 7) : deux palettes en bois de KayKit, et dessus un bac par matériau, comme dans les zones, avec le nom peint devant et le nombre au-dessus.
- **[PROPOSÉ]** **Océan restant** (remarque 8) : affiché avec 2 décimales.
- **[PROPOSÉ]** **Cuvette** (remarque 9) : un creux de sable avec un bourrelet tout autour, plus haut que l'eau, un fond mouillé plus sombre et des galets sur le bord.
- **[PROPOSÉ]** **Ombres** (remarque 9) : le joueur a une ombre aussi à la 1re personne (son corps ne se dessine pas, mais son ombre oui). Les ombres du soleil sont plus nettes de près (distance d'ombre ramenée à 70 m).
- **[PROPOSÉ]** **Téléphone** (remarque 10) : on peut entrer dans la cabine (trois murs, le côté ouvert vers le centre de l'île). Pendant l'appel, le combiné vient à l'oreille du joueur, relié par son fil, puis revient se raccrocher.
- **[PROPOSÉ]** **Jauge** (remarque 11) : le poteau passe derrière le cadran et la plaque, il ne les traverse plus.
- **[PROPOSÉ]** **Caisse** (remarque 12) : la caisse du Pirate Kit de Kenney, fermée d'un couvercle, avec « AGENCE » et « Fragile » peints à plat sur la face.
- **[PROPOSÉ]** **Modèles CC0** : le moulin-pompe devient l'éolienne de ferme de Quaternius (ses pales tournent), le condenseur prend la toile tendue du Survival Kit de Kenney, la brouette du catalogue est celle de KayKit. Restent faits par code : la pompe à bras (rien de gratuit), la cabine, la bâche et le bassin en bois (le bac KayKit étiré à 4 × 3 m déformait ses planches).
- **[PROPOSÉ]** **Tuyaux** : clic maintenu en glissant pour poser une ligne droite au niveau de la première pièce ; clic droit sur une pièce pour la reprendre (E marche toujours) ; le cube fantôme devient bleu si l'eau d'une pompe passera par là, bleu vif avec « verse dans la zone » si la pièce versera dans une zone. Le niveau qui verse (« un bloc au-dessus ») suit la hauteur de la zone, posée sur du sable creusé ou remonté.

## 20. Glossaire

| Terme | Définition |
|---|---|
| **Drain** | Le bouchon/trou d'évacuation au fond de l'océan, découvert à ≤ 5 % |
| **Zone de séchage** | Tout endroit où l'eau s'évapore pour laisser des ressources (trou, bâche, bassin, évaporateur) |
| **Zone de dépôt** | L'endroit où l'on pose le paiement que l'avion vient récupérer |
| **Palier (T0–T6)** | Niveau technologique qui change la façon de jouer |
| **Débit** | Litres retirés de l'océan par seconde |
| **Volume retiré** | La variable de vérité de la progression ; le niveau d'eau en découle |
| **Clin d'œil** | Détail visuel de lore, sans texte à lire, jamais obligatoire |
