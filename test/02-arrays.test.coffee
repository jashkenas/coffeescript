# Test array operations

test "array creation", ->
  arr = [1, 2, 3]
  eq arr.length, 3
  eq arr[0], 1
  eq arr[2], 3

test "array with trailing comma", ->
  arr = [1, 2, 3,]
  eq arr.length, 3

test "nested arrays", ->
  arr = [[1, 2], [3, 4]]
  eq arr[0][1], 2
  eq arr[1][0], 3

test "array destructuring", ->
  [a, b, c] = [1, 2, 3]
  eq a, 1
  eq b, 2
  eq c, 3

test "array destructuring with rest", ->
  [first, rest...] = [1, 2, 3, 4]
  eq first, 1
  eq rest.length, 3
  eq rest[0], 2

test "array splats", ->
  a = [2, 3]
  b = [1, a..., 4]
  eq b.length, 4
  eq b[0], 1
  eq b[1], 2
  eq b[3], 4

test "array comprehension", ->
  squares = (x * x for x in [1, 2, 3])
  eq squares[0], 1
  eq squares[1], 4
  eq squares[2], 9

test "filtered comprehension", ->
  evens = (x for x in [1, 2, 3, 4, 5] when x % 2 is 0)
  eq evens.length, 2
  eq evens[0], 2
  eq evens[1], 4

test "range arrays", ->
  arr = [1..3]
  eq arr.length, 3
  eq arr[0], 1
  eq arr[2], 3

test "exclusive range", ->
  arr = [1...4]
  eq arr.length, 3
  eq arr[2], 3
