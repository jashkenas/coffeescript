# Test edge cases and special patterns

test "@ as this", ->
  obj =
    value: 42
    getValue: -> @value
    getValueArrow: => @value

  eq obj.getValue(), 42

test "@property shorthand", ->
  class Person
    constructor: (@name, @age) ->

  person = new Person("Alice", 30)
  eq person.name, "Alice"
  eq person.age, 30

test "do expressions", ->
  result = do -> 42
  eq result, 42

  # Note: 'do fn(args)' doesn't work, use 'fn(args)' directly
  add = (a, b) -> a + b
  result = add(5, 3)
  eq result, 8

test "do with function", ->
  counter = 0
  inc = -> counter++

  do inc
  do inc
  eq counter, 2

test "heregex (multiline regex)", ->
  regex = ///
    ^     # start
    \d+   # digits
    $     # end
  ///
  ok regex.test "123"
  ok not regex.test "abc"

test "heregex with flags", ->
  regex = ///
    hello
    \s+
    world
  ///i
  ok regex.test "Hello World"
  ok regex.test "HELLO WORLD"

test "existential assignment", ->
  a = null
  a ?= 42
  eq a, 42

  b = 10
  b ?= 20
  eq b, 10

test "existential access chain", ->
  obj = a: b: c: 42
  eq obj?.a?.b?.c, 42
  eq obj?.x?.y?.z, undefined

test "soaked function calls", ->
  obj =
    method: -> 42

  eq obj.method?(), 42
  eq obj.missing?(), undefined

test "compound assignment operators", ->
  x = 10
  x += 5
  eq x, 15

  x -= 3
  eq x, 12

  x *= 2
  eq x, 24

  x /= 4
  eq x, 6

  x %= 4
  eq x, 2

  x **= 3
  eq x, 8

test "logical assignment operators", ->
  a = true
  a &&= false
  eq a, false

  b = false
  b ||= true
  eq b, true

  c = null
  c ?= 42
  eq c, 42

test "prototype access", ->
  Boolean::custom = -> "custom"
  result = true.custom()
  eq result, "custom"
  delete Boolean::custom

test "arguments object", ->
  fn = ->
    Array::slice.call(arguments)

  args = fn(1, 2, 3)
  eq args.length, 3
  eq args[0], 1

test "special number values", ->
  eq Infinity + 1, Infinity
  eq -Infinity - 1, -Infinity
  ok isNaN(NaN)
  ok isNaN(0/0)
  eq 1/0, Infinity
  eq -1/0, -Infinity

test "unicode in strings", ->
  str = "Hello 世界 🌍"
  ok str.includes "世界"
  ok str.includes "🌍"

test "line continuation", ->
  result = 1 + \
           2 + \
           3
  eq result, 6

test "chained comparisons", ->
  ok 1 < 2 < 3 < 4
  ok 5 > 4 > 3 > 2
  ok 2 <= 2 <= 3
  ok 3 >= 3 >= 2

test "everything is an expression", ->
  result = if true
    x = 10
    x * 2
  eq result, 20

  value = try
    JSON.parse '{"a": 1}'
  catch
    null
  eq value.a, 1

test "implicit returns", ->
  fn = (x) ->
    if x > 0
      "positive"
    else if x < 0
      "negative"
    else
      "zero"

  eq fn(5), "positive"
  eq fn(-3), "negative"
  eq fn(0), "zero"
