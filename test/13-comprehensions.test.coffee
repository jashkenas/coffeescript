# Test comprehensions and advanced iteration

test "basic array comprehension", ->
  doubles = (x * 2 for x in [1, 2, 3])
  eq doubles[0], 2
  eq doubles[1], 4
  eq doubles[2], 6

test "filtered comprehension", ->
  evens = (x for x in [1, 2, 3, 4, 5, 6] when x % 2 is 0)
  eq evens.length, 3
  eq evens[0], 2
  eq evens[2], 6

test "object comprehension", ->
  obj = {a: 1, b: 2, c: 3}
  values = (v for k, v of obj)
  ok 1 in values
  ok 2 in values
  ok 3 in values

test "nested comprehension", ->
  matrix = ([i, j] for i in [1, 2] for j in [3, 4])
  eq matrix.length, 2  # Correct: produces nested structure
  eq matrix[0][0][0], 1
  eq matrix[0][0][1], 3
  eq matrix[1][0][0], 1
  eq matrix[1][0][1], 4

test "comprehension with index", ->
  indexed = ("#{i}:#{v}" for v, i in ['a', 'b', 'c'])
  eq indexed[0], "0:a"
  eq indexed[1], "1:b"
  eq indexed[2], "2:c"

test "comprehension with range", ->
  squares = (x * x for x in [1..5])
  eq squares.length, 5
  eq squares[0], 1
  eq squares[4], 25

test "by clause in comprehension", ->
  everyOther = (x for x in [0..10] by 2)
  eq everyOther.length, 6
  eq everyOther[0], 0
  eq everyOther[5], 10

test "comprehension with guard", ->
  result = (x for x in [1..10] when x > 5)
  eq result.length, 5
  eq result[0], 6
  eq result[4], 10

test "object comprehension with filter", ->
  scores = {alice: 85, bob: 92, charlie: 78, diana: 95}
  highScorers = (name for name, score of scores when score >= 90)
  ok 'bob' in highScorers
  ok 'diana' in highScorers
  ok 'alice' not in highScorers

test "comprehension assignment", ->
  numbers = [1..5]
  doubled = for n in numbers
    n * 2
  eq doubled[0], 2
  eq doubled[4], 10

test "comprehension with continue", ->
  result = for x in [1..5]
    continue if x is 3
    x * 2
  eq result.length, 4  # Correct: continue skips iteration entirely
  eq result[0], 2  # x=1: 1*2 = 2
  eq result[1], 4  # x=2: 2*2 = 4
  eq result[2], 8  # x=4: 4*2 = 8 (x=3 was skipped)
  eq result[3], 10 # x=5: 5*2 = 10

test "comprehension with own", ->
  class Parent
    @prop: "parent"

  class Child extends Parent
    @ownProp: "child"

  props = (v for own k, v of Child)
  ok 'child' in props
  ok 'parent' not in props
