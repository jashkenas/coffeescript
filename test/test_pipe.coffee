map: (list, fn) -> fn item for item in list
first: (list, fn) -> (return item) for item in list when fn item

add: (x, y) -> x + y
times: (x, y) -> x * y

y: 1 | add(8) | times(8)
z: [1, 2, 3, 4] | map((x) -> x * x) | first (x) -> x > 10

ok y is 8 * (8 + 1)
ok z is 16

grep: (list, regex) ->
  matches: item for item in list when item.match regex
  if matches.length then matches else null

results: ['Hello', 'World!', 'How do you do?'] | grep /^H/
deepEqual results, ['Hello', 'How do you do?']

reversed: [1, 2, 3, 4] | Array::reverse.call()
deepEqual reversed, [4, 3, 2, 1]

results: ['a', 'b', 'c', 'd'] | grep(/\d/) | or 'GREP empty.'
ok results is 'GREP empty.'

y: 1 | add(8) | times(0) | or 2 | times 2
ok y is 4

z: [1, 2, 3, 4] |
    map((x) -> x * x) |
    Array::reverse.call() |
    or [1, 2, 3, 4] |
    first (x) -> x > 10
ok z is 16
