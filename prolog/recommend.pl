:- module(recommend, [
    recommend/4,              % +Profile, +TopN, -Results, -Excluded
    recommend_candidates/3,   % +Profile, -ScoredList, -Excluded
    recommend_group/4,        % +Profiles, +TopN, -Results, -Excluded
    to_result_dict/2,
    first_n/3,
    profile_default/1
]).

:- use_module(movies).
:- use_module(library(lists)).

/** <module> Moteur de recommandation
 *
 *  Un profil utilisateur est un dict Prolog avec les cles :
 *    genres         : liste de genres aimes (poids fort)
 *    moods          : liste d'ambiances recherchees (poids moyen)
 *    liked_movies   : liste d'Id de films deja aimes par l'utilisateur
 *    avoid_genres   : liste de genres a exclure totalement
 *    min_rating     : note minimale exigee (defaut 0)
 *    learned_genres : genres appris implicitement via le feedback (poids reduit)
 *    learned_moods  : ambiances apprises implicitement via le feedback
 *
 *  recommend/4 calcule un score pour chaque film candidat en combinant
 *  plusieurs sources d'evidence, puis renvoie les TopN meilleurs, tries par
 *  score decroissant, avec le detail (breakdown) et les raisons qui
 *  justifient chaque recommandation.
 */

profile_default(profile{
    genres: [], moods: [], liked_movies: [], avoid_genres: [],
    min_rating: 0, learned_genres: [], learned_moods: []
}).

% --------------------------------------------------------------------------
% Ponderations du moteur de scoring
% --------------------------------------------------------------------------

weight(genre_match,         3.0).
weight(mood_match,          2.0).
weight(director_match,      3.0).
weight(actor_match,         1.5).
weight(quality_bonus,       0.4).   % multiplie par (Note - 7)
weight(learned_genre_match, 1.5).   % genre appris via le feedback (poids reduit)
weight(learned_mood_match,  1.0).   % ambiance apprise via le feedback

% --------------------------------------------------------------------------
% Recommandation individuelle
% --------------------------------------------------------------------------

%!  recommend_candidates(+Profile, -ScoredList, -Excluded) is det.
%
%   ScoredList est la liste NON TRIEE de Score-Id-info(Reasons,Breakdown)
%   pour tous les films candidats (score > 0, hors films deja aimes et
%   hors genres a eviter). Utile pour compter les candidats restants
%   (moteur de dialogue) sans construire les dicts de resultat complets.
recommend_candidates(Profile, ScoredList, Excluded) :-
    get_dict_default(liked_movies, Profile, [], LikedMovies),
    get_dict_default(avoid_genres, Profile, [], AvoidGenres),
    get_dict_default(min_rating, Profile, 0, MinRating),

    findall(Id, (movie(Id, _, _, _, _), movie_has_any_genre(Id, AvoidGenres)), Excluded0),
    sort(Excluded0, Excluded),

    findall(Score-Id-info(Reasons, Breakdown),
        (   movie(Id, _, _, _, Rating),
            Rating >= MinRating,
            \+ member(Id, LikedMovies),
            \+ member(Id, Excluded),
            score_movie(Id, Profile, Score, Reasons, Breakdown),
            Score > 0
        ),
        ScoredList).

%!  recommend(+Profile, +TopN, -Results, -Excluded) is det.
recommend(Profile, TopN, Results, Excluded) :-
    recommend_candidates(Profile, ScoredList, Excluded),
    sort(0, @>=, ScoredList, ScoredSorted),
    first_n(TopN, ScoredSorted, TopScored),
    maplist(to_result_dict, TopScored, Results).

% --------------------------------------------------------------------------
% Recommandation de groupe ("soiree entre amis")
% --------------------------------------------------------------------------

%!  recommend_group(+Profiles, +TopN, -Results, -Excluded) is det.
%
%   Chaque profil de la liste Profiles peut contenir une cle `name`. Un
%   film n'est jamais propose s'il touche un genre a eviter par AU MOINS
%   une personne du groupe. Parmi les films restants, le classement
%   privilegie le "min" des scores individuels (equite : personne n'est
%   sacrifie) puis, a egalite, la somme des scores (plaisir collectif).
recommend_group(Profiles, TopN, Results, Excluded) :-
    findall(Avoid, (member(P, Profiles), get_dict_default(avoid_genres, P, [], Avoid)), AvoidLists),
    append(AvoidLists, AvoidAll0),
    sort(AvoidAll0, AvoidUnion),

    findall(Id, (movie(Id, _, _, _, _), movie_has_any_genre(Id, AvoidUnion)), Excluded0),
    sort(Excluded0, Excluded),

    findall(MinScore-SumScore-Id-PerProfile,
        (   movie(Id, _, _, _, _),
            \+ member(Id, Excluded),
            maplist(score_movie_for_group(Id), Profiles, PerProfile),
            maplist(person_score, PerProfile, Scores),
            min_list(Scores, MinScore),
            sum_list(Scores, SumScore),
            MinScore > 0
        ),
        Rows),

    sort(0, @>=, Rows, SortedRows),
    first_n(TopN, SortedRows, TopRows),
    maplist(to_group_result_dict, TopRows, Results).

score_movie_for_group(Id, Profile, Name-Score-Reasons) :-
    get_dict_default(name, Profile, "Invite", Name),
    score_movie(Id, Profile, Score, Reasons, _Breakdown).

person_score(_-Score-_, Score).

to_group_result_dict(MinScore-_SumScore-Id-PerProfile, result{
    id: Id, title: Title, year: Year, rating: Rating, genres: Genres,
    description: Description, group_score: RoundedMin, per_person: PerPersonDicts
}) :-
    movie(Id, Title, Year, _, Rating),
    findall(G, movie_genre(Id, G), Genres),
    ( movie_description(Id, Description) -> true ; Description = "" ),
    RoundedMin is round(MinScore * 10) / 10,
    maplist(person_dict, PerProfile, PerPersonDicts).

person_dict(Name-Score-Reasons, person{name: Name, score: Rounded, reasons: Reasons}) :-
    Rounded is round(Score * 10) / 10.

% --------------------------------------------------------------------------
% Calcul du score d'un film candidat
% --------------------------------------------------------------------------

score_movie(Id, Profile, Score, Reasons, Breakdown) :-
    get_dict_default(genres, Profile, [], Genres),
    get_dict_default(moods, Profile, [], Moods),
    get_dict_default(liked_movies, Profile, [], LikedMovies),
    get_dict_default(learned_genres, Profile, [], LearnedGenres0),
    get_dict_default(learned_moods, Profile, [], LearnedMoods0),
    subtract(LearnedGenres0, Genres, LearnedGenres),
    subtract(LearnedMoods0, Moods, LearnedMoods),

    findall(G, (movie_genre(Id, G), member(G, Genres)), MatchedGenres),
    findall(Mo, (movie_mood(Id, Mo), member(Mo, Moods)), MatchedMoods),
    findall(G, (movie_genre(Id, G), member(G, LearnedGenres)), MatchedLearnedGenres),
    findall(Mo, (movie_mood(Id, Mo), member(Mo, LearnedMoods)), MatchedLearnedMoods),

    ( LikedMovies == []
    -> MatchedDirectors = [], MatchedActors = []
    ;  findall(D,
           ( movie_director(Id, D), member(LM, LikedMovies), movie_director(LM, D) ),
           MatchedDirectors0),
       sort(MatchedDirectors0, MatchedDirectors),
       findall(A,
           ( movie_actor(Id, A), member(LM, LikedMovies), movie_actor(LM, A) ),
           MatchedActors0),
       sort(MatchedActors0, MatchedActors)
    ),

    length(MatchedGenres, NGenres),
    length(MatchedMoods, NMoods),
    length(MatchedDirectors, NDirectors),
    length(MatchedActors, NActors),
    length(MatchedLearnedGenres, NLearnedGenres),
    length(MatchedLearnedMoods, NLearnedMoods),

    movie(Id, _, _, _, Rating),
    QualityBonusRaw is max(0, Rating - 7),

    weight(genre_match, WGenre),
    weight(mood_match, WMood),
    weight(director_match, WDirector),
    weight(actor_match, WActor),
    weight(quality_bonus, WQuality),
    weight(learned_genre_match, WLearnedGenre),
    weight(learned_mood_match, WLearnedMood),

    GenreScore is NGenres * WGenre,
    MoodScore is NMoods * WMood,
    DirectorScore is NDirectors * WDirector,
    ActorScore is NActors * WActor,
    QualityScore is QualityBonusRaw * WQuality,
    LearnedScore is NLearnedGenres * WLearnedGenre + NLearnedMoods * WLearnedMood,

    Score is GenreScore + MoodScore + DirectorScore + ActorScore + QualityScore + LearnedScore,

    maplist(round1, [GenreScore, MoodScore, DirectorScore, ActorScore, QualityScore, LearnedScore],
            [RGenre, RMood, RDirector, RActor, RQuality, RLearned]),
    Breakdown = breakdown{genre: RGenre, mood: RMood, director: RDirector,
                           actor: RActor, quality: RQuality, learned: RLearned},

    build_reasons(MatchedGenres, MatchedMoods, MatchedDirectors, MatchedActors,
                  MatchedLearnedGenres, MatchedLearnedMoods, Rating, Reasons).

round1(X, Y) :- Y is round(X * 10) / 10.

build_reasons(Genres, Moods, Directors, Actors, LearnedGenres, LearnedMoods, Rating, Reasons) :-
    findall(R, reason(genre, Genres, R), R1),
    findall(R, reason(mood, Moods, R), R2),
    findall(R, reason(director, Directors, R), R3),
    findall(R, reason(actor, Actors, R), R4),
    findall(R, reason(learned_genre, LearnedGenres, R), R5),
    findall(R, reason(learned_mood, LearnedMoods, R), R6),
    ( Rating >= 8.5 -> R7 = ["Tres bien note par la critique"] ; R7 = [] ),
    append([R1, R2, R3, R4, R5, R6, R7], Reasons).

reason(genre, List, R) :-
    member(G, List), format(atom(R), "Genre apprecie : ~w", [G]).
reason(mood, List, R) :-
    member(Mo, List), format(atom(R), "Ambiance recherchee : ~w", [Mo]).
reason(director, List, R) :-
    member(D, List), format(atom(R), "Meme realisateur qu'un film que vous aimez : ~w", [D]).
reason(actor, List, R) :-
    member(A, List), format(atom(R), "Acteur commun avec un film que vous aimez : ~w", [A]).
reason(learned_genre, List, R) :-
    member(G, List), format(atom(R), "Appris de vos votes : vous aimez le genre ~w", [G]).
reason(learned_mood, List, R) :-
    member(Mo, List), format(atom(R), "Appris de vos votes : vous aimez l'ambiance ~w", [Mo]).

% --------------------------------------------------------------------------
% Utilitaires
% --------------------------------------------------------------------------

movie_has_any_genre(_, []) :- !, fail.
movie_has_any_genre(Id, Genres) :-
    movie_genre(Id, G),
    member(G, Genres),
    !.

first_n(N, List, Firsts) :-
    length(Prefix, N),
    ( append(Prefix, _, List)
    -> Firsts = Prefix
    ;  Firsts = List
    ).

to_result_dict(Score-Id-info(Reasons, Breakdown), result{
    id: Id,
    title: Title,
    year: Year,
    rating: Rating,
    score: RoundedScore,
    reasons: Reasons,
    breakdown: Breakdown,
    genres: Genres,
    description: Description
}) :-
    movie(Id, Title, Year, _, Rating),
    findall(G, movie_genre(Id, G), Genres),
    ( movie_description(Id, Description) -> true ; Description = "" ),
    RoundedScore is round(Score * 10) / 10.

get_dict_default(Key, Dict, Default, Value) :-
    ( is_dict(Dict), get_dict(Key, Dict, V)
    -> Value = V
    ;  Value = Default
    ).
