# Questionnaire MVP / Démo

> Toutes les questions à trancher avant de commencer à construire le MVP.
> Chaque réponse sera reportée dans [`PRD.md`](PRD.md) (qui reste la source unique de vérité) et consignée dans [`HANDOFF.md`](../HANDOFF.md).

## Comment répondre vite

- Pour chaque question, l'option **en gras** est ma recommandation.
- Tu peux répondre en bloc : **« OK pour tout sauf M-07 : C, M-23 : non, … »**.
- Tu peux répondre thème par thème, ou laisser un thème pour plus tard : tant qu'une question n'est pas tranchée, on part sur la recommandation **pendant le prototype** et on la note **[PROPOSÉ]**.
- « Je te laisse choisir » est une réponse valable pour les questions techniques.
- Quand une question reprend une question déjà ouverte du PRD, son numéro d'origine est indiqué (ex. *= Q-06*).

Les chiffres sont *provisoires* : ils servent à fixer un ordre de grandeur, l'équilibrage les ajustera.

---

## A. Objectif et périmètre du MVP

| ID | Question | Options | Recommandation |
|---|---|---|---|
| M-01 | À quoi sert le MVP ? | A. Prototype interne pour vérifier que c'est amusant · B. Démo publique (itch.io, Steam Next Fest) · C. Les deux, dans cet ordre | **C** : prototype interne d'abord, puis il devient la démo |
| M-02 | Durée de jeu de la démo ? | 15-20 min · **30-45 min** · 60 min+ | **30-45 min** |
| M-03 | Paliers inclus dans le MVP ? | T0-T1 · **T0-T2** · T0-T3 | **T0-T2** : seau → bricolage → hydraulique manuelle, et la première machine automatique à la toute fin |
| M-04 | La fin (drain, avion publicitaire) dans le MVP ? | A. Non · **B. Oui, via une touche de debug** pour la tester · C. Oui, jouable dans la démo avec un « mini-océan » | **B** : on la construit et on la teste, mais la démo publique ne la montre pas (c'est la chute du jeu complet) |
| M-05 | Comment se termine la démo ? | A. Écran « Merci d'avoir joué » · **B. Teaser** : le catalogue montre en silhouette les machines T3, un gros avion passe, puis écran de fin de démo · C. On peut continuer sans fin | **B** |
| M-06 | Niveau graphique du MVP ? | A. Formes grises (greybox) · **B. Greybox d'abord, puis packs low-poly gratuits (CC0) pour la démo** · C. Graphismes finaux | **B** |
| M-07 | Qui produit les modèles 3D, textures et sons ? | A. Toi · B. Packs d'assets (gratuits/payants) · C. Un artiste plus tard · D. Mélange | **D** : packs pour le MVP, à remplacer ensuite par du sur-mesure |
| M-08 | Langues du MVP ? | Français seul · **FR + EN** · Plus | **FR + EN**, avec le système de traduction en place dès le début |

## B. Technique

| ID | Question | Options | Recommandation |
|---|---|---|---|
| M-09 | Version de Godot ? | **Dernière 4.x stable**, figée ensuite · Une version précise que tu utilises déjà | **Dernière 4.x stable** (dis-moi si tu en as déjà une installée) |
| M-10 | Langage | **GDScript typé** · C# | **GDScript typé** (C# complique le portage mobile) |
| M-11 | Quel est ton PC (carte graphique, processeur, RAM) ? | — | Il sert de référence pour les performances (*= Q-19*) |
| M-12 | Git LFS pour les gros fichiers ? | **Oui** · Non | **Oui** (attention : le quota gratuit de GitHub est limité, on surveille) |
| M-13 | Intégration continue (GitHub Actions) ? | Rien · **Tests automatiques sur chaque PR** · Tests + export Windows téléchargeable | **Tests sur chaque PR**, export plus tard |
| M-14 | Résolution et affichage | **1080p de référence, fenêtré + plein écran, 16:9 et ultra-large supportés** · Autre | **Recommandation** |

## C. Contrôles et caméra

| ID | Question | Options | Recommandation |
|---|---|---|---|
| M-15 | Clavier : ZQSD, WASD ? | ZQSD fixe · WASD fixe · **Détection automatique de la disposition + touches réassignables** | **Détection auto + réassignables** |
| M-16 | Manette dans le MVP ? | Oui · **Non, plus tard** | **Non, plus tard** (mais le code des contrôles est prévu pour) |
| M-17 | Sauter ? Courir ? | Les deux · **Courir oui, sauter oui (petit saut)** · Ni l'un ni l'autre | **Les deux**, sans parkour |
| M-18 | Boutons d'action | **Clic gauche = utiliser l'outil tenu (puiser, verser, récolter) ; E = interagir (téléphone, caisse, porte) ; molette / 1-5 = changer d'outil** · Autre | **Recommandation** |
| M-19 | Troisième personne : quelle caméra ? | **Au-dessus de l'épaule, orbite à la souris** · Caméra fixe derrière · Caméra libre | **Épaule + orbite** |
| M-20 | Touche de bascule 1re / 3e personne ? | **V** · F5 · Autre | **V** (réassignable) |
| M-21 | Options de confort | **Curseur de champ de vision (FOV), balancement de tête désactivable, sensibilité souris** · Rien | **Recommandation** |
| M-22 | Placer un objet acheté | **Dans le MVP : en première personne, avec un aperçu fantôme qu'on tourne à la molette, sans grille** · Vue de dessus dédiée · Grille | **Aperçu fantôme** ; la vue de dessus vient plus tard |

## D. Personnage

| ID | Question | Options | Recommandation |
|---|---|---|---|
| M-23 | Apparence du personnage (*= Q-22*) | Fixe et neutre · Choix au début · Personnalisable plus tard | **Fixe et neutre** pour le MVP, à concevoir plus tard |
| M-24 | Nager dans le MVP ? | **Oui, nage simple** · Non, eau infranchissable | **Oui** |
| M-25 | Trop loin en nageant : le gag du réveil sur l'île ? | **Oui** · Mur invisible · Courant qui ramène | **Oui** |
| M-26 | Endurance, fatigue, faim, soif (*= Q-05*) ? | **Aucune** · Légères | **Aucune** |
| M-27 | Combien d'objets tenus à la fois ? | Un seul, on change dans un menu · **Barre d'outils de 5 cases** · Inventaire complet | **Barre de 5 cases** |
| M-28 | Que fait-on des ressources récoltées ? | A. On porte chaque sac à la main jusqu'à la zone de dépôt · **B. Elles vont dans un stock global (compteur), avec des tas visibles près du dépôt** · C. A au début, B après un achat (brouette, tapis) | **B** pour le MVP (A devient vite pénible), C à envisager pour le jeu complet |

## E. Le seau et le puisage

| ID | Question | Options | Recommandation |
|---|---|---|---|
| M-29 | Comment remplit-on le seau ? | Un clic face à l'eau (instantané) · **Entrer dans l'eau peu profonde et maintenir le clic (~1 s)** · Animation automatique | **Maintenir le clic dans l'eau** |
| M-30 | Capacité du seau de départ | 5 L · **10 L** · 20 L | **10 L** |
| M-31 | Un seau plein ralentit le joueur ? | Non · **Un peu (-15 %)** · Beaucoup | **Un peu** |
| M-32 | L'eau se renverse si on court ou saute ? | **Un peu (gag), réglable** · Non | **Un peu** ; on retire si c'est agaçant en test |
| M-33 | Verser ailleurs qu'une zone de séchage ? | **Sur le sable : l'eau s'infiltre (perdue) ; dans la mer : retour à l'océan** · Impossible | **Recommandation** |
| M-34 | Quand l'eau compte-t-elle comme « retirée » de l'océan ? | **Dès qu'elle est puisée** (remise dans la mer = rendue) · Seulement une fois évaporée | **Dès qu'elle est puisée** : le compteur réagit tout de suite, c'est plus gratifiant |
| M-35 | Améliorations du seau dans le MVP | **Grand seau (20 L), palanche (2 seaux), arrosoir géant ?** · Autres idées | **Grand seau + palanche** ; tes idées bienvenues |

## F. Le séchage

| ID | Question | Options | Recommandation |
|---|---|---|---|
| M-36 | Première zone de séchage | A. Creuser un trou dans le sable · **B. Une cuvette rocheuse naturelle déjà sur l'île** · C. Une bâche livrée au premier appel | **B** : zéro friction pour la première minute, et la bâche devient le premier achat |
| M-37 | Temps pour sécher un seau dans la cuvette, en plein soleil | 20 s · **45 s** · 2 min | **45 s** |
| M-38 | Une zone de séchage a-t-elle une capacité maximale ? | **Oui (elle refuse l'eau quand elle est pleine)** · Non | **Oui** : c'est ce qui pousse à acheter plus de surface |
| M-39 | Récolte | **Clic sur le dépôt de sel (manuel), puis râteau qui récolte toute une zone d'un coup** · Automatique | **Recommandation** |
| M-40 | Cycle jour/nuit dans le MVP (*= Q-06*) ? | **Oui : 20 min réelles par jour, évaporation ×0,3 la nuit** · Oui, décoratif · Non | **Oui** |
| M-41 | Où peut-on poser les zones de séchage achetées ? | **N'importe où sur du sable plat** · Emplacements prédéfinis · Grille | **Sable plat, libre** |
| M-42 | Le séchage s'arrête-t-il quand le joueur s'éloigne ? | **Non, tout continue tant que le jeu tourne** · Seulement à proximité | **Non** |

## G. Les ressources

| ID | Question | Options | Recommandation |
|---|---|---|---|
| M-43 | Rendements de départ *(provisoires)* par seau évaporé | **Sel : 1 garanti · Minéraux : 10 % de chance · Minéraux rares : 0,5 % · Coquillage : 3 % au puisage** · À revoir | **Recommandation**, puis équilibrage |
| M-44 | Coquillages sur la plage | **Quelques coquillages réapparaissent chaque matin sur la plage** · Seulement au puisage | **Réapparition chaque matin** : une raison de faire le tour de l'île |
| M-45 | Perle (5ᵉ ressource, *= Q-04*) dans le MVP ? | Oui · **Non (on décide pour le jeu complet)** | **Non** |
| M-46 | Limite de stockage ? | **Aucune dans le MVP** · Entrepôts à acheter | **Aucune** |

## H. Le téléphone, le catalogue et les livraisons

| ID | Question | Options | Recommandation |
|---|---|---|---|
| M-47 | Interface du catalogue (*= Q-11*) | Tout dans le monde (on feuillette un catalogue 3D) · Menu classique · **Mixte : on décroche en 3D, puis un menu illustré façon catalogue papier** | **Mixte** |
| M-48 | Le premier appel | **Tutoriel muet : on décroche, musique d'attente, une caisse tombe avec le catalogue** · Le catalogue est déjà là | **Tutoriel muet** |
| M-49 | Commander | Un article à la fois · **Un panier, plusieurs articles par commande** | **Panier** |
| M-50 | Paiement : la zone de dépôt | **Les ressources partent du stock vers une palette visible ; l'avion l'arrache au crochet en rase-mottes** · Le joueur porte tout | **Recommandation** (cohérent avec M-28) |
| M-51 | Délai de livraison | 5 s · **10-20 s** · 1 min | **10-20 s**, comique et rapide |
| M-52 | Ouvrir une caisse | **Interagir (E) : la caisse s'ouvre, l'objet apparaît prêt à poser** · Automatique | **Recommandation** |
| M-53 | Gag des maquettes (bateau → bateau en bouteille, *= Q-12*) dans le MVP ? | **Oui, au moins le bateau** · Non | **Oui** : c'est la première question que se posent les joueurs |
| M-54 | Le téléphone sonne-t-il parfois pendant la partie ? | **Jamais** (il ne sonne… qu'à la fin si on garde l'idée) · Oui, offres spéciales | **Jamais** |
| M-55 | Musique d'attente | **Oui, un thème court et entêtant qui devient le thème du jeu** · Non | **Oui** |
| M-56 | Revendre ou rembourser un achat ? | Oui · **Non dans le MVP** | **Non** |

## I. Le contenu du catalogue du MVP

Liste proposée pour T0-T2. Valide, retire ou ajoute.

| Palier | Article | Rôle | Prix indicatif *(provisoire)* |
|---|---|---|---|
| T0 | Seau 10 L | De départ | — |
| T0 | Cuvette rocheuse | Zone de séchage de départ | — |
| T1 | Bâche de séchage | Zone de séchage à poser (moyenne) | 15 sel |
| T1 | Grand seau 20 L | ×2 par trajet | 40 sel |
| T1 | Tongs | +20 % de vitesse de marche | 25 sel + 2 coquillages |
| T1 | Râteau à sel | Récolte une zone entière d'un coup | 60 sel + 5 minéraux |
| T1 | Palanche | Porter deux seaux | 120 sel + 10 minéraux |
| T1 | Bateau *(gag)* | Livre un bateau en bouteille | 999 sel |
| T1 → T2 | **Manuel du bricoleur** (clé de palier) | Débloque T2 | 250 sel + 25 minéraux + 10 coquillages |
| T2 | Bassin en bois | Grande zone de séchage | 300 sel + 20 minéraux |
| T2 | Pompe à bras | Pompe ×10 en actionnant la manivelle (maintenir le clic) | 500 sel + 40 minéraux |
| T2 | Tuyaux | Relient la pompe aux bassins | 50 sel / tronçon |
| T2 | Miroir solaire | +50 % d'évaporation pour les bassins proches | 200 sel + 5 minéraux rares |
| T2 | **Moulin-pompe** (première machine automatique) | Pompe seul, sans le joueur ; fin de la démo | 1 500 sel + 100 minéraux + 10 minéraux rares |

| ID | Question | Options | Recommandation |
|---|---|---|---|
| M-57 | Cette liste te convient-elle ? | Oui · Modifications | Tes idées d'objets drôles sont les bienvenues |
| M-58 | La pompe à bras est-elle active (il faut tourner la manivelle) ? | **Oui : T2 reste actif, l'automatisation arrive avec le moulin-pompe** · Non, automatique | **Oui** |
| M-59 | Rythme visé | **Premier achat < 3 min · T1 terminé ~15 min · T2 débloqué ~20 min · moulin-pompe ~40 min** · Plus lent · Plus rapide | **Recommandation** |

## J. L'île, l'océan et le monde

| ID | Question | Options | Recommandation |
|---|---|---|---|
| M-60 | Taille de l'île de départ | 20 m · **~40 m de diamètre** · 80 m | **~40 m** |
| M-61 | Que contient l'île au départ ? | **Téléphone, seau, cuvette rocheuse, 2-3 palmiers, rochers, une petite crique, une palette de dépôt** · Plus | **Recommandation** |
| M-62 | Le niveau de l'eau dans la démo | **Honnête : il ne bouge quasiment pas (c'est la blague), le progrès se lit dans les compteurs et les jalons** · Truqué pour bouger un peu | **Honnête** |
| M-63 | Volume de l'océan *(provisoire)* | **~2 × 10¹³ L** (bassin de ~8 km de rayon) · Autre | **Recommandation**, fixée par le simulateur |
| M-64 | Fond marin modélisé dans le MVP | **Seulement autour de l'île (plage et plateau)**, le reste en grand plan simple | **Recommandation** |
| M-65 | Météo | **Nuages qui passent, pas de pluie** · Météo variable | **Recommandation** |
| M-66 | Faune dans le MVP (*lié à Q-10*) | **Mouettes, quelques poissons près du bord, un crabe** · Rien | **Recommandation** |
| M-67 | Le petit tourbillon lointain (indice du drain) dans le MVP ? | **Oui** · Non | **Oui** : il ne coûte presque rien et récompense les joueurs attentifs dès la démo |

## K. Interface et prise en main

| ID | Question | Options | Recommandation |
|---|---|---|---|
| M-68 | Contenu de l'écran pendant le jeu (HUD) | **Stock en haut à gauche, % d'océan restant en haut au centre, barre d'outils en bas** · Rien à l'écran (tout dans le monde) | **Recommandation**, avec option pour le masquer |
| M-69 | Tutoriel | **Muet : icônes contextuelles (ex. icône de clic au-dessus de l'eau)** · Textes d'aide · Aucun | **Muet, par icônes** |
| M-70 | Jalons comparatifs (baignoire, piscine…) dans le MVP | **Oui, les 3 premiers** · Non | **Oui** |
| M-71 | Menu principal | **Continuer · Nouvelle partie · Options · Quitter, avec 3 emplacements de sauvegarde** · 1 seul emplacement | **Recommandation** |
| M-72 | Options du MVP | **Volumes (musique, effets, ambiance), sensibilité, FOV, résolution, plein écran, langue, touches** | **Recommandation** |
| M-73 | Le chronomètre de partie est-il visible pendant le jeu ? | Toujours · **Caché, avec option pour l'afficher (speedrun)** · Jamais | **Caché + option** |
| M-74 | La partie se met-elle en pause dans le catalogue ? | Oui · **Non : le séchage continue pendant qu'on fait ses courses** | **Non** (la pause se fait avec Échap) |

## L. Audio

| ID | Question | Options | Recommandation |
|---|---|---|---|
| M-75 | Musique pendant le jeu | Musique continue · **Surtout l'ambiance (vagues, vent, mouettes), avec de courts morceaux à certains moments** · Silence | **Ambiance + moments musicaux** |
| M-76 | Source des sons du MVP | **Banques de sons libres (CC0)** · Créés sur mesure | **Banques libres** pour le MVP |

## M. Sauvegarde

| ID | Question | Options | Recommandation |
|---|---|---|---|
| M-77 | Fréquence de sauvegarde | **Auto : toutes les 2 min, après chaque achat et en quittant** · Manuelle | **Auto** |
| M-78 | Sauvegarde manuelle en plus ? | Oui · **Non** | **Non** : une seule sauvegarde automatique par emplacement |
| M-79 | Progression quand le jeu est fermé (*= Q-03*) ? | Oui · **Non sur PC** | **Non** |

## N. Hors MVP (pour confirmer qu'on les laisse de côté)

| ID | Question | Recommandation |
|---|---|---|
| M-80 | Le mini-jeu clicker est **hors MVP** ? | **Oui, hors MVP** |
| M-81 | La gestion de l'énergie (*= Q-08*) arrive avec T3, donc **hors MVP** ? | **Oui** |
| M-82 | La pluie visuelle (*= Q-09*) est **hors MVP** ? | **Oui** |
| M-83 | Le fond marin complet, les paliers T3-T6 et l'île qui grandit sont **hors MVP** ? | **Oui** |
| M-84 | Clins d'œil inclus dans le MVP | **Le tourbillon lointain, les traits gravés sur le palmier (réveils), le pilote qui fait coucou** |
| M-85 | Nom du jeu pour la démo (*= Q-21*) | « Drain the Ocean » ? |
