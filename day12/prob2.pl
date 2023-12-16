count_springs(Line, Lengths) :-
  split_string(Line, ".", ".", Groups),
  % compare number of groups first to save the expensive string_length check
  length(Groups, NumGroups),
  length(Lengths, NumGroups),
  maplist(string_length, Groups, Lengths).
  % writeln([Line, Groups, Lengths]).

generate_springs([], []).
generate_springs([InH|InTail], [OutH|OutTail]) :-
  % if InH is '?', generate a sequence of '#' and '.' (with backtracking)
  % otherwise just copy to the output
  (InH = '?' -> member(OutH, ['#', '.']); OutH = InH),
  generate_springs(InTail, OutTail).

match_pattern_to_counts(Pattern, [], Out) :-
  % writeln(["empty Counts pattern", Pattern]),
  % check there's no '#' or '?'
  string_chars(Pattern, Chars),
  maplist(=('.'), Chars),
  Out=Pattern.
match_pattern_to_counts(Pattern, [FirstCount|RestCounts], Out) :-
  % writeln(["non empty Counts", FirstCount, RestCounts, Pattern]),
  first_group_and_rest(Pattern, FirstPart, RestPattern),
  % writeln(["first and rest ", FirstPart, " + ", RestPattern]),
  generate_springs_str(FirstPart, Out1),
  count_springs(Out1, [FirstCount]),
  ((sub_string(Out1, _, 1, 0, "#"), sub_string(RestPattern, 0, 1, _, "?"))
   -> replace_first_char(RestPattern, '.', NewRest); NewRest = RestPattern),
  % writeln("First part passed"),
  % writeln(["Patterns", FirstPart, RestPattern]),
  % writeln(["Counts and rest", FirstCount, RestCounts]),
  % writeln(["Out1", Out1, NewRest]),
  match_pattern_to_counts(NewRest, RestCounts, Out2),
  string_concat(Out1, Out2, Out).

replace_first_char(In, Ch, Out) :-
  string_chars(In, [_|Rest]),
  string_chars(Out, [Ch|Rest]).

first_group_and_rest(Pattern, Part1, Part2) :-
  string_concat(Part1, Part2, Pattern),
  % first group must not be empty
  \+ string_length(Part1, 0),
  % writeln(["split ", Pattern, " => ", Part1, " + ", Part2]),
  % must not split consecutive springs
  \+ (sub_string(Part1, _, 1, 0, "#"), sub_string(Part2, 0, 1, _, "#")),
  no_more_than_one_spring_group(Part1).

contains_spring(Str) :-
  string_chars(Str, Chars),
  member('#', Chars).

no_more_than_one_spring_group(Pattern) :-
  split_string(Pattern, ".", ".", Groups),
  include(contains_spring, Groups, SpringGroups),
  length(SpringGroups, Len),
  Len =< 1.
  
generate_springs_str(Pattern, OutStr) :-
  string_chars(Pattern, InputList),
  generate_springs(InputList, OutList),
  % note this is from OutList to OutStr now
  string_chars(OutStr, OutList).

count_matches(Pattern, ExpectedCounts, Matches) :-
  findall(Candidate,
         (match_pattern_to_counts(Pattern, ExpectedCounts, Candidate)),
         ValidCandidates),
  length(ValidCandidates, Matches),
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
  count_matches(Pattern5x, Counts5x, Matches).

repeat_and_join_string(Str, Times, Sep, Result) :- 
    findall(Str, between(1, Times, _), Strs),
    atomics_to_string(Strs, Sep, Result).

repeat_list(List, Times, Result) :-
    findall(List, between(1, Times, _), Lists),
    flatten(Lists, Result).

prob2 :-
  read_lines(user_input, Lines),
  maplist(count_matches_from_line_5x, Lines, AllMatches),
  sumlist(AllMatches, Sum),
  write("Sum of counts: "),
  writeln(Sum).

