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

test "large ranges are generated with looping constructs", ->
  down = [99..0]
  eq 100, (len = down.length)
  eq   0, down[len - 1]

  up = [0...100]
  eq 100, (len = up.length)
  eq  99, up[len - 1]

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
