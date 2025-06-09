# Proposition Formelle – Veille Technologique  
**Cours** : Veille technologique (420-1SH-SW)  
**Session** : Hiver 2025  
**Nom** : *Louis-Philippe L'Ecuyer*  
**Date de remise** : 14 avril 2025  


## Prérecherche – Survol des intérêts

### Sujet 1 : *Automatiser mon jeu godot Eye of the toaster*
- **Résumé** : Créer un auto-battler afin de rendre le jeu autonome. Je veux essayer d’apprendre à une intelligence artificielle à esquiver les ennemis afin d’aller le plus loin possible dans le jeu. Puisque le jeu est relativement simple, je crois que ce projet est réalisable en deux semaines.

- **Ressources disponibles** : Addon Godot Godot RL Agent avec un tutoriel YouTube (ajouter des nodes de contrôleur AI) https://www.youtube.com/watch?v=f8arMv_rtUU

---

### Sujet 2 : *Créer un petit jeu de combat sur Roblox*
- **Résumé** : Je travaille actuellement sur un projet personnel en Luau sur le moteur Roblox, et je voudrais faire un micro-jeu de combat afin de me pratiquer à utiliser à la fois Luau, l’environnement 3D et les fonctionnalités multijoueurs que m’offre la plateforme.

- **Ressources disponibles** : Documentation officielle 
https://create.roblox.com/docs

---

### Sujet 3 : *Créer un programme de web scraping*
- **Résumé** : Créer un résumé d’une page web afin de fournir à un utilisateur un bon aperçu sans avoir à passer trop de temps sur le site. Les logiciels de web scraping sont souvent payants de base.

- **Ressources disponibles** : Plusieurs librairies utiles comme Puppeteer (pour simuler un navigateur web) et BeautifulSoup (pour extraire les données HTML/XML)

---

### Sujet 4 : *Application de reconnaissance vocale biométrique*

- **Résumé** : Programme de reconnaissance vocale qui permettrait d’enregistrer chaque voix et de l’associer à une personne pour exécuter certaines actions (ex. une salutation différente selon la personne).

- **Ressources disponibles** : `speech_recognition` (pour écouter avec le micro)

    - `resemblyzer` (pour identifier les personnes)

    - `pyaudio` (pour capter le son)

    - `numpy`, scikit-learn (pour le traitement / classification)

---

### Sujet 5 : *générateur de quiz intelligent*
- **Résumé** : À partir de l’API d’OpenAI, je lui demande de créer des questions à choix multiples à partir d’un texte quelconque entré par l’utilisateur. Le questionnaire serait ensuite affiché en HTML, donc il s’agirait d’un quiz web basé sur le texte fourni. Ce programme pourrait être utile pour étudier ou simplement pour le divertissement.

- **Ressources disponibles** : API OpenAI https://openai.com/index/openai-api/

---
<br/><br/>

# Sélection du sujet

### Sujet choisi : *Créer un petit jeu de combat sur Roblox*

- **Justification** : Je crois que ce sujet est le plus réaliste à réaliser en 10 jours. Il n’est ni trop facile, ni trop compliqué. Je pense pouvoir y intégrer des mécaniques intéressantes au fur et à mesure de mon avancement.

- **Défis anticipés** :  
    - Gestion des scripts côté serveur/client
    - Utilisation d'un nouveau langage de programmation,
    - Intégration de la dimension Z pour l’environnement 3D


- **Ressources nécessaires** : Roblox offre une documentation complète sur Luau, leur version modifiée de Lua.

<br/>

---

<br/>

## Creation de jeu de combat 3D sur le moteur de jeu roblox studio
Après la première moitié de la session (en mars), j’ai commencé un projet avec un ami : recréer un vieux jeu Roblox auquel on jouait quand on était plus jeunes. On a donc dû apprendre à utiliser un nouveau langage (Luau), ainsi qu’un environnement de développement 3D et multijoueur.

Le projet que je propose est un petit jeu de combat à petite échelle, dans le but de découvrir les nouvelles technologies utilisées dans la création de jeux 3D et multijoueurs, surtout du point de vue d’un débutant.



## Prérecherche 

Après avoir réfléchi aux sujets que j’avais proposés, j’ai déduit que je voulais faire ce projet parce qu’un jeu est facilement évolutif — il n’est jamais vraiment "fini". Une fois la base mise en place, on peut toujours ajouter de nouvelles fonctionnalités.

J’ai aussi vraiment aimé faire un jeu avec Godot, et comme Roblox Studio est très différent, cela me permet de découvrir la création de jeux sous un nouvel angle, avec une logique complètement différente.


## Objectifs du projet

- Créer un menu où le joueur pourra choisir sa classe. Je commencerai par deux classes, chacune ayant son propre ensemble d’attaques.

- Développer un système de combat fluide et complet pour chaque classe, avec un système de combos.

## Méthodologie et plan de réalisation

1. Recherche et création d’un module pour gérer les classes du joueur

2. Création du menu (une vue) pour attribuer une classe

3. Création du système de déplacement (sprint, dash, etc.)

4. Développement des attaques propres à chaque classe (animations, hitboxes)

5. Tests et débogage (côté serveur vs côté client)

## Outils et technologies utilisées 

- Plateforme Roblox Studio (Luau)

## Résultats attendus et critères de réussite 

- Une démonstration finale pourra être faite pour montrer le fonctionnement du jeu.