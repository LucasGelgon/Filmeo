:- module(server, [start_server/0, start_server/1]).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_files)).
:- use_module(library(http/http_json)).
:- use_module(library(http/json)).
:- use_module(library(http/http_parameters)).
:- use_module(library(lists)).

:- use_module(movies).
:- use_module(recommend).
:- use_module(dialogue).
:- use_module(feedback).

/** <module> Serveur HTTP du systeme de recommandation
 *
 *  Sert l'interface statique (public/) et une petite API JSON :
 *
 *    GET  /api/movies             -> catalogue complet des films
 *    GET  /api/genres             -> liste des genres disponibles
 *    GET  /api/moods              -> liste des ambiances disponibles
 *    POST /api/recommend          -> recommandation individuelle (+ apprentissage)
 *    POST /api/group/recommend    -> recommandation pour un groupe
 *    POST /api/dialogue/start     -> demarre le systeme expert conversationnel
 *    POST /api/dialogue/answer    -> repond a une question du dialogue
 *    POST /api/dialogue/reset     -> reinitialise le dialogue
 *    POST /api/feedback           -> enregistre un vote (pouce leve/baisse)
 */

:- http_handler(root(.), http_reply_from_files('public', []), [prefix]).
:- http_handler('/api/movies', handle_movies, []).
:- http_handler('/api/genres', handle_genres, []).
:- http_handler('/api/moods', handle_moods, []).
:- http_handler('/api/recommend', handle_recommend, [methods([post])]).
:- http_handler('/api/group/recommend', handle_group_recommend, [methods([post])]).
:- http_handler('/api/dialogue/start', handle_dialogue_start, [methods([post])]).
:- http_handler('/api/dialogue/answer', handle_dialogue_answer, [methods([post])]).
:- http_handler('/api/dialogue/reset', handle_dialogue_reset, [methods([post])]).
:- http_handler('/api/feedback', handle_feedback, [methods([post])]).

start_server :-
    start_server(8080).

start_server(Port) :-
    http_server(http_dispatch, [port(Port)]),
    format("~n== Systeme de recommandation de films (Prolog) ==~n", []),
    format("Interface disponible sur http://localhost:~w~n~n", [Port]).

% --------------------------------------------------------------------------
% Catalogue
% --------------------------------------------------------------------------

handle_movies(_Request) :-
    findall(_{id: Id, title: Title, year: Year, runtime: Runtime, rating: Rating,
              genres: Genres, director: Director, moods: Moods, description: Description},
        (   movie(Id, Title, Year, Runtime, Rating),
            findall(G, movie_genre(Id, G), Genres),
            findall(Mo, movie_mood(Id, Mo), Moods),
            ( movie_director(Id, Director) -> true ; Director = null ),
            ( movie_description(Id, Description) -> true ; Description = "" )
        ),
        Movies0),
    predsort(compare_title, Movies0, Movies),
    reply_json_dict(_{movies: Movies}).

compare_title(Order, D1, D2) :-
    get_dict(title, D1, T1),
    get_dict(title, D2, T2),
    compare(Order, T1, T2).

handle_genres(_Request) :-
    all_genres(Genres),
    reply_json_dict(_{genres: Genres}).

handle_moods(_Request) :-
    all_moods(Moods),
    reply_json_dict(_{moods: Moods}).

% --------------------------------------------------------------------------
% Recommandation individuelle (+ apprentissage par feedback)
% --------------------------------------------------------------------------

handle_recommend(Request) :-
    http_read_json_dict(Request, Body, [default_tag(json)]),
    profile_from_body(Body, Profile),
    ( get_dict(top_n, Body, TopNRaw) -> TopN is round(TopNRaw) ; TopN = 6 ),
    recommend(Profile, TopN, Results, Excluded),
    length(Excluded, ExcludedCount),
    get_dict(learned_genres, Profile, LearnedGenres),
    get_dict(learned_moods, Profile, LearnedMoods),
    reply_json_dict(_{
        results: Results,
        excluded_count: ExcludedCount,
        learned: _{genres: LearnedGenres, moods: LearnedMoods}
    }).

%!  profile_from_body(+Body, -Profile) is det.
%
%   Construit le profil envoye au moteur a partir du JSON recu, en y
%   fusionnant les genres/ambiances "appris" du feedback de la session
%   (si un session_id est fourni) : les votes positifs boostent, les
%   votes tres negatifs viennent grossir la liste des genres a eviter
%   (sauf si l'utilisateur a lui-meme coche ce genre comme aime).
profile_from_body(Body, Profile) :-
    get_list(Body, genres, Genres),
    get_list(Body, moods, Moods),
    get_list(Body, liked_movies, LikedMovies),
    get_list(Body, avoid_genres, AvoidGenres0),
    ( get_dict(min_rating, Body, MinRatingRaw) -> MinRating is MinRatingRaw ; MinRating = 0 ),
    ( get_dict(session_id, Body, SessionIdRaw), SessionIdRaw \== ""
    -> normalize_atom(SessionIdRaw, SessionId),
       feedback:learned_boosts(SessionId, LearnedGenres, LearnedMoods),
       feedback:learned_avoid(SessionId, LearnedAvoid0)
    ;  LearnedGenres = [], LearnedMoods = [], LearnedAvoid0 = []
    ),
    subtract(LearnedAvoid0, Genres, LearnedAvoid),
    union(AvoidGenres0, LearnedAvoid, AvoidGenres),
    Profile = profile{
        genres: Genres, moods: Moods, liked_movies: LikedMovies,
        avoid_genres: AvoidGenres, min_rating: MinRating,
        learned_genres: LearnedGenres, learned_moods: LearnedMoods
    }.

% --------------------------------------------------------------------------
% Recommandation de groupe
% --------------------------------------------------------------------------

handle_group_recommend(Request) :-
    http_read_json_dict(Request, Body, [default_tag(json)]),
    get_dict(profiles, Body, ProfilesRaw),
    maplist(group_profile_from_dict, ProfilesRaw, Profiles),
    ( get_dict(top_n, Body, TopNRaw) -> TopN is round(TopNRaw) ; TopN = 6 ),
    recommend_group(Profiles, TopN, Results, Excluded),
    length(Excluded, ExcludedCount),
    reply_json_dict(_{results: Results, excluded_count: ExcludedCount}).

group_profile_from_dict(Raw, profile{
    name: Name, genres: Genres, moods: Moods, liked_movies: LikedMovies,
    avoid_genres: AvoidGenres, min_rating: 0, learned_genres: [], learned_moods: []
}) :-
    ( get_dict(name, Raw, NameRaw), NameRaw \== "" -> Name = NameRaw ; Name = "Invite" ),
    get_list(Raw, genres, Genres),
    get_list(Raw, moods, Moods),
    get_list(Raw, liked_movies, LikedMovies),
    get_list(Raw, avoid_genres, AvoidGenres).

% --------------------------------------------------------------------------
% Systeme expert conversationnel
% --------------------------------------------------------------------------

handle_dialogue_start(Request) :-
    http_read_json_dict(Request, Body, [default_tag(json)]),
    get_dict(session_id, Body, SessionIdRaw),
    normalize_atom(SessionIdRaw, SessionId),
    dialogue:start_dialogue(SessionId, Reply),
    reply_json_dict(Reply).

handle_dialogue_answer(Request) :-
    http_read_json_dict(Request, Body, [default_tag(json)]),
    get_dict(session_id, Body, SessionIdRaw),
    get_dict(question_id, Body, QuestionIdRaw),
    get_dict(value, Body, ValueRaw),
    normalize_atom(SessionIdRaw, SessionId),
    QuestionId is round(QuestionIdRaw),
    normalize_atom(ValueRaw, Value),
    dialogue:answer_dialogue(SessionId, QuestionId, Value, Reply),
    reply_json_dict(Reply).

handle_dialogue_reset(Request) :-
    http_read_json_dict(Request, Body, [default_tag(json)]),
    get_dict(session_id, Body, SessionIdRaw),
    normalize_atom(SessionIdRaw, SessionId),
    dialogue:reset_dialogue(SessionId),
    reply_json_dict(_{ok: true}).

% --------------------------------------------------------------------------
% Feedback / apprentissage
% --------------------------------------------------------------------------

handle_feedback(Request) :-
    http_read_json_dict(Request, Body, [default_tag(json)]),
    get_dict(session_id, Body, SessionIdRaw),
    get_dict(movie_id, Body, MovieIdRaw),
    get_dict(vote, Body, VoteRaw),
    normalize_atom(SessionIdRaw, SessionId),
    normalize_atom(MovieIdRaw, MovieId),
    Vote is round(VoteRaw),
    feedback:record_feedback(SessionId, MovieId, Vote),
    feedback:learned_boosts(SessionId, LearnedGenres, LearnedMoods),
    reply_json_dict(_{ok: true, learned: _{genres: LearnedGenres, moods: LearnedMoods}}).

% --------------------------------------------------------------------------
% Utilitaires
% --------------------------------------------------------------------------

get_list(Dict, Key, Normalized) :-
    ( is_dict(Dict), get_dict(Key, Dict, Raw), is_list(Raw)
    -> maplist(normalize_atom, Raw, Normalized)
    ;  Normalized = []
    ).

normalize_atom(Item, Atom) :-
    ( atom(Item) -> Atom = Item
    ; string(Item) -> atom_string(Atom, Item)
    ; number(Item) -> atom_number(Atom, Item)
    ; Atom = Item
    ).
