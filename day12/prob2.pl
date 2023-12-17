match_first_springs([], 0, _ , 0).
match_first_springs([InH|_], 0, _ , 0) :-
  % complete the recursion if we've seen the right number of '#'s, AND the next
  % one is NOT '#'. Otherwise terminate.
  % writeln(["matched count, next ", InH]),
  InH \= '#'.
  % writeln("matched!!").
match_first_springs([InH|InTail], ConsumedLen, ExpectedSprings, SpringsToGo) :-
  SpringsToGo > 0,
  % writeln(["remaining ", InTail, "  springs to go ", SpringsToGo]),
  % if InH is '?', generate a sequence of '#' and '.' (with backtracking)
  % otherwise just copy to the output
  (InH = '?' -> (OutH = '#'; OutH = '.'); OutH = InH),
  (OutH = '#' ->
    % writeln(["found a '#', remaining ", InTail]),
    % recur
    NewCount is SpringsToGo - 1,
    match_first_springs(InTail, TailLen, ExpectedSprings, NewCount);
    % --- else ---
    % assert that we must haven't seen any spring '#' so far, otherwise terminate
    % writeln(["not a '#', current springs to go ", SpringsToGo]),
    ExpectedSprings = SpringsToGo,
    % recur
    match_first_springs(InTail, TailLen, ExpectedSprings, SpringsToGo)
  ),
  ConsumedLen is TailLen + 1.

match_first_springs_str(Pattern, Count, ConsumedLen) :-
  string_chars(Pattern, InputList),
  match_first_springs(InputList, ConsumedLen, Count, Count).

match_pattern_to_counts(Pattern, []) :-
  % writeln(["empty Counts pattern", Pattern]),
  % check there's no '#'
  string_chars(Pattern, Chars),
  \+ member('#', Chars).
match_pattern_to_counts(Pattern, [FirstCount|RestCounts]) :-
  match_first_springs_str(Pattern, FirstCount, MatchedLen),
  sub_string(Pattern, MatchedLen, _, 0, RestPattern),
  % string_length(RestPattern, RestLen),
  % sumlist(RestCounts, RestCountLen),
  % RestLen >= RestCountLen,
  % writeln(["first and rest ", MatchedPart, " + ", RestPattern]),
  % if the next is '?', it must only be expanded to '.', so just skip it
  (sub_string(RestPattern, 0, 1, _, "?")
   -> sub_string(RestPattern, 1, _, 0, NewRest); NewRest = RestPattern),
  % writeln(["NewRest => ", NewRest]),
  % writeln(["Counts and rest  => ", FirstCount, RestCounts]),
  match_pattern_to_counts(NewRest, RestCounts).

replace_first_char(In, Ch, Out) :-
  string_chars(In, [_|Rest]),
  string_chars(Out, [Ch|Rest]).

count_matches(Pattern, ExpectedCounts, Matches) :-
  aggregate(count,
         (match_pattern_to_counts(Pattern, ExpectedCounts)),
         Matches),
  writeln(Matches).

read_lines(Stream, []) :- at_end_of_stream(Stream).
read_lines(Stream, [X|L]) :-
    \+ at_end_of_stream(Stream),
    read_line_to_string(Stream, X),
    read_lines(Stream, L).

parse_line(Line, Pattern, Counts) :-
  split_string(Line, " ", " ", [Pattern|[CountsStr]]),
  split_string(CountsStr, ",", ",", CountStrs),
  maplist(atom_number, CountStrs, Counts).

count_matches_from_line_5x(Line, Matches) :-
  parse_line(Line, Pattern, Counts),
  repeat_and_join_string(Pattern, 5, '?', Pattern5x),
  repeat_list(Counts, 5, Counts5x),
  writeln(["Counting => ", Line]),
  count_matches(Pattern5x, Counts5x, Matches),
  writeln(["Counting <= ", Line, " ", Matches]).

repeat_and_join_string(Str, Times, Sep, Result) :- 
    findall(Str, between(1, Times, _), Strs),
    atomics_to_string(Strs, Sep, Result).

repeat_list(List, Times, Result) :-
    findall(List, between(1, Times, _), Lists),
    flatten(Lists, Result).

prob2 :-
  read_lines(user_input, Lines),
  concurrent_maplist(count_matches_from_line_5x, Lines, AllMatches),
  sumlist(AllMatches, Sum),
  write("Sum of counts: "),
  writeln(Sum).

