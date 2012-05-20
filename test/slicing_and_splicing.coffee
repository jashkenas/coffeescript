# Slicing and Splicing
# --------------------

# * Slicing
# * Splicing

# shared array
shared = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

# Slicing

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

  arrayEq [1, 2, 3], [1, 2, 3][..]

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

test "#1722: operator precedence in unbounded slice compilation", ->
  list = [0..9]
  n = 2 # some truthy number in `list`
  arrayEq [0..n], list[..n]
  arrayEq [0..n], list[..n or 0]
  arrayEq [0..n], list[..if n then n else 0]

test "#2349: inclusive slicing to numeric strings", ->
  arrayEq [0, 1], [0..10][.."1"]


# Splicing

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

  ary[..] = [1, 2, 3]
  arrayEq [1, 2, 3], ary

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

test "the return value of a splice literal should be the RHS", ->
  ary = [0, 0, 0]
  eq (ary[0..1] = 2), 2

  ary = [0, 0, 0]
  eq (ary[0..] = 3), 3

  arrayEq [ary[0..0] = 0], [0]

test "#1723: operator precedence in unbounded splice compilation", ->
  n = 4 # some truthy number in `list`

  list = [0..9]
  list[..n] = n
  arrayEq [n..9], list

  list = [0..9]
  list[..n or 0] = n
  arrayEq [n..9], list

  list = [0..9]
  list[..if n then n else 0] = n
  arrayEq [n..9], list
