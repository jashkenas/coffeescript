multi_liner:
  for x in [3..5]
    for y in [3..5]
      [x, y]

single_liner:
  [x, y] for y in [3..5] for x in [3..5]

ok multi_liner.length is single_liner.length
ok 5 is multi_liner[2][2][1]
ok 5 is single_liner[2][2][1]


# Test comprehensions within parentheses.
result: null
store: (obj) -> result: obj
store (x * 2 for x in [3, 2, 1])

ok result.join(' ') is '6 4 2'

