# Range Literals
# --------------

# TODO: add indexing and method invocation tests: [1..4][0] is 1, [0...3].toString()

# shared array
shared = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

test "basic inclusive ranges", ->
  arrayEq [1, 2, 3] , [1..3]
  arrayEq [0, 1, 2] , [0..2]
  arrayEq [0, 1]    , [0..1]
  arrayEq [0]       , [0..0]
  arrayEq [-1]      , [-1..-1]
  arrayEq [-1, 0]   , [-1..0]
  arrayEq [-1, 0, 1], [-1..1]

test "basic exclusive ranges", ->
  arrayEq [1, 2, 3] , [1...4]
  arrayEq [0, 1, 2] , [0...3]
  arrayEq [0, 1]    , [0...2]
  arrayEq [0]       , [0...1]
  arrayEq [-1]      , [-1...0]
  arrayEq [-1, 0]   , [-1...1]
  arrayEq [-1, 0, 1], [-1...2]

  arrayEq [], [1...1]
  arrayEq [], [0...0]
  arrayEq [], [-1...-1]

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  arrayEq [1, 2, 3] , [1 ... 4]
  arrayEq [0, 1, 2] , [0 ... 3]
  arrayEq [0, 1]    , [0 ... 2]
  arrayEq [0]       , [0 ... 1]
  arrayEq [-1]      , [-1 ... 0]
  arrayEq [-1, 0]   , [-1 ... 1]
  arrayEq [-1, 0, 1], [-1 ... 2]

  arrayEq [], [1 ... 1]
  arrayEq [], [0 ... 0]
  arrayEq [], [-1 ... -1]

test "downward ranges", ->
  arrayEq shared, [9..0].reverse()
  arrayEq [5, 4, 3, 2] , [5..2]
  arrayEq [2, 1, 0, -1], [2..-1]

  arrayEq [3, 2, 1]  , [3..1]
  arrayEq [2, 1, 0]  , [2..0]
  arrayEq [1, 0]     , [1..0]
  arrayEq [0]        , [0..0]
  arrayEq [-1]       , [-1..-1]
  arrayEq [0, -1]    , [0..-1]
  arrayEq [1, 0, -1] , [1..-1]
  arrayEq [0, -1, -2], [0..-2]

  arrayEq [4, 3, 2], [4...1]
  arrayEq [3, 2, 1], [3...0]
  arrayEq [2, 1]   , [2...0]
  arrayEq [1]      , [1...0]
  arrayEq []       , [0...0]
  arrayEq []       , [-1...-1]
  arrayEq [0]      , [0...-1]
  arrayEq [0, -1]  , [0...-2]
  arrayEq [1, 0]   , [1...-1]
  arrayEq [2, 1, 0], [2...-1]

test "ranges with variables as enpoints", ->
  [a, b] = [1, 3]
  arrayEq [1, 2, 3], [a..b]
  arrayEq [1, 2]   , [a...b]
  b = -2
  arrayEq [1, 0, -1, -2], [a..b]
  arrayEq [1, 0, -1]    , [a...b]

test "ranges with expressions as endpoints", ->
  [a, b] = [1, 3]
  arrayEq [2, 3, 4, 5, 6], [(a+1)..2*b]
  arrayEq [2, 3, 4, 5]   , [(a+1)...2*b]

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  arrayEq [2, 3, 4, 5]   , [(a+1) ... 2*b]

test "large ranges are generated with looping constructs", ->
  down = [99..0]
  eq 100, (len = down.length)
  eq   0, down[len - 1]

  up = [0...100]
  eq 100, (len = up.length)
  eq  99, up[len - 1]

test "for-from loops over ranges", ->
  array1 = []
  for x from [20..30]
    array1.push(x)
    break if x is 25
  arrayEq array1, [20, 21, 22, 23, 24, 25]

test "for-from comprehensions over ranges", ->
  array1 = (x + 10 for x from [20..25])
  ok array1.join(' ') is '30 31 32 33 34 35'

  array2 = (x for x from [20..30] when x %% 2 == 0)
  ok array2.join(' ') is '20 22 24 26 28 30'

test "#1012 slices with arguments object", ->
  expected = [0..9]
  argsAtStart = (-> [arguments[0]..9]) 0
  arrayEq expected, argsAtStart
  argsAtEnd = (-> [0..arguments[0]]) 9
  arrayEq expected, argsAtEnd
  argsAtBoth = (-> [arguments[0]..arguments[1]]) 0, 9
  arrayEq expected, argsAtBoth

test "#1409: creating large ranges outside of a function body", ->
  CoffeeScript.eval '[0..100]'

test "#2047: Infinite loop possible when `for` loop with `range` uses variables", ->
  up = 1
  down = -1
  a = 1
  b = 5

  testRange = (arg) ->
    [from, to, step, expectedResult] = arg
    r = (x for x in [from..to] by step)
    arrayEq r, expectedResult

  testData = [
    [1, 5, 1, [1..5]]
    [1, 5, -1, []]
    [1, 5, up, [1..5]]
    [1, 5, down, []]

    [a, 5, 1, [1..5]]
    [a, 5, -1, []]
    [a, 5, up, [1..5]]
    [a, 5, down, []]

    [1, b, 1, [1..5]]
    [1, b, -1, []]
    [1, b, up, [1..5]]
    [1, b, down, []]

    [a, b, 1, [1..5]]
    [a, b, -1, []]
    [a, b, up, [1..5]]
    [a, b, down, []]

    [5, 1, 1, []]
    [5, 1, -1, [5..1]]
    [5, 1, up, []]
    [5, 1, down,  [5..1]]

    [5, a, 1, []]
    [5, a, -1, [5..1]]
    [5, a, up, []]
    [5, a, down, [5..1]]

    [b, 1, 1, []]
    [b, 1, -1, [5..1]]
    [b, 1, up, []]
    [b, 1, down, [5..1]]

    [b, a, 1, []]
    [b, a, -1, [5..1]]
    [b, a, up, []]
    [b, a, down, [5..1]]
  ]

  testRange d for d in testData

test "#2047: from, to and step as variables", ->
  up = 1
  down = -1
  a = 1
  b = 5

  r = (x for x in [a..b] by up)
  arrayEq r, [1..5]

  r = (x for x in [a..b] by down)
  arrayEq r, []

  r = (x for x in [b..a] by up)
  arrayEq r, []

  r = (x for x in [b..a] by down)
  arrayEq r, [5..1]

  a = 1
  b = -1
  step = 0
  r = (x for x in [b..a] by step)
  arrayEq r, []

test "#4884: Range not declaring var for the 'i'", ->
  'use strict'
  [0..21].forEach (idx) ->
    idx + 1

  eq global.i, undefined

test "#4889: `for` loop unexpected behavior", ->
  n = 1
  result = []
  for i in [0..n]
    result.push i
    for j in [(i+1)..n]
      result.push j

  arrayEq result, [0,1,1,2,1]

test "#4889: `for` loop unexpected behavior with `by 1` on second loop", ->
  n = 1
  result = []
  for i in [0..n]
    result.push i
    for j in [(i+1)..n] by 1
      result.push j

  arrayEq result, [0,1,1]

test "countdown example from docs", ->
  countdown = (num for num in [10..1])
  arrayEq countdown, [10,9,8,7,6,5,4,3,2,1]

test "counting up when the range goes down returns an empty array", ->
  countdown = (num for num in [10..1] by 1)
  arrayEq countdown, []

test "counting down when the range goes up returns an empty array", ->
  countup = (num for num in [1..10] by -1)
  arrayEq countup, []

test "counting down by too much returns just the first value", ->
  countdown = (num for num in [10..1] by -100)
  arrayEq countdown, [10]

test "counting up by too much returns just the first value", ->
  countup = (num for num in [1..10] by 100)
  arrayEq countup, [1]
