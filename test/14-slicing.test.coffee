# Test array and string slicing operations

test "array slicing", ->
  arr = [1, 2, 3, 4, 5]
  slice = arr[1..3]
  eq slice.length, 3
  eq slice[0], 2
  eq slice[2], 4

test "array slicing exclusive", ->
  arr = [1, 2, 3, 4, 5]
  slice = arr[1...4]
  eq slice.length, 3
  eq slice[0], 2
  eq slice[2], 4

test "array slicing from start", ->
  arr = [1, 2, 3, 4, 5]
  slice = arr[..2]
  eq slice.length, 3
  eq slice[0], 1
  eq slice[2], 3

test "array slicing to end", ->
  arr = [1, 2, 3, 4, 5]
  slice = arr[2..]
  eq slice.length, 3
  eq slice[0], 3
  eq slice[2], 5

test "array slicing with negative indices", ->
  arr = [1, 2, 3, 4, 5]
  slice = arr[-2..]
  eq slice.length, 2
  eq slice[0], 4
  eq slice[1], 5

test "string slicing", ->
  str = "hello world"
  slice = str[0..4]
  eq slice, "hello"

test "string slicing exclusive", ->
  str = "hello world"
  slice = str[6...11]
  eq slice, "world"

test "array splicing with assignment", ->
  arr = [1, 2, 3, 4, 5]
  arr[1..3] = [7, 8, 9]
  eq arr.length, 5
  eq arr[1], 7
  eq arr[3], 9

test "array splicing insertion", ->
  arr = [1, 2, 5]
  arr[2...2] = [3, 4]
  eq arr.length, 5
  eq arr[2], 3
  eq arr[3], 4
  eq arr[4], 5

test "array splicing deletion", ->
  arr = [1, 2, 3, 4, 5]
  arr[1..3] = []
  eq arr.length, 2
  eq arr[0], 1
  eq arr[1], 5
