# Array Literals
# --------------

# * Array Literals
# * Splats in Array Literals

# TODO: add indexing and method invocation tests: [1][0] is 1, [].toString()

test "trailing commas", ->
  trailingComma = [1, 2, 3,]
  ok (trailingComma[0] is 1) and (trailingComma[2] is 3) and (trailingComma.length is 3)

  trailingComma = [
    1, 2, 3,
    4, 5, 6
    7, 8, 9,
  ]
  (sum = (sum or 0) + n) for n in trailingComma

  a = [((x) -> x), ((x) -> x * x)]
  ok a.length is 2

test "incorrect indentation without commas", ->
  result = [['a']
   {b: 'c'}]
  ok result[0][0] is 'a'
  ok result[1]['b'] is 'c'


# Splats in Array Literals

test "array splat expansions with assignments", ->
  nums = [1, 2, 3]
  list = [a = 0, nums..., b = 4]
  eq 0, a
  eq 4, b
  arrayEq [0,1,2,3,4], list


test "mixed shorthand objects in array lists", ->

  arr = [
    a:1
    'b'
    c:1
  ]
  ok arr.length is 3
  ok arr[2].c is 1

  arr = [b: 1, a: 2, 100]
  eq arr[1], 100

  arr = [a:0, b:1, (1 + 1)]
  eq arr[1], 2

  arr = [a:1, 'a', b:1, 'b']
  eq arr.length, 4
  eq arr[2].b, 1
  eq arr[3], 'b'


test "array splats with nested arrays", ->
  nonce = {}
  a = [nonce]
  list = [1, 2, a...]
  eq list[0], 1
  eq list[2], nonce

  a = [[nonce]]
  list = [1, 2, a...]
  arrayEq list, [1, 2, [nonce]]

test "#1274: `[] = a()` compiles to `false` instead of `a()`", ->
  a = false
  fn = -> a = true
  [] = fn()
  ok a
