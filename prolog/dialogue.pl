:- module(dialogue, [
    start_dialogue/2,   % +SessionId, -ReplyDict
    answer_dialogue/4,  % +SessionId, +QuestionId, +Value, -ReplyDict
    reset_dialogue/1
]).

:- use_module(movies).
:- use_module(recommend).

/** <module> Petit systeme expert conversationnel
 *
 *  Plutot que de remplir un formulaire, l'utilisateur repond a une
 *  suite de questions. Apres chaque reponse, on recalcule le nombre de
 *  films qui correspondent encore au profil partiel (recommend_candidates/3).
 *  Si peu de films restent (ou que les questions sont epuisees), le
 *  dialogue s'arrete et affiche les resultats : c'est une regle d'arret
 *  dynamique, pas un simple compteur fixe de questions.
 */

:- dynamic dialogue_state/3.  % dialogue_state(SessionId, Profile, Step)

% dq(Step, Type, Texte, Options)
dq(1, genre, "Quel genre vous tente aujourd'hui ?",
   [action, drama, comedy, thriller, sci_fi, horror, romance, animation, fantasy]).
dq(2, mood, "Quelle ambiance recherchez-vous ?",
   [feelgood, intense, dark, funny, thought_provoking, epic, relaxing, scary, emotional]).
dq(3, avoid_genre, "Un genre a eviter absolument ce soir ?",
   [horror, action, romance, comedy, drama, thriller, sci_fi]).
dq(4, quality, "Vous voulez une valeur sure tres bien notee, ou peu importe ?",
   [top_rated, any]).
dq(5, liked_movie, "Un film que vous avez adore recemment ? (cherchez dans le catalogue)",
   movie_search).

total_questions(5).
early_stop_threshold(4).   % s'arrete des qu'il ne reste plus que N candidats

start_dialogue(SessionId, ReplyDict) :-
    reset_dialogue(SessionId),
    empty_profile(Profile),
    with_mutex(dialogue_mutex, assertz(dialogue_state(SessionId, Profile, 1))),
    build_step_reply(Profile, 1, ReplyDict).

reset_dialogue(SessionId) :-
    with_mutex(dialogue_mutex, retractall(dialogue_state(SessionId, _, _))).

empty_profile(profile{
    genres: [], moods: [], liked_movies: [], avoid_genres: [],
    min_rating: 0, learned_genres: [], learned_moods: []
}).

answer_dialogue(SessionId, QuestionId, Value, ReplyDict) :-
    with_mutex(dialogue_mutex, get_or_init_state(SessionId, Profile0, _Step0)),
    apply_answer(QuestionId, Value, Profile0, Profile1),
    Step1 is QuestionId + 1,
    with_mutex(dialogue_mutex,
        (   retractall(dialogue_state(SessionId, _, _)),
            assertz(dialogue_state(SessionId, Profile1, Step1))
        )),
    build_step_reply(Profile1, Step1, ReplyDict).

get_or_init_state(SessionId, Profile, Step) :-
    (   dialogue_state(SessionId, P, S)
    ->  Profile = P, Step = S
    ;   empty_profile(Profile), Step = 1,
        assertz(dialogue_state(SessionId, Profile, Step))
    ).

apply_answer(_, skip, Profile, Profile) :- !.
apply_answer(QuestionId, Value, Profile0, Profile) :-
    dq(QuestionId, Type, _, _),
    !,
    apply_typed_answer(Type, Value, Profile0, Profile).
apply_answer(_, _, Profile, Profile).

apply_typed_answer(genre, Value, P0, P) :- add_unique(genres, Value, P0, P).
apply_typed_answer(mood, Value, P0, P) :- add_unique(moods, Value, P0, P).
apply_typed_answer(avoid_genre, Value, P0, P) :- add_unique(avoid_genres, Value, P0, P).
apply_typed_answer(liked_movie, Value, P0, P) :- add_unique(liked_movies, Value, P0, P).
apply_typed_answer(quality, top_rated, P0, P) :- !, P = P0.put(min_rating, 8.0).
apply_typed_answer(quality, _, P0, P) :- P = P0.

add_unique(Field, Value, P0, P) :-
    ( get_dict(Field, P0, L) -> true ; L = [] ),
    ( memberchk(Value, L) -> P = P0 ; P = P0.put(Field, [Value | L]) ).

build_step_reply(Profile, Step, ReplyDict) :-
    recommend_candidates(Profile, ScoredList, _Excluded),
    length(ScoredList, Count),
    total_questions(Total),
    early_stop_threshold(StopAt),
    (   ( Count =< StopAt ; Step > Total )
    ->  finish_dialogue(Profile, ScoredList, Count, ReplyDict)
    ;   dq(Step, Type, Text, Options)
    ->  ReplyDict = _{
            done: false,
            question: _{id: Step, type: Type, text: Text, options: Options},
            remaining: Count,
            step: Step,
            total: Total
        }
    ;   finish_dialogue(Profile, ScoredList, Count, ReplyDict)
    ).

finish_dialogue(Profile, ScoredList, Count, _{done: true, results: Results, remaining: Count, profile: Profile}) :-
    sort(0, @>=, ScoredList, Sorted),
    first_n(6, Sorted, Top),
    maplist(to_result_dict, Top, Results).
