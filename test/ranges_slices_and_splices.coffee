# Ranges, Slices, and Splices
# ---------------------------

# shared array
shared = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]


#### Ranges

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


#### Slices

test "basic slicing", ->
  arrayEq [7, 8, 9]   , shared[7..9]
  arrayEq [2, 3]      , shared[2...4]
  arrayEq [2, 3, 4, 5], shared[2...6]

test "slicing with variables as endpoints", ->
  [a, b] = [1, 4]
  arrayEq [1, 2, 3, 4], shared[a..b]
  arrayEq [1, 2, 3]   , shared[a...b]

test "slicing with expressions as endpoints", ->
  [a, b] = [1, 3]
  arrayEq [2, 3, 4, 5, 6], shared[(a+1)..2*b]
  arrayEq [2, 3, 4, 5]   , shared[a+1...(2*b)]

test "unbounded slicing", ->
  arrayEq [7, 8, 9]   , shared[7..]
  arrayEq [8, 9]      , shared[-2..]
  arrayEq [9]         , shared[-1...]
  arrayEq [0, 1, 2]   , shared[...3]
  arrayEq [0, 1, 2, 3], shared[..-7]

  arrayEq shared      , shared[..-1]
  arrayEq shared[0..8], shared[...-1]

  for a in [-shared.length..shared.length]
    arrayEq shared[a..] , shared[a...]
  for a in [-shared.length+1...shared.length]
    arrayEq shared[..a][...-1] , shared[...a]

test "#930, #835, #831, #746 #624: inclusive slices to -1 should slice to end", ->
  arrayEq shared, shared[0..-1]
  arrayEq shared, shared[..-1]
  arrayEq shared.slice(1,shared.length), shared[1..-1]

test "string slicing", ->
  str = "abcdefghijklmnopqrstuvwxyz"
  ok str[1...1] is ""
  ok str[1..1] is "b"
  ok str[1...5] is "bcde"
  ok str[0..4] is "abcde"
  ok str[-5..] is "vwxyz"


#### Splices

test "basic splicing", ->
  ary = [0..9]
  ary[5..9] = [0, 0, 0]
  arrayEq [0, 1, 2, 3, 4, 0, 0, 0], ary

  ary = [0..9]
  ary[2...8] = []
  arrayEq [0, 1, 8, 9], ary

test "unbounded splicing", ->
  ary = [0..9]
  ary[3..] = [9, 8, 7]
  arrayEq [0, 1, 2, 9, 8, 7]. ary

  ary[...3] = [7, 8, 9]
  arrayEq [7, 8, 9, 9, 8, 7], ary

test "splicing with variables as endpoints", ->
  [a, b] = [1, 8]

  ary = [0..9]
  ary[a..b] = [2, 3]
  arrayEq [0, 2, 3, 9], ary

  ary = [0..9]
  ary[a...b] = [5]
  arrayEq [0, 5, 8, 9], ary

test "splicing with expressions as endpoints", ->
  [a, b] = [1, 3]

  ary = [0..9]
  ary[ a+1 .. 2*b+1 ] = [4]
  arrayEq [0, 1, 4, 8, 9], ary

  ary = [0..9]
  ary[a+1...2*b+1] = [4]
  arrayEq [0, 1, 4, 7, 8, 9], ary

test "splicing to the end, against a one-time function", ->
  ary = null
  fn = ->
    if ary
      throw 'err'
    else
      ary = [1, 2, 3]

  fn()[0..] = 1

  arrayEq ary, [1]
