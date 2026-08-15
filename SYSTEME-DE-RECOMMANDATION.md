# Systeme de notation et de recommandation — Filméo

Ce document explique comment Filméo note les films et comment il choisit
quoi te recommander. L'objectif du systeme est d'etre **transparent** :
chaque suggestion peut etre justifiee point par point, contrairement a un
modele boite noire.

## 1. Deux notions a ne pas confondre

- **La note du film** : une note fixe sur 10, stockee dans le catalogue
  (ex : *The Shawshank Redemption* = 9.3). Elle ne change jamais, quel que
  soit l'utilisateur.
- **Le score de recommandation** : un nombre calcule **a la volee**, pour
  UN utilisateur et UN film donnes. Il n'a pas de maximum fixe (il peut
  depasser 10 si un film coche beaucoup de cases) : plus il est haut, plus
  le film correspond a ce que tu as demande.

La note du film n'est qu'un des ingredients du score ; elle sert surtout de
petit bonus de qualite (voir plus bas).

## 2. Les criteres pris en compte

Pour un film candidat, le systeme regarde :

| Critere | Ce qu'il regarde |
|---|---|
| Genres aimes | Les genres du film qui sont dans ta liste "genres que vous aimez" |
| Ambiance | Les ambiances du film (intense, feel-good, sombre...) qui matchent ta selection |
| Realisateur | Si le realisateur a deja fait un film que tu as coche comme aime |
| Acteurs | Les acteurs du film qui jouent aussi dans un film que tu as aime |
| Note du film | Bonus si le film est particulierement bien note |
| Appris de tes votes | Genres/ambiances que tu as implicitement valides en votant 👍 sur plusieurs films (voir section 5) |

Un genre que tu as marque "a eviter" **elimine completement** le film :
il n'apparait jamais, meme s'il coche toutes les autres cases.

## 3. La formule de score

Chaque critere rapporte des points, avec un poids different selon son
importance :

| Critere | Points |
|---|---|
| Chaque genre en commun | +3 |
| Chaque ambiance en commun | +2 |
| Meme realisateur qu'un film aime | +3 |
| Chaque acteur en commun avec un film aime | +1.5 |
| Bonus qualite | +0.4 pour chaque point de note au-dessus de 7 |
| Genre appris (via feedback) | +1.5 |
| Ambiance apprise (via feedback) | +1.0 |

Le score final est simplement la somme de tout ca. Les criteres que tu as
coches toi-meme comptent plus que ceux que le systeme a devines a partir
de tes votes — c'est voulu : on te fait plus confiance sur ce que tu dis
explicitement.

### Exemple concret

Profil : j'aime la science-fiction et le thriller, je cherche une ambiance
"qui fait reflechir", et j'ai deja aime *Inception* (realise par
Christopher Nolan).

Le systeme evalue *Interstellar* :

| Critere | Detail | Points |
|---|---|---|
| Genre | science-fiction en commun | +3 |
| Ambiance | "qui fait reflechir" en commun | +2 |
| Realisateur | Christopher Nolan a aussi realise *Inception* | +3 |
| Acteurs | aucun acteur en commun avec *Inception* | +0 |
| Qualite | note 8.7, soit 1.7 point au-dessus de 7 → 1.7 × 0.4 | +0.68 |
| **Total** | | **8.68 → score 8.7** |

C'est ce detail (appele le "breakdown") qui s'affiche derriere le bouton
**"Pourquoi ce film ?"** sur chaque carte de resultat.

## 4. Les trois facons d'obtenir une recommandation

### Par criteres

Tu coches des chips (genres, ambiances, genres a eviter) et des films que
tu as deja aimes, puis le systeme calcule le score ci-dessus pour tous les
films du catalogue et te montre les mieux notes.

### Dialogue guide

Plutot que de tout cocher d'un coup, tu reponds a une suite de questions
(genre, ambiance, genre a eviter, exigence de qualite, film deja aime).
Apres chaque reponse, le nombre de films encore possibles est recalcule en
direct. Des qu'il n'en reste plus beaucoup — ou que les questions sont
epuisees — le dialogue s'arrete et affiche directement les resultats. Le
nombre de questions posees s'adapte donc a la precision de tes reponses.

### Soiree entre amis

Chaque personne du groupe a ses propres gouts. Un film est ecarte des
qu'**une seule** personne du groupe a coche un de ses genres comme "a
eviter". Parmi les films restants, le film choisi n'est pas forcement
celui qui plait le plus en moyenne : c'est celui dont **la personne la
moins convaincue est quand meme satisfaite**. Concretement, on classe les
films par leur score minimum parmi les participants (pour ne sacrifier
personne), et seulement en cas d'egalite on regarde le score total du
groupe.

## 5. L'apprentissage par feedback

Chaque vote 👍 ou 👎 sur un film met a jour un petit compteur, propre a
ton navigateur, pour chaque genre et chaque ambiance de ce film :

- un 👍 ajoute +1 au compteur des genres/ambiances du film,
- un 👎 retire -1.

Ce compteur est plafonne entre -5 et +5. Deux votes positifs suffisent
pour qu'un genre ou une ambiance soit considere "appris" : il vient alors
booster automatiquement tes prochaines recherches (avec un poids plus
faible que si tu l'avais coche toi-meme), meme sans re-cocher la chip. A
l'inverse, si le compteur descend a -2, le genre est automatiquement
ajoute a ta liste "a eviter" — sauf si tu l'as toi-meme coche comme aime,
qui a toujours le dernier mot.

## 6. Limites actuelles

- Les gouts et les votes sont gardes en memoire le temps que le serveur
  tourne : ils sont perdus si le serveur redemarre.
- Le catalogue est fixe (50 films) : pas de mise a jour automatique.
- L'ordre des questions du dialogue guide est fixe ; un systeme plus
  avance choisirait la question la plus discriminante a chaque etape.
