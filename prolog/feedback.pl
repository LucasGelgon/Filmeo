:- module(feedback, [
    record_feedback/3,   % +SessionId, +MovieId, +Vote (1 ou -1)
    learned_boosts/3,    % +SessionId, -GenresBoost, -MoodsBoost
    learned_avoid/2,     % +SessionId, -GenresAvoid
    reset_feedback/1
]).

:- use_module(movies).

/** <module> Apprentissage leger par retour utilisateur
 *
 *  Chaque vote (pouce leve / baisse) sur un film met a jour un compteur
 *  par genre et par ambiance, propre a la session utilisateur. Quand un
 *  compteur depasse un seuil positif, le genre ou l'ambiance est "appris"
 *  et vient renforcer les prochaines recommandations. 
 *  A l'inverse, un compteur tres negatif fait passer le genre en exclusion automatique.
 */

:- dynamic feedback_tally/3.  % feedback_tally(SessionId, Attribute, Score)

boost_threshold(2).
avoid_threshold(-2).
tally_min(-5).
tally_max(5).

record_feedback(SessionId, MovieId, Vote) :-
    must_be(integer, Vote),
    forall(movie_genre(MovieId, G), adjust_tally(SessionId, genre(G), Vote)),
    forall(movie_mood(MovieId, Mo), adjust_tally(SessionId, mood(Mo), Vote)).

adjust_tally(SessionId, Attr, Delta) :-
    with_mutex(feedback_mutex, update_tally(SessionId, Attr, Delta)).

update_tally(SessionId, Attr, Delta) :-
    ( retract(feedback_tally(SessionId, Attr, Old)) -> true ; Old = 0 ),
    tally_min(Min), tally_max(Max),
    New is max(Min, min(Max, Old + Delta)),
    assertz(feedback_tally(SessionId, Attr, New)).

learned_boosts(SessionId, GenresBoost, MoodsBoost) :-
    boost_threshold(T),
    findall(G, (feedback_tally(SessionId, genre(G), S), S >= T), GenresBoost),
    findall(Mo, (feedback_tally(SessionId, mood(Mo), S), S >= T), MoodsBoost).

learned_avoid(SessionId, GenresAvoid) :-
    avoid_threshold(T),
    findall(G, (feedback_tally(SessionId, genre(G), S), S =< T), GenresAvoid).

reset_feedback(SessionId) :-
    with_mutex(feedback_mutex, retractall(feedback_tally(SessionId, _, _))).
