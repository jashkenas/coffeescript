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

test "#3194: string interpolation in array", ->
  arr = [ "a"
          key: 'value'
        ]
  eq 2, arr.length
  eq 'a', arr[0]
  eq 'value', arr[1].key

  b = 'b'
  arr = [ "a#{b}"
          key: 'value'
        ]
  eq 2, arr.length
  eq 'ab', arr[0]
  eq 'value', arr[1].key

test "regex interpolation in array", ->
  arr = [ /a/
          key: 'value'
        ]
  eq 2, arr.length
  eq 'a', arr[0].source
  eq 'value', arr[1].key

  b = 'b'
  arr = [ ///a#{b}///
          key: 'value'
        ]
  eq 2, arr.length
  eq 'ab', arr[0].source
  eq 'value', arr[1].key

test "splat extraction from generators", ->
  gen = ->
    yield 1
    yield 2
    yield 3
  arrayEq [ gen()... ], [ 1, 2, 3 ]

test "for-from loops over Array", ->
  array1 = [50, 30, 70, 20]
  array2 = []
  for x from array1
    array2.push(x)
  arrayEq array1, array2

  array1 = [[20, 30], [40, 50]]
  array2 = []
  for [a, b] from array1
    array2.push(b)
    array2.push(a)
  arrayEq array2, [30, 20, 50, 40]

  array1 = [{a: 10, b: 20, c: 30}, {a: 40, b: 50, c: 60}]
  array2 = []
  for {a: a, b, c: d} from array1
    array2.push([a, b, d])
  arrayEq array2, [[10, 20, 30], [40, 50, 60]]

  array1 = [[10, 20, 30, 40, 50]]
  for [a, b..., c] from array1
    eq 10, a
    arrayEq [20, 30, 40], b
    eq 50, c

test "for-from comprehensions over Array", ->
  array1 = (x + 10 for x from [10, 20, 30])
  ok array1.join(' ') is '20 30 40'

  array2 = (x for x from [30, 41, 57] when x %% 3 is 0)
  ok array2.join(' ') is '30 57'

  array1 = (b + 5 for [a, b] from [[20, 30], [40, 50]])
  ok array1.join(' ') is '35 55'

  array2 = (a + b for [a, b] from [[10, 20], [30, 40], [50, 60]] when a + b >= 70)
  ok array2.join(' ') is '70 110'
