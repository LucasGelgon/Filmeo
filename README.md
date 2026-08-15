# Filméo — Recommandation de films en Prolog

Un systeme de recommandation de films dont le moteur de suggestion
(scoring, dialogue, apprentissage, explications) est **entierement ecrit
en Prolog** (SWI-Prolog). Le meme processus Prolog sert aussi une petite
interface web (HTML/CSS/JS) via son serveur HTTP integre — pas besoin
d'un autre backend.

Trois facons d'obtenir des recommandations :

- **Par criteres** : chips de genres/ambiances + films deja aimes.
- **Dialogue guide** : un mini systeme expert qui pose des questions
  successives et s'arrete des qu'il ne reste plus beaucoup de films
  candidats.
- **Soiree entre amis** : plusieurs profils en meme temps, le moteur
  cherche le film qui minimise la frustration de la personne la moins
  satisfaite (equite plutot que simple moyenne).

Chaque recommandation peut etre expliquee ("Pourquoi ce film ?" affiche
le detail du score par regle) et notee (👍/👎) : le moteur retient alors
les genres/ambiances plebiscites et les re-utilise dans les recherches
suivantes.

## Structure du projet

```
prolog-movie-recommender/
├── run.pl                 # point d'entree : lance le serveur (port 8090)
├── prolog/
│   ├── movies.pl            # base de connaissances : 50 films (genres, realisateurs,
│   │                          acteurs, ambiances, notes, descriptions)
│   ├── recommend.pl          # moteur de scoring individuel + mode groupe
│   ├── dialogue.pl           # systeme expert conversationnel (questions dynamiques)
│   ├── feedback.pl           # apprentissage leger a partir des votes 👍/👎
│   └── server.pl             # serveur HTTP + API JSON, sert aussi public/
└── public/
    ├── index.html
    ├── style.css
    └── app.js                # interface : 3 modes, cartes de resultats, dialogue,
                                # panneau "soiree entre amis"
```

## Comment ca marche

### 1. La base de connaissances (`movies.pl`)

Faits Prolog : `movie/5`, `movie_genre/2`, `movie_director/2`,
`movie_actor/2`, `movie_mood/2`, `movie_description/2`.

### 2. Le scoring individuel (`recommend.pl`)

Le moteur prend un "profil" (genres aimes, ambiances recherchees, films
deja aimes, genres a eviter, note minimale) et calcule pour chaque film
candidat un score base sur des regles ponderees :

| Critere | Poids |
|---|---|
| Genre en commun avec les genres aimes | +3 |
| Ambiance en commun | +2 |
| Meme realisateur qu'un film deja aime | +3 |
| Acteur en commun avec un film deja aime | +1.5 |
| Bonus qualite (proportionnel a la note) | +0.4 x (note - 7) |
| Genre/ambiance **appris** via le feedback | +1.5 / +1.0 |

Les films appartenant a un genre "a eviter" sont exclus purement et
simplement. Chaque resultat revient avec :
- les **raisons** textuelles ("Meme realisateur qu'un film que vous
  aimez : Christopher Nolan"),
- un **breakdown** numerique par critere, affiche derriere le bouton
  "Pourquoi ce film ?" — c'est la trace du raisonnement Prolog, pas une
  boite noire.

### 3. Le dialogue guide (`dialogue.pl`)

Au lieu de cocher des chips, l'utilisateur repond a une suite de
questions (genre, ambiance, genre a eviter, exigence de note, film deja
aime). Apres **chaque** reponse, le serveur recalcule en direct le
nombre de films Prolog qui correspondent encore au profil partiel
(`recommend_candidates/3`). Des que ce nombre devient petit (4 ou
moins), ou que les questions sont epuisees, le dialogue s'arrete et
affiche les resultats — une regle d'arret dynamique, pas un simple
compteur fixe.

### 4. Le mode groupe (`recommend_group/4` dans `recommend.pl`)

Chaque personne du groupe a son propre profil. Un film est ecarte s'il
touche un genre que **quelqu'un** veut eviter. Parmi les films
restants, le classement privilegie le score **minimum** parmi les
personnes (equite : on ne sacrifie personne), puis a egalite la somme
des scores (plaisir collectif). Chaque resultat affiche le score par
personne.

### 5. L'apprentissage par feedback (`feedback.pl`)

Chaque vote 👍/👎 sur un film met a jour un compteur par genre et par
ambiance, propre a la session du navigateur (`session_id` genere et
garde en `localStorage`). Quand un compteur depasse un seuil (2 votes
positifs), le genre/l'ambiance est "appris" et vient renforcer
automatiquement les recherches suivantes, meme sans re-cocher les
chips — avec un poids plus faible que les criteres explicites, et une
raison dediee ("Appris de vos votes : ..."). Un compteur tres negatif
(-2) exclut automatiquement le genre, sauf si l'utilisateur l'a
explicitement coche comme aime.

### 6. Le serveur (`server.pl`)

API JSON au-dessus des modules ci-dessus, plus les fichiers statiques
de `public/` :

| Endpoint | Usage |
|---|---|
| `GET  /api/movies` | catalogue complet |
| `GET  /api/genres` / `/api/moods` | valeurs possibles |
| `POST /api/recommend` | recommandation individuelle (+ apprentissage) |
| `POST /api/group/recommend` | recommandation pour un groupe |
| `POST /api/dialogue/start` | demarre le dialogue guide |
| `POST /api/dialogue/answer` | repond a une question |
| `POST /api/dialogue/reset` | relance le dialogue a zero |
| `POST /api/feedback` | enregistre un vote 👍/👎 |

## Installation

Il faut [SWI-Prolog](https://www.swi-prolog.org/) (version 8+) :

```bash
sudo apt-get update && sudo apt-get install -y swi-prolog swi-prolog-core-packages
```

## Lancer le projet

```bash
cd /home/lgelgon/prolog-movie-recommender
swipl run.pl
```

Le serveur affiche `Interface disponible sur http://localhost:8090`.
Ouvre cette adresse dans un navigateur (le port 8090 est utilise plutot
que 8080 car ce dernier est deja occupe sur cette machine par le
listener Oracle XDB). Laisse le terminal (et le prompt Prolog `?-`)
ouvert : le serveur tourne dans un thread en arriere-plan tant que le
processus `swipl` reste actif.

Pour changer de port, edite `run.pl` (`start_server(8090)`) ou tape,
apres chargement :

```prolog
?- start_server(9090).
```

## Tester le moteur directement en Prolog

```bash
swipl prolog/recommend.pl
```

```prolog
?- recommend(profile{genres:[sci_fi, thriller], moods:[thought_provoking],
              liked_movies:[m2, m4], avoid_genres:[horror], min_rating:0,
              learned_genres:[], learned_moods:[]}, 5, Results, _),
   maplist([R]>>(format("~w (~w) — score ~w~n", [R.title, R.year, R.score])), Results).
```

Cela devrait mettre en avant des films comme *Interstellar*, *The Prestige*
ou *Blade Runner 2049* (autres films de Christopher Nolan / Denis
Villeneuve, dans les genres science-fiction / thriller).

## Idees d'evolution

- Vraie selection de question par gain d'information (entropie) plutot
  qu'un ordre fixe dans le dialogue.
- Persister les gouts/votes dans un fichier plutot qu'en memoire (les
  sessions sont perdues au redemarrage du serveur).
- Recommandation "en cascade" : graphe de films similaires visualise en
  D3.js.
- Importer un vrai catalogue (API type TMDB) avec affiches.
