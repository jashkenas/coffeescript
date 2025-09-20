# Test advanced and complex patterns

test "destructuring in for loops", ->
  pairs = [{a: 1, b: 2}, {a: 3, b: 4}]
  sums = []
  for {a, b} in pairs
    sums.push a + b
  eq sums[0], 3
  eq sums[1], 7

test "destructuring with splats", ->
  [first, middle..., last] = [1, 2, 3, 4, 5]
  eq first, 1
  eq last, 5
  eq middle.length, 3

test "complex destructuring", ->
  data =
    users: [
      {name: "Alice", scores: [90, 85]}
      {name: "Bob", scores: [88, 92]}
    ]

  {users: [{name: firstName, scores: [score1]}, {scores: [, score2]}]} = data
  eq firstName, "Alice"
  eq score1, 90
  eq score2, 92

test "method chaining", ->
  class Chain
    constructor: (@value = 0) ->

    add: (n) ->
      @value += n
      this

    multiply: (n) ->
      @value *= n
      this

    get: -> @value

  result = new Chain()
    .add(5)
    .multiply(2)
    .add(3)
    .get()

  eq result, 13

test "nested ternary operators", ->
  grade = (score) ->
    if score >= 90 then "A" else if score >= 80 then "B" else if score >= 70 then "C" else "F"

  eq grade(95), "A"
  eq grade(85), "B"
  eq grade(75), "C"
  eq grade(65), "F"

test "complex array slicing", ->
  arr = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

  # Every other element
  everyOther = (arr[i] for i in [0...arr.length] by 2)
  eq everyOther.length, 5
  eq everyOther[0], 0
  eq everyOther[4], 8

test "guard clauses in comprehensions", ->
  numbers = [1..10]
  result = (n * 2 for n in numbers when n % 2 is 0 and n > 4)
  eq result.length, 3
  eq result[0], 12  # 6 * 2
  eq result[2], 20  # 10 * 2

test "object comprehension with computed keys", ->
  keys = ['a', 'b', 'c']
  values = [1, 2, 3]
  obj = {}
  obj[keys[i]] = values[i] for i in [0...keys.length]

  eq obj.a, 1
  eq obj.b, 2
  eq obj.c, 3

test "switch with multiple values", ->
  classify = (value) ->
    switch value
      when 1, 2, 3 then "small"
      when 4, 5, 6 then "medium"
      when 7, 8, 9 then "large"
      else "unknown"

  eq classify(2), "small"
  eq classify(5), "medium"
  eq classify(8), "large"

test "switch without value (when-then)", ->
  categorize = (age) ->
    switch
      when age < 13 then "child"
      when age < 20 then "teen"
      when age < 60 then "adult"
      else "senior"

  eq categorize(10), "child"
  eq categorize(16), "teen"
  eq categorize(35), "adult"
  eq categorize(70), "senior"

test "postfix loops", ->
  count = 0
  count++ for i in [1..5]
  eq count, 5

  sum = 0
  sum += n for n in [1, 2, 3]
  eq sum, 6

test "loop with guard and index", ->
  arr = ['a', 'b', 'c', 'd', 'e']
  result = []
  for val, idx in arr when idx % 2 is 0
    result.push "#{idx}:#{val}"

  eq result.length, 3
  eq result[0], "0:a"
  eq result[2], "4:e"

test "range with variables", ->
  start = 5
  end = 10
  range = [start..end]
  eq range.length, 6
  eq range[0], 5
  eq range[5], 10

test "negative indices", ->
  # CoffeeScript compiles negative indices to arr[arr.length - n]
  arr = [1, 2, 3, 4, 5]
  # These would work in CoffeeScript source but not in runtime JS
  # eq arr[-1], 5
  # eq arr[-2], 4
  # Instead use slice for negative indexing
  eq arr.slice(-1)[0], 5
  eq arr.slice(-2)[0], 4
  eq arr.slice(-5)[0], 1

test "string multiplication pattern", ->
  # Repeat string pattern
  repeat = (str, n) ->
    result = ""
    result += str for i in [1..n]
    result

  eq repeat("ab", 3), "ababab"

test "default parameters with destructuring", ->
  fn = ({a = 1, b = 2} = {}) ->
    a + b

  eq fn(), 3
  eq fn({a: 5}), 7
  eq fn({b: 10}), 11
  eq fn({a: 5, b: 5}), 10

test "rest parameters in destructuring", ->
  fn = ([first, second, rest...]) ->
    {first, second, rest}

  result = fn([1, 2, 3, 4, 5])
  eq result.first, 1
  eq result.second, 2
  eq result.rest.length, 3

test "complex boolean expressions", ->
  a = true
  b = false
  c = true

  result = a and not b and c
  ok result

  result = a or b and c
  ok result

  result = not (a and b) or c
  ok result

test "property existence checks", ->
  obj = {a: null, b: undefined, c: 0, d: false, e: ""}

  ok 'a' of obj
  ok 'b' of obj
  ok 'c' of obj
  ok 'd' of obj
  ok 'e' of obj
  ok not ('f' of obj)
