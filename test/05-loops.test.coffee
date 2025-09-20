# Test loop operations

test "for..in loop", ->
  sum = 0
  for x in [1, 2, 3]
    sum += x
  eq sum, 6

test "for..of loop", ->
  values = []
  for x from [10, 20, 30]
    values.push x
  eq values.length, 3
  eq values[0], 10

test "for..in with index", ->
  indices = []
  for val, idx in ['a', 'b', 'c']
    indices.push idx
  eq indices[0], 0
  eq indices[2], 2

test "while loop", ->
  count = 0
  sum = 0
  while count < 3
    sum += count
    count++
  eq sum, 3

test "until loop", ->
  count = 0
  until count is 3
    count++
  eq count, 3

test "loop with break", ->
  count = 0
  loop
    count++
    break if count is 5
  eq count, 5

test "for..in with when", ->
  evens = []
  for x in [1, 2, 3, 4, 5] when x % 2 is 0
    evens.push x
  eq evens.length, 2
  eq evens[0], 2

test "for..in over range", ->
  sum = 0
  for i in [1..3]
    sum += i
  eq sum, 6

test "for..in over object", ->
  obj = {a: 1, b: 2}
  keys = []
  for key of obj
    keys.push key
  ok 'a' in keys
  ok 'b' in keys

test "nested loops", ->
  result = []
  for i in [1, 2]
    for j in [3, 4]
      result.push i * j
  eq result.length, 4
  eq result[0], 3
  eq result[3], 8
