let rec sliding_pairs lst =
  match lst with
  | x :: y :: rest -> (x, y) :: sliding_pairs (y :: rest)
  | _ -> []

let seq_of_differences lst =
  sliding_pairs lst
  |> List.map (fun (a, b) -> b - a)

let last_element lst =
  List.hd (List.rev lst)

let rec extrapolate_next lst =
  let differences = seq_of_differences lst in
  if List.for_all (fun n -> n == 0) differences then
    last_element lst
  else
    last_element lst + extrapolate_next differences

let rec extrapolate_prev lst =
  let differences = seq_of_differences lst in
  if List.for_all (fun n -> n == 0) differences then
    List.hd lst
  else
    List.hd lst - extrapolate_prev differences

let parse_integers line =
  let integer_list = String.split_on_char ' ' line in
  List.map int_of_string integer_list

let rec read_lines acc =
  try
    let line = input_line stdin in
    read_lines (line :: acc)
  with
  | End_of_file -> List.rev acc

let all_lines =
  read_lines []
  |> List.map parse_integers

let () = 
  List.map extrapolate_next all_lines
  |> List.fold_left (+) 0
  |> string_of_int
  |> print_endline

let () = 
  List.map extrapolate_prev all_lines
  |> List.fold_left (+) 0
  |> string_of_int
  |> print_endline 