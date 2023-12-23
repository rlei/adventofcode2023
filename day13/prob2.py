import fileinput, itertools

def find_reflect_line(patterns: list[str], old: (int | None)) -> (int | None):
  for row in range(1, len(patterns)):
    part1 = list(reversed(patterns[:row]))
    part2 = patterns[row:]
    min_lines = min(row, len(patterns) - row)
    if part1[:min_lines] == part2[:min_lines] and row != old:
      return row
  return None

def find_reflect_line_smudge(patterns: list[str]) -> (int | None):
  old_reflect_line = find_reflect_line(patterns, None)

  rows = len(patterns)
  cols = len(patterns[0])
  for row in range(0, rows):
    for col in range(0, cols):
      pattern = patterns[row]
      saved = pattern[col]
      smudge = '#' if saved == '.' else '.'

      patterns[row] = pattern[:col] + smudge + pattern[col+1:]
      try_find = find_reflect_line(patterns, old_reflect_line)
      patterns[row] = pattern[:col] + saved + pattern[col+1:]

      if try_find is not None and try_find != old_reflect_line:
        return try_find
  return None

if __name__ == "__main__":
  lines = [line.strip() for line in fileinput.input()]
  it = iter(lines)
  maps = [[_] + list(itertools.takewhile(lambda l: l != '', it)) for _ in it]
  sum = 0
  for aMap in maps:
    reflect_row = find_reflect_line_smudge(aMap)
    if not reflect_row:
      transposed = ["".join([pattern[i] for pattern in aMap]) for i in range(0, len(aMap[0]))]
      reflect_col = find_reflect_line_smudge(transposed)
      sum += reflect_col
    else:
      sum += 100 * reflect_row

  print(sum) 
