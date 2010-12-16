# Ranges, Slices, and Splices
# ---------------------------

# shared array
shared = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]


#### Ranges

test "basic ranges", ->
  arrayEqual [2, 3, 4, 5], [2...6]

test "downward ranges", ->
  arrayEqual shared, [9..0].reverse()
  arrayEqual [5, 4, 3, 2, 1], [5..1]

test "ranges with variables as enpoints", ->
  [a, b] = [1, 5]
  arrayEqual [1, 2, 3, 4], [a...b]
  b = -5
  arrayEqual [1, 0, -1, -2, -3, -4, -5], [a..b]

test "ranges with expressions as endpoints", ->
  arrayEqual [6, 7, 8, 9, 10], [(1+5)..1+9]

test "large ranges are generated with looping constructs", ->
  ary = [100...0]
  ok (len = ary.length) is 100
  ok ary[len - 1] is 1


#### Slices

test "basic slicing", ->
  arrayEqual [7, 8, 9]   , shared[7..9]
  arrayEqual [2, 3]      , shared[2...4]
  arrayEqual [2, 3, 4, 5], shared[2...6]

test "slicing with variables as endpoints", ->
  [a, b] = [1, 5]
  arrayEqual [1, 2, 3, 4], shared[a...b]

test "slicing with expressions as endpoints", ->

test "unbounded slicing", ->
  arrayEqual [7, 8, 9]   , shared[7..]
  arrayEqual [8, 9]      , shared[-2..]
  arrayEqual [9]         , shared[-1...]
  arrayEqual [0, 1, 2]   , shared[...3]
  arrayEqual [0, 1, 2, 3], shared[..-7]
  arrayEqual shared[a..] , shared[a...] for a in [-shared.length..shared.length]
  arrayEqual shared      , shared[..-1]
  arrayEqual shared[0..8], shared[...-1]
  arrayEqual shared[..a] , shared[...a] for a in [-shared.length..shared.length] when a isnt -1

test "#930, #835, #831, #746 #624: inclusive slices to -1 should slice to end", ->

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
  arrayEqual [0, 1, 2, 3, 4, 0, 0, 0], ary

test "unbounded splicing", ->
  ary = [0..9]
  ary[3..] = [9, 8, 7]
  arrayEqual [0, 1, 2, 9, 8, 7]. ary

  ary[...3] = [7, 8, 9]
  arrayEqual [7, 8, 9, 9, 8, 7], ary

# splicing with variables as endpoints

# splicing with expressions as endpoints
