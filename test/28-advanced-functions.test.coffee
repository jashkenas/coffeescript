# Test Advanced Functions

test "function with rest parameters", ->
  fn = (first, rest...) ->
    first + rest.length

  eq fn(10), 10
  eq fn(10, 1, 2, 3), 13

test "function with destructured parameters", ->
  fn = ({x, y}) ->
    x + y

  eq fn({x: 3, y: 4}), 7

test "function with destructured array parameters", ->
  fn = ([a, b, c]) ->
    a + b + c

  eq fn([1, 2, 3]), 6

test "function with complex default parameters", ->
  fn = (x = 10, y = x * 2) ->
    x + y

  eq fn(), 30
  eq fn(5), 15

test "nested functions", ->
  outer = (x) ->
    inner = (y) ->
      x + y
    inner

  add5 = outer(5)
  eq add5(3), 8

test "function returning function", ->
  makeAdder = (x) ->
    (y) -> x + y

  add10 = makeAdder(10)
  eq add10(5), 15

test "recursive functions", ->
  factorial = (n) ->
    if n <= 1 then 1 else n * factorial(n - 1)

  eq factorial(5), 120

test "mutually recursive functions", ->
  even = null
  odd = null

  even = (n) ->
    if n == 0 then true else odd(n - 1)

  odd = (n) ->
    if n == 0 then false else even(n - 1)

  ok even(4)
  ok not odd(4)

test "functions with @ parameters", ->
  fn = (@value) ->

  obj = {}
  fn.call(obj, 42)
  eq obj.value, 42

test "functions with @ and destructuring", ->
  fn = ({@x, @y}) ->

  obj = {}
  fn.call(obj, {x: 1, y: 2})
  eq obj.x, 1
  eq obj.y, 2

test "bound functions with fat arrow", ->
  obj =
    value: 42
    getBound: -> @value  # Can't use => in object literal
    getUnbound: -> @value

  bound = obj.getBound.bind(obj)
  eq bound(), 42

test "arguments object", ->
  fn = ->
    Array.from(arguments)

  result = fn(1, 2, 3)
  ok result[0] == 1
  ok result[1] == 2
  ok result[2] == 3

test "function with guard clauses", ->
  fn = (x) ->
    return 0 if x < 0
    return 100 if x > 100
    x

  eq fn(-5), 0
  eq fn(50), 50
  eq fn(150), 100

test "function composition", ->
  double = (x) -> x * 2
  addOne = (x) -> x + 1

  compose = (f, g) -> (x) -> f(g(x))
  doubleThenAdd = compose(addOne, double)

  eq doubleThenAdd(5), 11

test "partial application", ->
  add = (a, b, c) -> a + b + c

  partial = (fn, args...) ->
    (moreArgs...) -> fn(args..., moreArgs...)

  add1and2 = partial(add, 1, 2)
  eq add1and2(3), 6

test "function with multiple return points", ->
  fn = (x) ->
    if x < 0
      return 'negative'
    if x == 0
      return 'zero'
    'positive'

  eq fn(-1), 'negative'
  eq fn(0), 'zero'
  eq fn(1), 'positive'

test "generator functions", ->
  gen = ->
    yield 1
    yield 2
    yield 3

  g = gen()
  eq g.next().value, 1
  eq g.next().value, 2
  eq g.next().value, 3

test "async functions", ->
  fn = ->
    await Promise.resolve(42)

  ok fn() instanceof Promise

test "function with try-catch", ->
  fn = (shouldThrow) ->
    try
      throw new Error() if shouldThrow
      'success'
    catch
      'error'

  eq fn(false), 'success'
  eq fn(true), 'error'

test "memoization pattern", ->
  calls = 0
  memoized = do ->
    cache = {}
    (n) ->
      return cache[n] if n of cache
      calls++
      cache[n] = n * 2

  eq memoized(5), 10
  eq memoized(5), 10
  eq calls, 1
