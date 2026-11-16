# Drain the Ocean — PRD (Product Requirements Document)

> **Source unique de vérité.** Toute fonctionnalité du jeu, toute règle de gameplay et tout choix technique est décrit ici. Si ce n'est pas dans ce document, ce n'est pas (encore) dans le jeu.
> Chaque modification de ce document doit être consignée dans [`HANDOFF.md`](../HANDOFF.md).

| Champ | Valeur |
|---|---|
| Version du document | 0.1 (brouillon initial) |
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
11. [La fin : la bonde](#11-la-fin--la-bonde)
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

Quand il reste **5 % d'eau ou moins**, une **bonde** devient visible au fond de l'océan. Le joueur n'a qu'à la tirer pour vider tout le reste. C'est la chute comique du jeu.

**Une phrase :** un jeu incrémental en 3D (*[QUESTION Q-01]*) où l'on passe d'un seau à des machines absurdes pour vider un océan… qui avait une bonde depuis le début.

---

## 2. Piliers de conception

**[PROPOSÉ]** Les piliers servent à trancher les débats futurs : une fonctionnalité qui n'en sert aucun est coupée.

1. **L'absurde pris au sérieux.** Le jeu ne fait jamais de clin d'œil appuyé. Le personnage vide l'océan avec application ; l'humour naît du décalage (avion qui ne s'arrête pas, chiffres démesurés, bonde finale).
2. **Toujours voir le progrès.** Même quand le niveau de l'océan ne bouge pas, le joueur voit quelque chose grandir : son stock, ses machines, son île, ses records.
3. **Montrer, ne pas raconter.** Aucun texte de lore, aucun livre, aucun dialogue. Tout se comprend à l'œil (voir [section 12](#12-clins-dœil-lore-uniquement-visuel)).
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
- **[PROPOSÉ]** Pas de survie (ni faim, ni soif, ni santé). Le jeu reste détendu. *[QUESTION Q-05]*
- **[PROPOSÉ]** Cycle jour/nuit lent (ex. 20 min réelles par jour). Le soleil influence l'évaporation (voir [6.3](#63-le-séchage)). La nuit est belle et calme, pas punitive. *[QUESTION Q-06]*

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
- **[PROPOSÉ]** L'agence n'a pas de visage. On ne voit que ses avions, son logo (pictogramme sans texte) et ses caisses. Le pilote fait un signe de la main à chaque passage.

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
3. Atteindre ≤ 5 % : trouver la bonde, la tirer, fin.

### 5.4 Durée cible

- **[PROPOSÉ]** 6 à 10 heures pour finir, 12 à 15 heures pour tout trouver (clins d'œil, succès). *[QUESTION Q-02]*
- **[PROPOSÉ]** Premier achat en moins de 3 minutes. Premier palier technologique en moins de 15 minutes. Le joueur ne doit jamais rester plus de ~10 minutes sans objectif atteignable visible.

### 5.5 Actif contre inactif (idle)

- **[PROPOSÉ]** Début de partie très **actif** (le joueur porte le seau lui-même), puis de plus en plus **automatisé** : le joueur devient gestionnaire et architecte de son île.
- **[QUESTION Q-03]** Le jeu progresse-t-il quand il est fermé (progression hors ligne) ? Recommandation : **non** pour le PC (c'est un jeu à vivre, pas une appli à laisser tourner), **oui** pour le mobile.

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
- **[QUESTION Q-04]** Ajouter une 5ᵉ ressource ultra-rare (ex. **perle**, trouvée dans certains coquillages) pour les achats de fin et le contenu caché ?

### 6.2 Monnaie : troc ou crédits ?

**[QUESTION Q-07]** Deux options :

- **A. Troc direct (recommandé)** : chaque article du catalogue a un prix en ressources (ex. « Pompe manuelle = 300 sel + 20 minéraux + 5 coquillages »). Chaque ressource garde de la valeur toute la partie, c'est plus lisible et plus « naufragé ».
- **B. Crédits** : on vend les ressources à l'agence contre une monnaie unique, puis on achète. Plus simple à équilibrer, mais le sel perd vite tout intérêt et l'économie devient abstraite.

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
| — | La bonde | Rien à acheter : elle était là depuis le début | Fin du jeu | ∞ |

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
| Abysse central | 100 – 300 m | T5-T6 | Géants clins d'œil, et finalement la bonde |

- **[PROPOSÉ]** Le joueur peut **marcher** sur le fond découvert. Explorer devient une activité à part entière (coquillages, minéraux rares, clins d'œil).
- **[PROPOSÉ]** Le sable découvert est d'abord mouillé et sombre, puis sèche et s'éclaircit (shader), pour que la baisse se lise même de près.

### 8.5 L'île qui grandit

**[PROPOSÉ]** Mécanique centrale : **la terre gagnée sur l'eau est de la place constructible.** Au début, l'île est trop petite pour tout poser ; vider l'océan donne de la place pour vider l'océan. C'est la boucle de rétroaction qui donne du sens au niveau de l'eau.

### 8.6 Où va l'eau ?

C'est le plus gros trou logique du concept. Si on évapore l'eau, elle devrait retomber en pluie.

**[PROPOSÉ]** Réponse en couches :

1. **Évaporation** (T0 à T4) : l'eau s'évapore et forme des nuages qui **s'éloignent toujours vers l'horizon**. Il ne pleut jamais sur l'île. On ne l'explique pas. (Clin d'œil possible : on aperçoit très loin de la pluie tomber… en dehors du bassin.)
2. **Machines** (T5-T6) : les machines géantes rejettent la vapeur en colonnes ou « expédient » l'eau de façon absurde (machine à nuages qui envoie les nuages ailleurs, tuyau qui monte vers le ciel et disparaît).
3. **La bonde** : la seule vraie réponse, à la fin. L'eau part par le trou.

**[QUESTION Q-09]** Ajouter un « gag de la pluie » (une averse rare qui fait remonter le niveau d'un chouïa) ? C'est drôle une fois, frustrant si ça coûte du progrès. Recommandation : purement visuel, sans effet sur le niveau.

### 8.7 La vie marine

**[QUESTION Q-10]** Que deviennent les poissons ? Vider un océan, c'est aussi tuer ce qu'il y a dedans, et le ton doit rester léger. Proposition : les poissons **reculent** toujours vers le centre (on les voit de plus en plus serrés, comique), et à la fin ils partent **par la bonde** dans le tourbillon, en faisant coucou. Aucun poisson mort à l'écran.

---

## 9. Le téléphone et l'agence de livraison

### 9.1 Passer commande

- **[PROPOSÉ]** Décrocher le téléphone ouvre le **catalogue** : des pages illustrées, avec des pictogrammes et des prix en icônes de ressources. Interface en jeu (diégétique) qui reste lisible. *[QUESTION Q-11]*
- **[PROPOSÉ]** Le premier appel est un tutoriel muet : on décroche, on entend une musique d'attente, une caisse tombe du ciel avec le catalogue papier dedans.

### 9.2 Payer

- **[PROPOSÉ]** Le joueur dépose ses ressources sur une **zone de dépôt** (une palette, puis une plateforme). Lors de la commande, l'avion passe en rase-mottes et **arrache le dépôt avec un crochet** sans ralentir (gag récurrent). Plus tard, un tapis roulant alimente automatiquement la zone.
- **[PROPOSÉ]** Le paiement se valide dès que le dépôt contient assez ; l'excédent reste sur place.

### 9.3 Recevoir

- **[DÉCIDÉ]** Livraison par avion, rapide et comique, sans attendre le joueur.
- **[PROPOSÉ]** Délai : 5 à 20 secondes. La caisse est larguée en parachute **à peu près** au bon endroit. Au début elle tombe parfois à l'eau près du rivage et flotte jusqu'à la plage (gag sans pénalité).
- **[PROPOSÉ]** Les avions grossissent avec les paliers : petit hydravion → avion cargo → escadrille → avion absurde qui largue une machine géante entière.
- **[PROPOSÉ]** Les achats ne peuvent jamais être perdus : un objet qui tombe mal finit toujours par revenir sur la plage.

### 9.4 Ce que l'agence refuse de livrer

Gros trou logique : « Si l'agence livre des objets, pourquoi ne pas commander un bateau ? »

**[PROPOSÉ]** Le catalogue contient bien un **bateau**, un **hélicoptère** et un **avion**… à un prix ridicule. On les achète, et on reçoit… **une maquette** (bateau en bouteille, hélico en plastique, avion en papier). Gag visuel, et ça ferme la question sans un mot. *[QUESTION Q-12]*

Autres cas à couvrir de la même façon : gilet de sauvetage (taille enfant), radio (ne capte que la musique d'attente de l'agence), fusée de détresse (feu d'artifice qui dessine le logo de l'agence).

---

## 10. Le personnage, la caméra et les contrôles

- **[QUESTION Q-01]** 3D ou 2D/2,5D pour le jeu principal ? Recommandation : **3D stylisée low-poly** (l'échelle de l'océan et la baisse du niveau n'ont d'impact qu'en 3D).
- **[QUESTION Q-13]** Vue à la première ou à la troisième personne ? Recommandation : **troisième personne** (on voit le personnage avec son seau, plus lisible et plus drôle) avec possibilité de zoomer en vue de dessus pour gérer l'île (mode « construction »).
- **[PROPOSÉ]** Contrôles : clavier/souris et manette (pour le Steam Deck).
- **[PROPOSÉ]** Le personnage peut nager. S'il s'éloigne trop, l'écran s'assombrit et il **se réveille sur l'île**, comme au début (gag, et clin d'œil sur des réveils précédents). Aucune pénalité.
- **[PROPOSÉ]** Le personnage ne parle pas, ne pense pas en bulles. Ses émotions passent par l'animation.

---

## 11. La fin : la bonde

- **[DÉCIDÉ]** Quand il reste **5 % d'eau ou moins**, une bonde est visible au fond de l'océan. Le joueur peut simplement l'ouvrir pour vider le reste. C'est censé être drôle.
- **[PROPOSÉ]** Déroulé :
  1. À ≤ 5 %, l'eau restante est assez basse et claire pour révéler, au centre, une **énorme bonde** (style baignoire) avec sa **chaîne**.
  2. Le joueur marche jusqu'au centre sur le fond découvert (trajet long et solennel, musique qui monte).
  3. Il tire la chaîne. Petit « plop ». Silence. Puis **un énorme glouglou de baignoire** : tourbillon géant, l'eau, les poissons et les objets flottants disparaissent dans le trou en quelques secondes.
  4. Le joueur reste au milieu du fond à sec, avec son seau, devant toutes ses machines désormais inutiles.
- **[PROPOSÉ]** Indice dès le début : un **minuscule tourbillon** permanent à la surface, très loin, à l'emplacement de la bonde. Visible pour les joueurs attentifs. Il grossit très légèrement à mesure que le niveau baisse.
- **[PROPOSÉ]** Peut-on atteindre la bonde avant 5 % (scaphandre, plongée) ? Non : avant 5 %, l'eau est trop profonde et trouble pour la voir, et aucun objet du catalogue ne permet de plonger aussi bas. *[QUESTION Q-15]*
- **[QUESTION Q-16]** Que se passe-t-il après ? Options :
  - **A.** Générique, puis le joueur peut se promener librement sur le fond asséché pour trouver tous les clins d'œil (recommandé).
  - **B.** Révélation finale : la caméra s'élève et laisse deviner que tout était une gigantesque baignoire… sans jamais le montrer clairement (recommandé en complément de A).
  - **C.** « Nouvelle partie + » : après le générique, on entend un robinet s'ouvrir quelque part…
  - **D.** Le joueur « passe » vraiment : il marche jusqu'au bord du bassin et sort. Que trouve-t-il ? (à définir)

---

## 12. Clins d'œil (lore uniquement visuel)

**[DÉCIDÉ]** Pas d'histoire à proprement parler. Pas de livres, pas de notes, pas de textes à lire. Seulement des clins d'œil compréhensibles à l'œil, pour les joueurs attentifs.

**[PROPOSÉ]** Règles :

- Aucun texte lisible dans le monde (les seuls « textes » sont des pictogrammes, des chiffres et le logo de l'agence).
- Aucun clin d'œil n'est obligatoire pour finir le jeu.
- Chaque clin d'œil se comprend en une image.

**[PROPOSÉ]** Pistes (à trier) :

| Thème | Clin d'œil | Où / quand |
|---|---|---|
| La bonde | Le petit tourbillon visible dès le début | Surface, toute la partie |
| La baignoire | Le fond de l'abysse est carrelé ; un gigantesque canard en caoutchouc échoué ; un rocher en forme de savon ; le trou de trop-plein dans une falaise | Abysse, T5-T6 |
| Le téléphone | Le câble du téléphone court sur le fond marin… jusqu'à un autre téléphone, ou jusqu'à la bonde | Fond découvert |
| Les naufragés d'avant | D'autres petites îles découvertes avec un téléphone d'une autre couleur, rouillé, et un seau abandonné ; un squelette assis tenant un seau | Plateau, talus |
| Les réveils | Des traits gravés sur un palmier (comme un calendrier de prisonnier) qui augmentent à chaque fois que le joueur « se noie » et se réveille | Île de départ |
| L'agence | Le pilote vieillit au fil de la partie (barbe qui pousse, puis cheveux blancs) | Chaque livraison |
| L'agence | Le logo de l'agence ressemble de près à… une bonde | Caisses, avions |
| Le temps | Le seau de départ s'abîme, se rapièce, se décolore | Toute la partie |
| Bouteille à la mer | Une bouteille contenant un dessin (pas de texte) : quelqu'un qui tire une chaîne | Plateau |
| Le catalogue | Une page du catalogue montre une bonde barrée, ou en rupture de stock | Catalogue, tardif |

---

## 13. Mini-jeu clicker (dans la version PC)

- **[DÉCIDÉ]** Le jeu PC contient un mini-jeu : même concept, en clicker, pixel art très simple.
- **[PROPOSÉ]** Accès diégétique : on achète au catalogue une **console portable** (design original, pas une copie d'une vraie console). Le personnage s'assoit et joue ; l'écran de la console prend tout l'écran.
- **[PROPOSÉ]** Contenu : cliquer pour puiser, achats d'améliorations, automatisation, et une bonde à la fin. Durée 20 à 40 minutes.
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

- **[PROPOSÉ]** Jeu principal : 3D low-poly stylisée, couleurs vives, eau très soignée (c'est le personnage principal du jeu). Ciel et lumière qui changent avec le jour.
- **[PROPOSÉ]** Mini-jeu et mobile : pixel art très simple, palette restreinte (ex. 16 couleurs).
- **[PROPOSÉ]** Audio : vagues, vent, mouettes au début, puis bruits de machines de plus en plus présents. Musique d'attente du téléphone qui devient un thème récurrent (et peut-être la musique du générique). Le son de la bonde est le moment sonore le plus important du jeu.
- **[PROPOSÉ]** Contraste voulu : l'île est paisible au début et devient une usine bruyante. Le silence après la bonde doit frapper.

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
| Langues | Interface en français et anglais (le monde n'a pas de texte, donc peu à traduire) | **[PROPOSÉ]** |

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
- **Cible** : 60 i/s en 1080p sur une carte graphique milieu de gamme de 2020 (*[QUESTION Q-19]* : configuration minimale visée ?).

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
| P-04 | **Où va l'eau ?** L'évaporation devrait faire pleuvoir | Moyenne | Les nuages partent toujours au loin ; machines absurdes ; la bonde comme vraie réponse | 8.6 |
| P-05 | **Pourquoi ne pas commander un bateau ?** | Haute (casse le concept) | L'agence livre des maquettes | 9.4 |
| P-06 | **Pourquoi ne pas nager ?** | Moyenne | Trop loin = on se réveille sur l'île | 10 |
| P-07 | **La fin peut frustrer** : « J'ai tout fait pour rien ? » | Moyenne | C'est le but, mais on adoucit : indices visibles depuis le début, récompense post-générique, exploration libre | 11 |
| P-08 | **La bonde atteignable trop tôt** (plongée, exploit) | Moyenne | Invisible et inaccessible avant 5 % | 11 |
| P-09 | **La place sur l'île** : trop de machines, trop de stock | Moyenne | L'île grandit avec la baisse ; stock affiché par paliers ; entrepôts au catalogue | 8.5, 16.3 |
| P-10 | **Économie à une seule ressource utile** : le sel perd sa valeur | Moyenne | Troc direct et chaque palier exige une ressource plus rare | 6.2 |
| P-11 | **La vie marine** : ton morbide si les poissons meurent | Moyenne | Les poissons reculent et partent par la bonde | 8.7 |
| P-12 | **Lacs résiduels** dans les creux du fond | Moyenne | Fond modelé sans cuvettes ; flaques seulement décoratives | 8.3 |
| P-13 | **Le lore « uniquement visuel »** peut passer inaperçu | Basse | Plusieurs niveaux de lecture, un clin d'œil évident (canard géant) et des subtils | 12 |
| P-14 | **Le mini-jeu clicker** peut devenir une meilleure source de ressources que le jeu | Basse | Récompenses cosmétiques seulement | 13 |
| P-15 | **Une livraison qui tombe à l'eau** fait perdre l'achat | Basse | Les objets reviennent toujours sur la plage | 9.3 |
| P-16 | **Pas de texte** dans le monde, mais l'UI doit être claire | Moyenne | Pictogrammes dans le monde ; UI de menu avec texte traduit | 9.1, 16.1 |
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

| ID | Question | Options | Recommandation |
|---|---|---|---|
| **Q-01** | Jeu principal en 3D ou en 2D/2,5D ? | 3D low-poly / 2,5D isométrique / 2D | **3D low-poly** |
| **Q-02** | Durée de jeu visée ? | 3-5 h / 6-10 h / 15 h+ | **6-10 h** |
| **Q-03** | Progression hors ligne (quand le jeu est fermé) ? | Oui / Non / Seulement sur mobile | **Non sur PC, oui sur mobile** |
| **Q-04** | Une 5ᵉ ressource ultra-rare (perle) ? | Oui / Non | **Oui**, pour le contenu caché |
| **Q-05** | Mécaniques de survie (faim, soif) ? | Aucune / Légères / Complètes | **Aucune** |
| **Q-06** | Cycle jour/nuit ? | Oui avec effet sur l'évaporation / Oui décoratif / Non | **Oui avec effet** (léger) |
| **Q-07** | Économie : troc ou crédits ? | Troc direct / Crédits | **Troc direct** |
| **Q-08** | Gérer l'énergie à partir de T3 (éoliennes, panneaux) ? | Oui (couche logistique) / Non (machines autonomes) | **Oui, mais simple** (une jauge globale, pas de câbles) |
| **Q-09** | Pluie qui fait remonter le niveau ? | Effet réel / Purement visuel / Pas de pluie | **Purement visuel** |
| **Q-10** | Les poissons ? | Partent par la bonde / Absents / Autre | **Partent par la bonde** |
| **Q-11** | Interface du catalogue : diégétique (dans le monde) ou menu classique ? | Diégétique / Menu / Mixte | **Mixte** : on décroche en jeu, puis menu illustré |
| **Q-12** | Gag des maquettes (bateau, hélico, avion) ? | Oui / Non / Autre gag | **Oui** |
| **Q-13** | Caméra ? | Première personne / Troisième personne | **Troisième personne** + vue de dessus pour construire |
| **Q-14** | Mobile : modèle économique et plateformes ? | Payant / Gratuit / Gratuit + pub ; Android / Android + iOS | À décider plus tard |
| **Q-15** | La bonde peut-elle être atteinte avant 5 % ? | Jamais / Secret pour speedrunners | **Jamais** (peut-être un succès secret si on la *voit* tôt) |
| **Q-16** | Après la bonde ? | Exploration libre / Révélation baignoire / NG+ / Sortie du bassin | **Exploration libre + révélation suggérée** |
| **Q-17** | Le clicker donne-t-il des bonus au jeu principal ? | Cosmétiques / Petits bonus / Rien | **Cosmétiques** |
| **Q-18** | Distribution PC ? | Steam / itch.io / les deux | **itch.io pour les tests, Steam pour la sortie** |
| **Q-19** | Configuration PC minimale visée ? | Bas de gamme / Milieu de gamme | **Milieu de gamme 2020** |
| **Q-20** | Mobile : même projet Godot ou projet séparé ? | Même projet / Séparé | **Même projet**, à revoir au portage |
| **Q-21** | Nom définitif du jeu ? | « Drain the Ocean » / autre | À confirmer |
| **Q-22** | Le personnage : apparence, genre, personnalisable ? | Fixe / Personnalisable | À décider |

---

## 19. Périmètre MVP et feuille de route

**[PROPOSÉ]**

| Jalon | Contenu | Critère de réussite |
|---|---|---|
| **M0 — Fondations** | Projet Godot, structure du dépôt, CI, tests, sauvegarde vide | Un export Windows vide se construit en CI |
| **M1 — Prototype de l'eau** | Île grise, plan d'eau shader, terrain de fond, variable volume → hauteur, perf mesurée | 60 i/s avec le terrain complet ; on peut faire baisser l'eau avec une touche de debug |
| **M2 — Boucle de base** | Personnage, seau, bassin de séchage, ressources, téléphone, une livraison | On peut puiser → sécher → payer → recevoir un objet |
| **M3 — Tranche verticale** | T0 à T2 complets, simulateur d'économie, 3 clins d'œil, sons de base | 45 min de jeu amusantes testées par quelqu'un d'autre |
| **M4 — Contenu** | T3 à T6, fond marin complet, toutes les zones | On peut finir le jeu (avec debug d'accélération) |
| **M5 — La fin** | Bonde, tourbillon, générique, post-fin | La scène fait rire un testeur |
| **M6 — Clicker** | Mini-jeu pixel art complet dans la console portable | Jouable du début à la bonde |
| **M7 — Finition** | Équilibrage, polish, options, langues, succès | Version 1.0 PC |
| **M8 — Mobile** | Portage du clicker | Plus tard |

---

## 20. Glossaire

| Terme | Définition |
|---|---|
| **Bonde** | Le bouchon/trou d'évacuation au fond de l'océan, découvert à ≤ 5 % |
| **Zone de séchage** | Tout endroit où l'eau s'évapore pour laisser des ressources (trou, bâche, bassin, évaporateur) |
| **Zone de dépôt** | L'endroit où l'on pose le paiement que l'avion vient récupérer |
| **Palier (T0–T6)** | Niveau technologique qui change la façon de jouer |
| **Débit** | Litres retirés de l'océan par seconde |
| **Volume retiré** | La variable de vérité de la progression ; le niveau d'eau en découle |
| **Clin d'œil** | Détail visuel de lore, sans texte, jamais obligatoire |
