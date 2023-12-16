count_springs(Line, Lengths) :-
  writeln([Line, Groups, Lengths]),
  split_string(Line, ".", ".", Groups),
  maplist(string_length, Groups, Lengths),
  writeln([Line, Groups, Lengths]).

generate_springs([], []).
generate_springs([InH|InTail], [OutH|OutTail]) :-
  % if InH is '?', generate a sequence of '#' and '.' (with backtracking)
  % otherwise just copy to the output
  (InH = '?' -> member(OutH, ['#', '.']); OutH = InH),
  generate_springs(InTail, OutTail).

generate_springs_str(Pattern, OutStr) :-
  string_chars(Pattern, InputList),
  generate_springs(InputList, OutList),
  % note this is from OutList to OutStr now
  string_chars(OutStr, OutList).

count_matches(Pattern, ExpectedCounts, Matches) :-
  findall(Candidate,
         (generate_springs_str(Pattern, Candidate), count_springs(Candidate, ExpectedCounts)),
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

count_matches_from_line(Line, Matches) :-
  parse_line(Line, Pattern, Counts),
  count_matches(Pattern, Counts, Matches).

prob1 :-
  read_lines(user_input, Lines),
  maplist(count_matches_from_line, Lines, AllMatches),
  sumlist(AllMatches, Sum),
  write("Sum of counts: "),
  writeln(Sum).
