# Test Assignment

test "basic assignment", ->
  x = 42
  eq x, 42

test "multiple assignment", ->
  a = b = c = 10
  eq a, 10
  eq b, 10
  eq c, 10

test "compound assignment", ->
  x = 10
  x += 5
  eq x, 15
  x -= 3
  eq x, 12
  x *= 2
  eq x, 24
  x /= 4
  eq x, 6

test "destructuring assignment from arrays", ->
  [a, b, c] = [1, 2, 3]
  eq a, 1
  eq b, 2
  eq c, 3

test "destructuring with rest", ->
  arr = [1, 2, 3, 4]
  first = arr[0]
  rest = arr[1..]
  eq first, 1
  ok rest[0] == 2
  ok rest[1] == 3
  ok rest[2] == 4

test "destructuring with defaults", ->
  [a = 10, b = 20] = [1]
  eq a, 1
  eq b, 20

test "nested destructuring", ->
  [a, [b, c]] = [1, [2, 3]]
  eq a, 1
  eq b, 2
  eq c, 3

test "object destructuring", ->
  {x, y} = {x: 1, y: 2, z: 3}
  eq x, 1
  eq y, 2

test "object destructuring with renaming", ->
  {x: a, y: b} = {x: 1, y: 2}
  eq a, 1
  eq b, 2

test "object destructuring with defaults", ->
  {x = 10, y = 20} = {x: 1}
  eq x, 1
  eq y, 20

test "swap variables", ->
  a = 1
  b = 2
  [a, b] = [b, a]
  eq a, 2
  eq b, 1

test "conditional assignment", ->
  x = null
  x ?= 42
  eq x, 42

  y = 10
  y ?= 100
  eq y, 10

test "assignment in expressions", ->
  x = 0
  y = (x = 42) + 8
  eq x, 42
  eq y, 50

test "assignment with existence operator", ->
  obj = {}
  obj.prop ?= 42
  eq obj.prop, 42

  obj.prop ?= 100
  eq obj.prop, 42

test "string interpolation assignment", ->
  name = 'world'
  greeting = "Hello, #{name}!"
  eq greeting, 'Hello, world!'

test "regex assignment", ->
  pattern = /test/i
  ok pattern.test('TEST')

test "range assignment", ->
  range = [1..5]
  ok range[0] == 1
  ok range[4] == 5
  ok range.length == 5

test "slice assignment", ->
  arr = [1, 2, 3, 4, 5]
  arr[1..3] = [7, 8, 9]
  ok arr[0] == 1
  ok arr[1] == 7
  ok arr[3] == 9
  ok arr[4] == 5

test "property assignment", ->
  obj = {}
  obj.prop = 42
  obj['key'] = 'value'
  eq obj.prop, 42
  eq obj.key, 'value'

test "prototype assignment", ->
  class Test
  Test::method = -> 42
  t = new Test()
  eq t.method(), 42

test "assignment with splats", ->
  fn = (a, b, c) -> [a, b, c]
  result = fn(1, 2, 3)
  ok result[0] == 1
  ok result[1] == 2
  ok result[2] == 3

test "complex destructuring patterns", ->
  {a: {b: {c}}} = {a: {b: {c: 42}}}
  eq c, 42

test "assignment in loops", ->
  sum = 0
  for val, i in [10, 20, 30]
    sum += val + i
  eq sum, 63

test "assignment with binary operators", ->
  x = 5
  x &= 3
  eq x, 1

  y = 5
  y |= 3
  eq y, 7

test "assignment with logical operators", ->
  x = null
  x ||= 42
  eq x, 42

  y = true
  y &&= false
  eq y, false
