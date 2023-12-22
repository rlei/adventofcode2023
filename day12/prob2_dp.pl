% table count_matches/3.

match_first_springs([], 0, _ , 0).
match_first_springs([InH|_], ConsumedLen, _ , 0) :-
  % complete the recursion if we've seen the right number of '#'s, AND the next
  % one is NOT '#'. Otherwise terminate.
  % InH \= '#',
  % if the next is '?', it must only be expanded to '.', so just skip it
  % writeln("foo"),
  (InH = '?' ->
   ConsumedLen is 1;
   InH \= '#', ConsumedLen is 0),
   !. % cut here to avoid running the choice point below
match_first_springs([InH|InTail], ConsumedLen, ExpectedSprings, SpringsToGo) :-
  % writeln("abc"),
  SpringsToGo > 0,
  % if InH is '?', generate a sequence of '#' and '.' (with backtracking)
  % otherwise just copy to the output
  (InH = '?' -> (OutH = '#'; OutH = '.'); OutH = InH),
  (OutH = '#' ->
    % recur
    NewCount is SpringsToGo - 1,
    match_first_springs(InTail, TailLen, ExpectedSprings, NewCount);
    % --- else ---
    % assert that we must haven't seen any spring '#' so far, otherwise terminate
    ExpectedSprings = SpringsToGo,
    % recur
    match_first_springs(InTail, TailLen, ExpectedSprings, SpringsToGo)
  ),
  ConsumedLen is TailLen + 1.

match_first_springs_str(Pattern, Count, ConsumedLen) :-
  string_chars(Pattern, InputList),
  match_first_springs(InputList, ConsumedLen, Count, Count).

match_pattern_to_counts(Pattern, [], _) :-
  % check there's no '#'
  string_chars(Pattern, Chars),
  \+ member('#', Chars).
match_pattern_to_counts(Pattern, [FirstCount|RestCounts], MinPatternLen) :-
  string_length(Pattern, PatternSize),
  PatternSize >= MinPatternLen,

  match_first_springs_str(Pattern, FirstCount, MatchedLen),
  % writeln(["first and rest ", MatchedPart, " + ", RestPattern]),
  sub_string(Pattern, MatchedLen, _, 0, RestPattern),
  MinPatternLen1 is MinPatternLen - FirstCount - 1,
  % writeln(["Counts and rest  => ", FirstCount, RestCounts]),
  match_pattern_to_counts(RestPattern, RestCounts, MinPatternLen1).

count_matches(Pattern, ExpectedCounts, Matches) :-
  sumlist(ExpectedCounts, CountsSum),
  length(ExpectedCounts, NumCounts),
  MinPatternLen is CountsSum + NumCounts - 1,
  aggregate(count,
         (match_pattern_to_counts(Pattern, ExpectedCounts, MinPatternLen)),
         Matches).

count_matches_dp([], [], 1).
count_matches_dp([Pattern|Rest], [], Matches) :-
  string_chars(Pattern, Chars),
  % if this Pattern has no '#', check the rest; otherwise no matches because there's
  % alread no more count to be matched
  (\+ member('#', Chars) -> count_matches_dp(Rest, [], MatchesRec),
      Matches is MatchesRec;
      Matches is 0),
  !. % cut here to avoid running the choice point below
count_matches_dp([Pattern|RestPatterns], ExpectedCounts, Matches) :-
  (length(RestPatterns, RestLen), RestLen = 0 ->
    count_matches(Pattern, ExpectedCounts, Matches);
    % -- else ---
    split_counts_to_pattern_size(Pattern, ExpectedCounts, CountGroup1, CountGroup2),
    maplist(string_length, RestPatterns, RestPatternsLengths),
    sumlist(RestPatternsLengths, RestPatternsTotalLength),
    sumlist(CountGroup2, RestCountsSum),
    % relaxed length check
    RestPatternsTotalLength >= RestCountsSum,

    % writeln(["Pattern ", Pattern, " Rest ", RestPatterns, " To match ", CountGroup1]),
    count_matches(Pattern, CountGroup1, Group1Matches),
    % writeln(["group 1 matches ", Group1Matches]),
    aggregate(sum(EachMatch), (count_matches_dp(RestPatterns, CountGroup2, EachMatch)), Group2Matches),
    % count_matches_dp(RestPatterns, CountGroup2, Group2Matches),
    % writeln(["Pattern ", Pattern, " Rest ", RestPatterns, " To match ", CountGroup1]),
    % writeln(["group 1 matches ", Group1Matches]),
    % writeln(["Pattern ", Pattern, "; group 1 ", CountGroup1, "; matches ", Group1Matches]),
    % writeln(["Rest Patterns ", RestPatterns, "; group 2 ", CountGroup2, "; matches ", Group2Matches]),
    Matches is Group1Matches * Group2Matches
  ).
  % writeln(["Matches ", Matches]).

split_counts_to_pattern_size(Pattern, CountList, FirstPart, SecondPart) :-
  string_length(Pattern, PatternSize),
  append(FirstPart, SecondPart, CountList),
  sumlist(FirstPart, CountsSum),
  length(FirstPart, NumCounts),
  MinPatternLen is CountsSum + NumCounts - 1,
  % NumCounts > 0,
  PatternSize >= MinPatternLen.
  % writeln([FirstPart, SecondPart, CountList]),
  % writeln(["PatternSize ", PatternSize, "MinPatternLen", MinPatternLen]).

read_lines(Stream, []) :- at_end_of_stream(Stream).
read_lines(Stream, [X|L]) :-
    \+ at_end_of_stream(Stream),
    read_line_to_string(Stream, X),
    read_lines(Stream, L).

parse_line(Line, Pattern, Counts) :-
  split_string(Line, " ", " ", [Pattern|[CountsStr]]),
  split_string(CountsStr, ",", ",", CountStrs),
  maplist(atom_number, CountStrs, Counts).

concat_pattern(Pattern, 1, Out) :-
  Out = Pattern.
concat_pattern(Pattern, N, Out) :-
  N > 1,
  % backtracking
  member(Sep, ['#', '.']),
  N1 is N - 1,
  concat_pattern(Pattern, N1, Next),
  atomics_to_string([Pattern, Next], Sep, Out).

count_matches_5x(Pattern, Counts5x, Matches) :-
  concat_pattern(Pattern, 5, Pattern5x),
  split_string(Pattern5x, ".", ".", Pattern5xList),
  % writeln(["Running => ", Pattern5x, "  ", Counts5x]),
  aggregate(sum(EachMatch), (count_matches_dp(Pattern5xList, Counts5x, EachMatch)), Matches).
  % writeln([Pattern5x, "  ", Counts5x, "  ", Matches]).

factorial(0, 1).
factorial(N, Fact) :-
    N > 0,
    N1 is N - 1,
    factorial(N1, Fact1),
    Fact is N * Fact1.

factorial_NM(0, _, 1).
factorial_NM(1, M, M).
factorial_NM(N, M, Fact) :-
  N > 1,
  M1 is M - 1,
  N1 is N - 1,
  factorial_NM(N1, M1, Fact1),
  Fact is M * Fact1.

combinations(M, N, C) :-
    factorial_NM(N, M, FactNM),
    factorial(N, FactN),
    C is FactNM // FactN.

combinations_5x(Pattern, Counts, Matches) :-
  string_length(Pattern, BaseLen),
  Pattern_5xLen is BaseLen * 5 + 4,
  repeat_list(Counts, 5, Counts5x),
  sumlist(Counts5x, TotalCounts),
  length(Counts5x, NumCounts),
  writeln([TotalCounts, NumCounts]),
  N is Pattern_5xLen - TotalCounts - (NumCounts - 1),
  M is NumCounts + N,
  writeln([M, N]),
  combinations(M, N, Matches).

count_matches_from_line_5x(Line, Matches) :-
  writeln(["Counting 5x => ", Line]),
  parse_line(Line, Pattern, Counts),
  (
    string_chars(Pattern, Chars),
    \+ member('#', Chars),
    \+ member('.', Chars) ->
    combinations_5x(Pattern, Counts, Matches);
    % --- else ---
    string_chars(Pattern, Chars),
    repeat_list(Counts, 5, Counts5x),
    ( % no separator?
      \+ member('.', Chars) -> 
      aggregate(sum(EachMatch), (count_matches_5x(Pattern, Counts5x, EachMatch)), Matches);
      % -- else ---
      repeat_and_join_string(Pattern, 5, '?', Pattern5x),
      split_string(Pattern5x, ".", ".", Pattern5xList),
      aggregate(sum(EachMatch), (count_matches_dp(Pattern5xList, Counts5x, EachMatch)), Matches)
    )
  ),
  writeln(["Counting <= ", Line, " ", Matches]).

count_matches_from_line_N(Line, N, Matches) :-
  writeln(["Counting Nx => ", N, Line]),
  parse_line(Line, Pattern, Counts),
  repeat_list(Counts, N, CountsNx),
  repeat_and_join_string(Pattern, N, '?', PatternNx),
  split_string(PatternNx, ".", ".", PatternNxList),
  aggregate(sum(EachMatch), (count_matches_dp(PatternNxList, CountsNx, EachMatch)), Matches),
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

