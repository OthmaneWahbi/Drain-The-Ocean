# Drain the Ocean — PRD (Product Requirements Document)

> **Source unique de vérité.** Toute fonctionnalité du jeu, toute règle de gameplay et tout choix technique est décrit ici. Si ce n'est pas dans ce document, ce n'est pas (encore) dans le jeu.
> Chaque modification de ce document doit être consignée dans [`HANDOFF.md`](../HANDOFF.md).

| Champ | Valeur |
|---|---|
| Version du document | 0.7 (réponses au questionnaire MVP intégrées) |
| Date | 2026-11-16 |
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
- **[DÉCIDÉ]** Survie **légère** (M-26, 2026-11-16) : **endurance** (style *Zelda: Breath of the Wild*, consommée en courant et en nageant), **faim et soif légères**. Le jeu reste détendu. Détails (sources de nourriture et d'eau douce, conséquences) : *[QUESTION N-02, N-03]*.
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
- **[PROPOSÉ]** Premier achat en moins de 3 minutes. Premier palier technologique en moins de 15 minutes. Le joueur ne doit jamais rester plus de ~10 minutes sans objectif atteignable visible.

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
- **[DÉCIDÉ]** Une 5ᵉ ressource ultra-rare, la **perle**, existe et est présente dès le MVP (M-45). Sa source et son usage dans le MVP : *[QUESTION N-07]*.

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

- **[PROPOSÉ]** Chaque palier se débloque par un **achat clé** au catalogue (ex. « le manuel de la pompe » sous forme de schéma illustré), pas par un arbre de compétences abstrait.
- **[PROPOSÉ]** Les objets d'un palier inférieur restent utiles un moment, puis deviennent décoratifs. Le joueur peut les revendre ou les garder.
- **[PROPOSÉ]** Le catalogue montre en silhouette grisée le palier suivant pour donner envie (« Qu'est-ce que c'est que ce truc énorme ? »).

---

## 8. L'océan : échelle, niveau, fond marin, destination de l'eau

### 8.1 Le problème d'échelle

Un vrai océan contient ~1,3 milliard de km³. Même un « petit » océan de jeu est hors de portée d'un seau. **C'est voulu** (c'est la blague), mais cela pose un vrai problème de conception : pendant des heures, le niveau ne bouge pas.

**[PROPOSÉ]** L'océan du jeu est un **bassin fini** :

- Rayon visible ~8 km (l'horizon à hauteur d'homme est à ~5 km : le joueur ne voit jamais le bord au début).
- Profondeur moyenne ~100 m, profondeur maximale ~300 m au centre.
- Volume ≈ 2 × 10¹³ L *(provisoire)*.

Ordre de grandeur : avec un débit final de ~10⁹ L/s, la dernière phase dure ~1 h. Avec un seau à 1 L/s, il faudrait 600 000 ans. **L'écart entre les deux est toute la progression du jeu.**

### 8.2 Rendre le progrès visible malgré l'échelle

**[PROPOSÉ]** Plusieurs couches de retour :

1. **Compteur en litres** avec gros chiffres (notation lisible : 1,2 M ; 3,4 Md ; puis notation scientifique en option).
2. **Jalons comparatifs** visuels (icônes, pas de texte) : une baignoire, une piscine, une piscine olympique, un lac, une mer intérieure… Chaque jalon débloque une petite récompense.
3. **Pourcentage restant** avec beaucoup de décimales au début (99,99999 %), ce qui est drôle en soi.
4. **Le niveau réel** de l'eau, honnête, qui commence à bouger visiblement au palier T3/T4.
5. **Le fond marin conçu pour révéler beaucoup tôt** : un plateau peu profond autour de l'île (voir 8.4) fait que les premiers centimètres dévoilent beaucoup de sable.
6. **[DÉCIDÉ]** Dès la démo, un **repère de niveau d'eau** doit montrer que le niveau bouge, même d'un tout petit peu (M-62). **[PROPOSÉ]** Une **jauge à aiguille** plantée près de la plage (comme un comparateur d'atelier) : les chiffres restent honnêtes, mais l'aiguille amplifie des dixièmes de millimètre pour que le mouvement se voie. *[QUESTION N-10]*

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
- **[PROPOSÉ]** Le premier appel est un tutoriel muet : on décroche, on entend une musique d'attente, une caisse tombe du ciel avec le catalogue papier dedans.

### 9.2 Payer

- **[PROPOSÉ]** Le joueur dépose ses ressources sur une **zone de dépôt** (une palette, puis une plateforme). Lors de la commande, l'avion passe en rase-mottes et **arrache le dépôt avec un crochet** sans ralentir (gag récurrent). Plus tard, un tapis roulant alimente automatiquement la zone.
- **[PROPOSÉ]** Le paiement se valide dès que le dépôt contient assez ; l'excédent reste sur place.

### 9.3 Recevoir

- **[DÉCIDÉ]** Livraison par avion, rapide et comique, sans attendre le joueur.
- **[DÉCIDÉ]** Délai : **5 secondes** (M-51).
- **[PROPOSÉ]** La caisse est larguée en parachute **à peu près** au bon endroit. Au début elle tombe parfois à l'eau près du rivage et flotte jusqu'à la plage (gag sans pénalité).
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
- **[PROPOSÉ]** Contrôles : clavier/souris et manette (pour le Steam Deck).
- **[DÉCIDÉ]** Le personnage **nage**, avec une **limite d'endurance** (la même que pour courir) : s'il part loin sans plan, il **se noie** (M-24). Conséquence de la noyade : *[QUESTION N-04]*.
- **[DÉCIDÉ]** Pas de mur invisible ni de « réveil sur l'île » pour limiter l'exploration (M-25) : le joueur peut aller **vraiment loin**, mais il n'y trouve rien. S'il est assez malin pour parcourir **des milliers de kilomètres** sans se noyer ni épuiser son endurance, il **termine le jeu** tout simplement (fin secrète). La distance nécessaire doit être immense, et cette liberté ne doit pas coûter de performances. Conséquences sur la taille du monde et la technique : *[QUESTION N-06]* et [16.3](#163-performances).
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
- **[PROPOSÉ]** Mini-jeu et mobile : pixel art très simple, palette restreinte (ex. 16 couleurs).
- **[PROPOSÉ]** Audio : vagues, vent, mouettes au début, puis bruits de machines de plus en plus présents. Musique d'attente du téléphone qui devient un thème récurrent (et peut-être la musique du générique). Le son du drain est le moment sonore le plus important du jeu.
- **[PROPOSÉ]** Contraste voulu : l'île est paisible au début et devient une usine bruyante. Le silence après le drain doit frapper.

---

## 16. Tech stack et architecture

### 16.1 Choix techniques

| Sujet | Choix | Statut |
|---|---|---|
| Moteur | **Godot 4** (dernière version stable 4.x au démarrage, puis figée ; montée de version = décision consignée) | Moteur **[DÉCIDÉ]**, version **[PROPOSÉ]** |
| Langage | **GDScript** typé statiquement. C# écarté : plus lourd pour l'export mobile et inutile ici | **[PROPOSÉ]** |
| Rendu PC | Moteur de rendu **Forward+** | **[PROPOSÉ]** |
| Rendu clicker / mobile | **Compatibility** (OpenGL) ou **Mobile** | **[PROPOSÉ]** |
| Plateforme cible | Windows 10/11 64 bits, export `.exe` | **[DÉCIDÉ]** |
| Distribution | Steam ? itch.io ? *[QUESTION Q-18]* | Ouvert |
| Versionnage | Git + GitHub. **Git LFS** pour les gros fichiers (modèles 3D, textures, sons) | **[PROPOSÉ]** |
| Tests | **GUT** ou **gdUnit4** pour les tests unitaires de la logique (économie, niveau d'eau, sauvegarde) | **[PROPOSÉ]** |
| CI | GitHub Actions : lancer les tests et produire un export Windows à chaque PR | **[PROPOSÉ]** |
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

- **Fond marin** : grand terrain (~16 km de côté) → maillage découpé en morceaux avec niveaux de détail (LOD), ou plugin de terrain (ex. Terrain3D). Brouillard pour cacher l'horizon.
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

**Nouvelles questions issues des réponses au questionnaire : N-01 à N-10, voir [19.3](#193-nouvelles-questions-n-01-à-n-10).**

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

- **Monde :** l'île de départ (~40 m) avec téléphone, seau, cuvette rocheuse, palmiers, palette de dépôt ; océan shader ; fond marin seulement autour de l'île ; cycle jour/nuit ; nuages ; mouettes, poissons, un crabe ; le petit tourbillon lointain (*voir N-01*) ; un repère de niveau d'eau.
- **Personnage :** caméra 1re personne + bascule 3e personne ; marcher, courir, sauter, nager ; endurance, faim et soif légères ; noyade ; barre d'outils de 5 cases.
- **Seau :** puiser (maintenir le clic dans l'eau), verser, petit ralentissement, eau qui se renverse un peu.
- **Séchage :** zones avec surface et capacité, évaporation selon le soleil, récolte manuelle puis au râteau.
- **Ressources :** sel, minéraux, minéraux rares, coquillages (réapparition sur la plage chaque matin), perle ; transport à la main au début, stock automatique après un achat.
- **Téléphone :** premier appel tutoriel, catalogue illustré, panier, palette de dépôt arrachée par l'avion, livraison en parachute en 10-20 s, ouverture des caisses, pose avec aperçu fantôme.
- **Contenu :** paliers T0 à T2, une quinzaine d'objets (voir [questionnaire, section I](QUESTIONS_MVP.md#i-le-contenu-du-catalogue-du-mvp)), jusqu'au moulin-pompe, première machine automatique.
- **Progrès :** compteur de litres retirés, % restant, 3 premiers jalons comparatifs.
- **Fin de démo :** teaser des machines T3, puis écran de fin de démo. La vraie fin (drain, avion publicitaire, temps, générique) est construite mais accessible seulement par une touche de debug.
- **Système :** menu principal, 3 emplacements, sauvegarde automatique, chronomètre, options de base, FR + EN.
- **Clins d'œil :** le tourbillon lointain, les traits sur le palmier, le pilote qui fait coucou.

**Hors MVP :** clicker, énergie, paliers T3-T6, fond marin complet, île qui grandit, pluie, manette, vue de dessus, succès, fin secrète à la nage (l'architecture la prévoit).

**Critère de réussite :** 30 à 45 minutes de jeu qu'un testeur extérieur trouve amusantes, sans explication.

### 19.2 Décisions du questionnaire MVP

Toutes **[DÉCIDÉ]** le 2026-11-16 par Othmane. Les commentaires d'Othmane sont repris en italique.

**Périmètre.** M-01 prototype interne qui devient la démo · M-02 30-45 min · M-03 paliers T0-T2 · M-04 vraie fin construite, accessible par touche de debug seulement · M-05 fin de démo en teaser (silhouettes T3, gros avion, écran de fin) · M-06 greybox puis packs low-poly CC0 · M-07 packs pour le MVP, *sur-mesure fait par nous sous Blender, plus tard* · M-08 FR + EN, traduction en place dès le début.

**Technique.** M-09 dernière Godot 4.x stable, figée · M-10 GDScript typé · M-11 référence : i9, RTX 4 Go VRAM, ~12 Go RAM · M-12 Git LFS (*quota à surveiller*) · M-13 tests automatiques sur chaque PR · M-14 1080p de référence, fenêtré + plein écran, 16:9 et ultra-large.

**Contrôles.** M-15 disposition du clavier détectée + touches réassignables · M-16 manette plus tard · M-17 courir + petit saut · M-18 clic gauche = outil, E = interagir, molette/1-5 = outils · M-19 3e personne au-dessus de l'épaule, orbite souris · M-20 bascule avec V · M-21 FOV, balancement de tête désactivable, sensibilité · M-22 placement en 1re personne avec aperçu fantôme.

**Personnage.** M-23 fixe et neutre pour le MVP · M-24 nage avec **endurance** (aussi pour courir), noyade si on part loin sans plan · M-25 pas de limite artificielle : *on peut aller très loin sans rien trouver ; des milliers de km sans se noyer = fin du jeu* · M-26 **survie légère : endurance façon BotW, faim et soif légères** · M-27 barre de 5 cases · M-28 **ressources portées à la main au début, stock automatique après un achat** (brouette, tapis).

**Seau.** M-29 maintenir le clic dans l'eau ~1 s, *temps améliorable* · M-30 10 L · M-31 **aucun ralentissement** · M-32 *quelques gouttes purement visuelles, sans effet sur la quantité* · M-33/M-34 l'eau compte comme retirée dès qu'elle est puisée ; **la reverser dans la mer ou sur le sable la rend à l'océan** (*sur le sable, elle finit par y retourner*) · M-35 grand seau 20 L + palanche.

**Séchage.** M-36 cuvette rocheuse de départ, bâche en premier achat · M-37 45 s, *améliorable plus tard* · M-38 capacité maximale · M-39 récolte au clic puis au râteau · M-40 jour de 20 min, ×0,3 la nuit · M-41 pose libre sur sable plat · M-42 le séchage continue partout.

**Ressources.** M-43 sel 1 garanti, minéraux 10 %, rares 0,5 %, coquillage 3 % au puisage · M-44 coquillages qui réapparaissent chaque matin · M-45 **perle dans le MVP** · M-46 pas de limite de stockage.

**Téléphone.** M-47 catalogue mixte · M-48 premier appel en tutoriel muet · M-49 panier · M-50 palette arrachée au crochet · M-51 **livraison en 5 s** · M-52 caisse ouverte avec E · M-53 gag du bateau · M-54 **le téléphone sonne parfois pour des offres spéciales** · M-55 musique d'attente devenue thème · M-56 pas de revente.

**Catalogue.** M-57 liste validée telle quelle · M-58 pompe à bras active · M-59 rythme : premier achat < 3 min, T1 ~15 min, T2 ~20 min, moulin-pompe ~40 min.

**Monde.** M-60 île ~40 m · M-61 contenu de départ validé · M-62 niveau honnête, *mais il doit bouger un tout petit peu dans la démo, avec un repère de niveau d'eau* · M-63 ~2 × 10¹³ L (*à revoir avec N-06*) · M-64 fond modélisé autour de l'île seulement · M-65 nuages, pas de pluie · M-66 mouettes, poissons, un crabe · M-67 **pas de tourbillon lointain** (*contradiction avec M-84, voir N-01*).

**Interface.** M-68 HUD *petit, simple et comique* · M-69 tutoriel muet par icônes · M-70 3 premiers jalons · M-71 menu avec 3 emplacements · M-72 options complètes · M-73 chronomètre caché, option speedrun · M-74 pas de pause dans le catalogue.

**Audio.** M-75 ambiance + courts morceaux · M-76 banques CC0.

**Sauvegarde.** M-77 auto toutes les 2 min, après achat, en quittant · M-78 **sauvegarde manuelle en plus, qui remplace la dernière sauvegarde auto** · M-79 pas de progression hors ligne.

**Hors MVP.** M-80 clicker · M-81 énergie · M-82 pluie · M-83 fond complet, T3-T6, île qui grandit · M-84 clins d'œil du MVP : tourbillon lointain, traits sur le palmier, pilote qui fait coucou · M-85 nom : « Drain the Ocean ».

### 19.3 Nouvelles questions (N-01 à N-10)

Questions ouvertes par les réponses au questionnaire. Formulaire : voir HANDOFF.

| ID | Question | Recommandation | Bloque le MVP ? |
|---|---|---|---|
| N-01 | M-67 dit « pas de tourbillon lointain », M-84 le garde dans les clins d'œil du MVP. Lequel ? | Le garder (il ne coûte presque rien) | Non |
| N-02 | D'où viennent la nourriture et l'eau douce ? | Noix de coco sur les palmiers + rations au catalogue ; eau douce par une bâche de condensation (achat T1) | Oui |
| N-03 | Que se passe-t-il quand la faim ou la soif est à zéro ? | Pas de mort : l'endurance maximale baisse jusqu'à ce qu'on mange/boive | Oui |
| N-04 | Que se passe-t-il quand on se noie ? | Écran noir, on revient sur la plage de l'île, sans perte de ressources | Oui |
| N-05 | L'endurance : combien, comment elle remonte, peut-on l'améliorer ? | ~20 s de course ou ~60 s de nage ; remonte à l'arrêt ou au sol ; améliorable par la nourriture et des objets du catalogue | Oui |
| N-06 | Fin secrète à la nage : comment accorder « des milliers de km » avec un océan fini à vider ? | Le bassin est réellement immense (rayon de plusieurs milliers de km) ; seule la zone autour de l'île est détaillée ; volume ~10¹⁸-10¹⁹ L | Non pour le MVP, oui pour l'architecture |
| N-07 | La perle dans le MVP : d'où vient-elle et à quoi sert-elle ? | Rare dans les coquillages ramassés (~2 %) ; sert à un objet spécial ou cosmétique du catalogue | Oui |
| N-08 | Les offres spéciales au téléphone : quoi et à quelle fréquence ? | Environ une fois par jour de jeu : un article à prix réduit pendant une journée ; on décroche pour voir l'offre | Oui |
| N-09 | Quel achat automatise le transport des ressources dans le MVP (M-28) ? | Ajouter une **brouette** en T1 (porte beaucoup à la fois) puis un **toboggan à sacs** jusqu'à la palette en T2 ; le vrai tapis roulant reste en T3 | Oui |
| N-10 | Le repère de niveau d'eau : une jauge à aiguille qui amplifie les dixièmes de millimètre ? | Oui | Non |

### 19.4 Feuille de route

| Jalon | Contenu | Critère de réussite |
|---|---|---|
| **M0 — Fondations** | Projet Godot, structure du dépôt, CI, tests, sauvegarde vide | Un export Windows vide se construit en CI |
| **M1 — Prototype de l'eau** | Île grise, plan d'eau shader, terrain de fond, variable volume → hauteur, perf mesurée | 60 i/s avec le terrain complet ; on peut faire baisser l'eau avec une touche de debug |
| **M2 — Boucle de base** | Personnage, seau, bassin de séchage, ressources, téléphone, une livraison | On peut puiser → sécher → payer → recevoir un objet |
| **M3 — Tranche verticale** | T0 à T2 complets, simulateur d'économie, 3 clins d'œil, sons de base | 45 min de jeu amusantes testées par quelqu'un d'autre |
| **M4 — Contenu** | T3 à T6, fond marin complet, toutes les zones | On peut finir le jeu (avec debug d'accélération) |
| **M5 — La fin** | Drain, tourbillon, traversée à pied, avion publicitaire, écran du temps de partie, générique, retour au menu | La scène fait rire un testeur |
| **M6 — Clicker** | Mini-jeu pixel art complet dans la console portable | Jouable du début au drain |
| **M7 — Finition** | Équilibrage, polish, options, langues, succès | Version 1.0 PC |
| **M8 — Mobile** | Portage du clicker | Plus tard |

---

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
