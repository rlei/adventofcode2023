import fileinput, itertools

def find_reflect_line(patterns: list[str]) -> (int | None):
  for row in range(1, len(patterns)):
    part1 = list(reversed(patterns[:row]))
    part2 = patterns[row:]
    min_lines = min(row, len(patterns) - row)
    if part1[:min_lines] == part2[:min_lines]:
      return row
  return None

if __name__ == "__main__":
  lines = [line.strip() for line in fileinput.input()]
  it = iter(lines)
  maps = [[_] + list(itertools.takewhile(lambda l: l != '', it)) for _ in it]
  sum = 0
  for aMap in maps:
    reflect_row = find_reflect_line(aMap)
    if not reflect_row:
      transposed = ["".join([pattern[i] for pattern in aMap]) for i in range(0, len(aMap[0]))]
      reflect_col = find_reflect_line(transposed)
      sum += reflect_col
    else:
      sum += 100 * reflect_row

  print(sum) 
