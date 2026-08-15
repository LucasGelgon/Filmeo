:- module(movies, [
    movie/5,
    movie_genre/2,
    movie_director/2,
    movie_actor/2,
    movie_mood/2,
    movie_description/2,
    all_genres/1,
    all_moods/1
]).

/** <module> Base de connaissances des films
 *
 *  movie(Id, Titre, Annee, DureeMinutes, Note)
 *  movie_genre(Id, Genre)
 *  movie_director(Id, Realisateur)
 *  movie_actor(Id, Acteur)
 *  movie_mood(Id, Ambiance)
 *  movie_description(Id, Texte)
 */

% ---------------------------------------------------------------------------
% Films
% ---------------------------------------------------------------------------

movie(m1,  'The Matrix', 1999, 136, 8.7).
movie(m2,  'Inception', 2010, 148, 8.8).
movie(m3,  'Interstellar', 2014, 169, 8.7).
movie(m4,  'The Dark Knight', 2008, 152, 9.0).
movie(m5,  'Pulp Fiction', 1994, 154, 8.9).
movie(m6,  'Fight Club', 1999, 139, 8.8).
movie(m7,  'Forrest Gump', 1994, 142, 8.8).
movie(m8,  'The Shawshank Redemption', 1994, 142, 9.3).
movie(m9,  'Se7en', 1995, 127, 8.6).
movie(m10, 'The Silence of the Lambs', 1991, 118, 8.6).
movie(m11, 'Get Out', 2017, 104, 7.7).
movie(m12, 'Hereditary', 2018, 127, 7.3).
movie(m13, 'A Quiet Place', 2018, 90, 7.5).
movie(m14, 'The Conjuring', 2013, 112, 7.5).
movie(m15, 'La La Land', 2016, 128, 8.0).
movie(m16, 'Amelie', 2001, 122, 8.3).
movie(m17, 'The Grand Budapest Hotel', 2014, 99, 8.1).
movie(m18, 'Little Miss Sunshine', 2006, 101, 7.8).
movie(m19, 'Superbad', 2007, 113, 7.6).
movie(m20, 'The Hangover', 2009, 100, 7.7).
movie(m21, 'Titanic', 1997, 195, 7.9).
movie(m22, 'Notting Hill', 1999, 124, 7.2).
movie(m23, 'Pride and Prejudice', 2005, 129, 7.8).
movie(m24, 'Eternal Sunshine of the Spotless Mind', 2004, 108, 8.3).
movie(m25, 'Mad Max: Fury Road', 2015, 120, 8.1).
movie(m26, 'John Wick', 2014, 101, 7.4).
movie(m27, 'Die Hard', 1988, 132, 8.2).
movie(m28, 'Gladiator', 2000, 155, 8.5).
movie(m29, 'The Avengers', 2012, 143, 8.0).
movie(m30, 'Spirited Away', 2001, 125, 8.6).
movie(m31, 'Your Name', 2016, 106, 8.4).
movie(m32, 'Toy Story', 1995, 81, 8.3).
movie(m33, 'Up', 2009, 96, 8.3).
movie(m34, 'Coco', 2017, 105, 8.4).
movie(m35, 'The Lord of the Rings: The Fellowship of the Ring', 2001, 178, 8.9).
movie(m36, 'Harry Potter and the Philosopher''s Stone', 2001, 152, 7.6).
movie(m37, 'Pan''s Labyrinth', 2006, 118, 8.2).
movie(m38, 'Blade Runner 2049', 2017, 164, 8.0).
movie(m39, 'Arrival', 2016, 116, 7.9).
movie(m40, 'The Prestige', 2006, 130, 8.5).
movie(m41, 'Parasite', 2019, 132, 8.5).
movie(m42, 'No Country for Old Men', 2007, 122, 8.2).
movie(m43, 'The Departed', 2006, 151, 8.5).
movie(m44, 'Whiplash', 2014, 106, 8.5).
movie(m45, 'Good Will Hunting', 1997, 126, 8.3).
movie(m46, 'Coraline', 2009, 100, 7.7).
movie(m47, 'The Nightmare Before Christmas', 1993, 76, 7.9).
movie(m48, 'Knives Out', 2019, 130, 7.9).
movie(m49, 'Zodiac', 2007, 157, 7.7).
movie(m50, 'Her', 2013, 126, 8.0).

% ---------------------------------------------------------------------------
% Genres
% ---------------------------------------------------------------------------

movie_genre(m1,  sci_fi).       movie_genre(m1,  action).
movie_genre(m2,  sci_fi).       movie_genre(m2,  thriller).
movie_genre(m3,  sci_fi).       movie_genre(m3,  drama).
movie_genre(m4,  action).       movie_genre(m4,  crime).      movie_genre(m4, thriller).
movie_genre(m5,  crime).        movie_genre(m5,  drama).
movie_genre(m6,  drama).        movie_genre(m6,  thriller).
movie_genre(m7,  drama).        movie_genre(m7,  romance).
movie_genre(m8,  drama).
movie_genre(m9,  thriller).     movie_genre(m9,  crime).      movie_genre(m9, horror).
movie_genre(m10, thriller).     movie_genre(m10, horror).     movie_genre(m10, crime).
movie_genre(m11, horror).       movie_genre(m11, thriller).
movie_genre(m12, horror).       movie_genre(m12, drama).
movie_genre(m13, horror).       movie_genre(m13, thriller).
movie_genre(m14, horror).
movie_genre(m15, romance).      movie_genre(m15, comedy).     movie_genre(m15, drama).
movie_genre(m16, romance).      movie_genre(m16, comedy).
movie_genre(m17, comedy).       movie_genre(m17, drama).
movie_genre(m18, comedy).       movie_genre(m18, drama).
movie_genre(m19, comedy).
movie_genre(m20, comedy).
movie_genre(m21, romance).      movie_genre(m21, drama).
movie_genre(m22, romance).      movie_genre(m22, comedy).
movie_genre(m23, romance).      movie_genre(m23, drama).
movie_genre(m24, romance).      movie_genre(m24, drama).      movie_genre(m24, sci_fi).
movie_genre(m25, action).       movie_genre(m25, sci_fi).
movie_genre(m26, action).       movie_genre(m26, thriller).
movie_genre(m27, action).       movie_genre(m27, thriller).
movie_genre(m28, action).       movie_genre(m28, drama).
movie_genre(m29, action).       movie_genre(m29, sci_fi).
movie_genre(m30, animation).    movie_genre(m30, fantasy).
movie_genre(m31, animation).    movie_genre(m31, romance).    movie_genre(m31, fantasy).
movie_genre(m32, animation).    movie_genre(m32, comedy).
movie_genre(m33, animation).    movie_genre(m33, comedy).     movie_genre(m33, drama).
movie_genre(m34, animation).    movie_genre(m34, fantasy).
movie_genre(m35, fantasy).      movie_genre(m35, action).
movie_genre(m36, fantasy).      movie_genre(m36, family).
movie_genre(m37, fantasy).      movie_genre(m37, drama).      movie_genre(m37, horror).
movie_genre(m38, sci_fi).       movie_genre(m38, thriller).
movie_genre(m39, sci_fi).       movie_genre(m39, drama).
movie_genre(m40, thriller).     movie_genre(m40, drama).      movie_genre(m40, sci_fi).
movie_genre(m41, drama).        movie_genre(m41, thriller).   movie_genre(m41, comedy).
movie_genre(m42, thriller).     movie_genre(m42, crime).      movie_genre(m42, drama).
movie_genre(m43, crime).        movie_genre(m43, thriller).   movie_genre(m43, drama).
movie_genre(m44, drama).
movie_genre(m45, drama).
movie_genre(m46, animation).    movie_genre(m46, fantasy).    movie_genre(m46, horror).
movie_genre(m47, animation).    movie_genre(m47, fantasy).
movie_genre(m48, mystery).      movie_genre(m48, comedy).     movie_genre(m48, crime).
movie_genre(m49, thriller).     movie_genre(m49, crime).      movie_genre(m49, mystery).
movie_genre(m50, romance).      movie_genre(m50, sci_fi).     movie_genre(m50, drama).

% ---------------------------------------------------------------------------
% Realisateurs
% ---------------------------------------------------------------------------

movie_director(m1,  'Lana Wachowski').
movie_director(m2,  'Christopher Nolan').
movie_director(m3,  'Christopher Nolan').
movie_director(m4,  'Christopher Nolan').
movie_director(m5,  'Quentin Tarantino').
movie_director(m6,  'David Fincher').
movie_director(m7,  'Robert Zemeckis').
movie_director(m8,  'Frank Darabont').
movie_director(m9,  'David Fincher').
movie_director(m10, 'Jonathan Demme').
movie_director(m11, 'Jordan Peele').
movie_director(m12, 'Ari Aster').
movie_director(m13, 'John Krasinski').
movie_director(m14, 'James Wan').
movie_director(m15, 'Damien Chazelle').
movie_director(m16, 'Jean-Pierre Jeunet').
movie_director(m17, 'Wes Anderson').
movie_director(m18, 'Jonathan Dayton').
movie_director(m19, 'Greg Mottola').
movie_director(m20, 'Todd Phillips').
movie_director(m21, 'James Cameron').
movie_director(m22, 'Roger Michell').
movie_director(m23, 'Joe Wright').
movie_director(m24, 'Michel Gondry').
movie_director(m25, 'George Miller').
movie_director(m26, 'Chad Stahelski').
movie_director(m27, 'John McTiernan').
movie_director(m28, 'Ridley Scott').
movie_director(m29, 'Joss Whedon').
movie_director(m30, 'Hayao Miyazaki').
movie_director(m31, 'Makoto Shinkai').
movie_director(m32, 'John Lasseter').
movie_director(m33, 'Pete Docter').
movie_director(m34, 'Lee Unkrich').
movie_director(m35, 'Peter Jackson').
movie_director(m36, 'Chris Columbus').
movie_director(m37, 'Guillermo del Toro').
movie_director(m38, 'Denis Villeneuve').
movie_director(m39, 'Denis Villeneuve').
movie_director(m40, 'Christopher Nolan').
movie_director(m41, 'Bong Joon-ho').
movie_director(m42, 'Ethan Coen').
movie_director(m43, 'Martin Scorsese').
movie_director(m44, 'Damien Chazelle').
movie_director(m45, 'Gus Van Sant').
movie_director(m46, 'Henry Selick').
movie_director(m47, 'Henry Selick').
movie_director(m48, 'Rian Johnson').
movie_director(m49, 'David Fincher').
movie_director(m50, 'Spike Jonze').

% ---------------------------------------------------------------------------
% Acteurs principaux (plusieurs faits possibles par film)
% ---------------------------------------------------------------------------

movie_actor(m1,  'Keanu Reeves').        movie_actor(m1,  'Carrie-Anne Moss').
movie_actor(m2,  'Leonardo DiCaprio').   movie_actor(m2,  'Elliot Page').
movie_actor(m3,  'Matthew McConaughey').movie_actor(m3,  'Anne Hathaway').
movie_actor(m4,  'Christian Bale').      movie_actor(m4,  'Heath Ledger').
movie_actor(m5,  'John Travolta').       movie_actor(m5,  'Samuel L. Jackson').
movie_actor(m6,  'Brad Pitt').           movie_actor(m6,  'Edward Norton').
movie_actor(m7,  'Tom Hanks').           movie_actor(m7,  'Robin Wright').
movie_actor(m8,  'Tim Robbins').         movie_actor(m8,  'Morgan Freeman').
movie_actor(m9,  'Brad Pitt').           movie_actor(m9,  'Morgan Freeman').
movie_actor(m10, 'Jodie Foster').        movie_actor(m10, 'Anthony Hopkins').
movie_actor(m11, 'Daniel Kaluuya').
movie_actor(m12, 'Toni Collette').
movie_actor(m13, 'Emily Blunt').         movie_actor(m13, 'John Krasinski').
movie_actor(m14, 'Vera Farmiga').        movie_actor(m14, 'Patrick Wilson').
movie_actor(m15, 'Ryan Gosling').        movie_actor(m15, 'Emma Stone').
movie_actor(m16, 'Audrey Tautou').
movie_actor(m17, 'Ralph Fiennes').
movie_actor(m18, 'Abigail Breslin').     movie_actor(m18, 'Steve Carell').
movie_actor(m19, 'Jonah Hill').          movie_actor(m19, 'Michael Cera').
movie_actor(m20, 'Bradley Cooper').      movie_actor(m20, 'Zach Galifianakis').
movie_actor(m21, 'Leonardo DiCaprio').   movie_actor(m21, 'Kate Winslet').
movie_actor(m22, 'Julia Roberts').       movie_actor(m22, 'Hugh Grant').
movie_actor(m23, 'Keira Knightley').
movie_actor(m24, 'Jim Carrey').          movie_actor(m24, 'Kate Winslet').
movie_actor(m25, 'Tom Hardy').           movie_actor(m25, 'Charlize Theron').
movie_actor(m26, 'Keanu Reeves').
movie_actor(m27, 'Bruce Willis').
movie_actor(m28, 'Russell Crowe').       movie_actor(m28, 'Joaquin Phoenix').
movie_actor(m29, 'Robert Downey Jr.').   movie_actor(m29, 'Chris Evans').
movie_actor(m30, 'Rumi Hiiragi').
movie_actor(m31, 'Ryunosuke Kamiki').
movie_actor(m32, 'Tom Hanks').           movie_actor(m32, 'Tim Allen').
movie_actor(m33, 'Edward Asner').
movie_actor(m34, 'Anthony Gonzalez').
movie_actor(m35, 'Elijah Wood').         movie_actor(m35, 'Ian McKellen').
movie_actor(m36, 'Daniel Radcliffe').    movie_actor(m36, 'Emma Watson').
movie_actor(m37, 'Ivana Baquero').
movie_actor(m38, 'Ryan Gosling').        movie_actor(m38, 'Harrison Ford').
movie_actor(m39, 'Amy Adams').
movie_actor(m40, 'Christian Bale').      movie_actor(m40, 'Hugh Jackman').
movie_actor(m41, 'Song Kang-ho').
movie_actor(m42, 'Javier Bardem').       movie_actor(m42, 'Tommy Lee Jones').
movie_actor(m43, 'Leonardo DiCaprio').   movie_actor(m43, 'Matt Damon').
movie_actor(m44, 'Miles Teller').        movie_actor(m44, 'J.K. Simmons').
movie_actor(m45, 'Matt Damon').          movie_actor(m45, 'Robin Williams').
movie_actor(m46, 'Dakota Fanning').
movie_actor(m47, 'Chris Sarandon').
movie_actor(m48, 'Daniel Craig').        movie_actor(m48, 'Chris Evans').
movie_actor(m49, 'Jake Gyllenhaal').     movie_actor(m49, 'Robert Downey Jr.').
movie_actor(m50, 'Joaquin Phoenix').     movie_actor(m50, 'Scarlett Johansson').

% ---------------------------------------------------------------------------
% Ambiances / moods
% ---------------------------------------------------------------------------

movie_mood(m1,  intense).      movie_mood(m1,  thought_provoking).
movie_mood(m2,  intense).      movie_mood(m2,  thought_provoking).
movie_mood(m3,  epic).         movie_mood(m3,  thought_provoking).  movie_mood(m3, emotional).
movie_mood(m4,  intense).      movie_mood(m4,  dark).
movie_mood(m5,  intense).      movie_mood(m5,  dark).
movie_mood(m6,  dark).         movie_mood(m6,  thought_provoking).
movie_mood(m7,  feelgood).     movie_mood(m7,  emotional).
movie_mood(m8,  emotional).    movie_mood(m8,  thought_provoking).
movie_mood(m9,  dark).         movie_mood(m9,  intense).
movie_mood(m10, dark).         movie_mood(m10, intense).
movie_mood(m11, dark).         movie_mood(m11, thought_provoking).
movie_mood(m12, dark).         movie_mood(m12, scary).
movie_mood(m13, intense).      movie_mood(m13, scary).
movie_mood(m14, scary).
movie_mood(m15, feelgood).     movie_mood(m15, emotional).
movie_mood(m16, feelgood).     movie_mood(m16, relaxing).
movie_mood(m17, feelgood).     movie_mood(m17, funny).
movie_mood(m18, feelgood).     movie_mood(m18, funny).
movie_mood(m19, funny).        movie_mood(m19, relaxing).
movie_mood(m20, funny).
movie_mood(m21, emotional).    movie_mood(m21, epic).
movie_mood(m22, feelgood).     movie_mood(m22, relaxing).
movie_mood(m23, emotional).    movie_mood(m23, relaxing).
movie_mood(m24, emotional).    movie_mood(m24, thought_provoking).
movie_mood(m25, intense).      movie_mood(m25, epic).
movie_mood(m26, intense).
movie_mood(m27, intense).
movie_mood(m28, epic).         movie_mood(m28, emotional).
movie_mood(m29, epic).         movie_mood(m29, funny).
movie_mood(m30, relaxing).     movie_mood(m30, thought_provoking).
movie_mood(m31, emotional).    movie_mood(m31, relaxing).
movie_mood(m32, feelgood).     movie_mood(m32, funny).
movie_mood(m33, emotional).    movie_mood(m33, feelgood).
movie_mood(m34, emotional).    movie_mood(m34, feelgood).
movie_mood(m35, epic).         movie_mood(m35, thought_provoking).
movie_mood(m36, feelgood).     movie_mood(m36, relaxing).
movie_mood(m37, dark).         movie_mood(m37, thought_provoking).
movie_mood(m38, thought_provoking). movie_mood(m38, dark).
movie_mood(m39, thought_provoking). movie_mood(m39, emotional).
movie_mood(m40, thought_provoking). movie_mood(m40, dark).
movie_mood(m41, thought_provoking). movie_mood(m41, dark).
movie_mood(m42, dark).         movie_mood(m42, thought_provoking).
movie_mood(m43, dark).         movie_mood(m43, intense).
movie_mood(m44, intense).      movie_mood(m44, thought_provoking).
movie_mood(m45, emotional).    movie_mood(m45, thought_provoking).
movie_mood(m46, dark).         movie_mood(m46, scary).
movie_mood(m47, funny).        movie_mood(m47, relaxing).
movie_mood(m48, funny).        movie_mood(m48, thought_provoking).
movie_mood(m49, dark).         movie_mood(m49, thought_provoking).
movie_mood(m50, emotional).    movie_mood(m50, thought_provoking).

% ---------------------------------------------------------------------------
% Descriptions courtes
% ---------------------------------------------------------------------------

movie_description(m1,  "Un programmeur decouvre que le monde reel est une simulation.").
movie_description(m2,  "Un voleur s'infiltre dans les reves pour implanter une idee.").
movie_description(m3,  "Des astronautes cherchent une nouvelle planete pour l'humanite.").
movie_description(m4,  "Batman affronte le chaos incarne par le Joker.").
movie_description(m5,  "Des histoires de gangsters s'entrecroisent a Los Angeles.").
movie_description(m6,  "Un employe insomniaque cree un club de combat clandestin.").
movie_description(m7,  "La vie extraordinaire d'un homme au grand coeur.").
movie_description(m8,  "L'amitie et l'espoir derriere les murs d'une prison.").
movie_description(m9,  "Deux enqueteurs traquent un tueur inspire par les peches capitaux.").
movie_description(m10, "Une jeune recrue du FBI traque un tueur en serie.").
movie_description(m11, "Un weekend chez sa belle-famille tourne au cauchemar.").
movie_description(m12, "Une famille est hantee par un lourd secret hereditaire.").
movie_description(m13, "Une famille survit en silence face a des creatures a l'ouie surdeveloppee.").
movie_description(m14, "Des enqueteurs paranormaux affrontent une presence malefique.").
movie_description(m15, "Une actrice et un musicien poursuivent leurs reves a Los Angeles.").
movie_description(m16, "Une serveuse parisienne change discretement la vie des autres.").
movie_description(m17, "Un concierge legendaire vit des aventures rocambolesques.").
movie_description(m18, "Une famille dysfonctionnelle part en road trip pour un concours de beaute.").
movie_description(m19, "Deux amis tentent de vivre une derniere soiree de lycee memorable.").
movie_description(m20, "Un enterrement de vie de garcon degenere a Las Vegas.").
movie_description(m21, "Une histoire d'amour naît a bord d'un paquebot legendaire.").
movie_description(m22, "Un libraire londonien tombe amoureux d'une star de cinema.").
movie_description(m23, "Une romance dans l'Angleterre du 19e siecle.").
movie_description(m24, "Un couple efface ses souvenirs l'un de l'autre apres une rupture.").
movie_description(m25, "Une course-poursuite effrenee dans un desert post-apocalyptique.").
movie_description(m26, "Un ancien tueur a gages reprend les armes pour venger son chien.").
movie_description(m27, "Un policier seul affronte des terroristes dans une tour.").
movie_description(m28, "Un general romain dechu devient gladiateur pour se venger.").
movie_description(m29, "Des super-heros s'unissent pour sauver la Terre.").
movie_description(m30, "Une fillette explore un monde peuple d'esprits.").
movie_description(m31, "Deux adolescents echangent mysterieusement de corps.").
movie_description(m32, "Des jouets prennent vie quand personne ne regarde.").
movie_description(m33, "Un veuf s'envole vers l'aventure grace a des ballons.").
movie_description(m34, "Un jeune garcon decouvre le pays des morts.").
movie_description(m35, "Un jeune hobbit part detruire un anneau maléfique.").
movie_description(m36, "Un jeune sorcier decouvre une ecole de magie.").
movie_description(m37, "Une fillette se refugie dans un monde fantastique et sombre.").
movie_description(m38, "Un policier replicant decouvre un secret bouleversant.").
movie_description(m39, "Une linguiste tente de communiquer avec des extraterrestres.").
movie_description(m40, "Deux magiciens rivaux se livrent une guerre sans merci.").
movie_description(m41, "Une famille pauvre s'infiltre chez une famille riche.").
movie_description(m42, "Un chasseur tombe sur une mallette d'argent et un tueur implacable.").
movie_description(m43, "Un flic infiltre et un truand infiltre se traquent mutuellement.").
movie_description(m44, "Un jeune batteur pousse son art sous la pression d'un professeur tyrannique.").
movie_description(m45, "Un genie autodidacte doit affronter son passe.").
movie_description(m46, "Une fillette decouvre un monde parallele inquietant derriere une porte.").
movie_description(m47, "Le roi d'Halloween decouvre le monde de Noel.").
movie_description(m48, "Un detective enquete sur la mort suspecte d'un patriarche fortune.").
movie_description(m49, "L'enquete obsessionnelle sur l'identite du tueur du zodiaque.").
movie_description(m50, "Un homme solitaire tombe amoureux d'une intelligence artificielle.").

% ---------------------------------------------------------------------------
% Helpers
% ---------------------------------------------------------------------------

all_genres(Genres) :-
    setof(G, Id^movie_genre(Id, G), Genres).

all_moods(Moods) :-
    setof(Mo, Id^movie_mood(Id, Mo), Moods).
