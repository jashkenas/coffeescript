# Test generator functions (non-async)

test "basic generator function", ->
  gen = ->
    yield 1
    yield 2
    yield 3

  g = gen()
  result = g.next()
  eq result.value, 1
  eq result.done, false

  result = g.next()
  eq result.value, 2
  eq result.done, false

  result = g.next()
  eq result.value, 3
  eq result.done, false

  result = g.next()
  eq result.done, true

test "generator with for..from", ->
  gen = ->
    yield 'a'
    yield 'b'
    yield 'c'

  letters = []
  for letter from gen()
    letters.push letter

  eq letters.length, 3
  eq letters[0], 'a'
  eq letters[2], 'c'

test "generator with return value", ->
  gen = ->
    yield 1
    yield 2
    return 3

  g = gen()
  g.next()  # 1
  g.next()  # 2
  result = g.next()
  eq result.value, 3
  eq result.done, true

test "generator with parameters", ->
  gen = (max) ->
    i = 0
    while i < max
      yield i
      i++

  values = []
  for val from gen(3)
    values.push val

  eq values.length, 3
  eq values[0], 0
  eq values[2], 2

test "generator delegation with yield from", ->
  innerGen = ->
    yield 1
    yield 2

  outerGen = ->
    yield 0
    yield from innerGen()
    yield 3

  values = []
  for val from outerGen()
    values.push val

  eq values.length, 4
  eq values[0], 0
  eq values[1], 1
  eq values[2], 2
  eq values[3], 3

test "infinite generator", ->
  fibonacci = ->
    [prev, curr] = [0, 1]
    loop
      yield curr
      [prev, curr] = [curr, prev + curr]

  fibs = []
  gen = fibonacci()
  for i in [1..5]
    fibs.push gen.next().value

  eq fibs[0], 1
  eq fibs[1], 1
  eq fibs[2], 2
  eq fibs[3], 3
  eq fibs[4], 5

# Generator methods in classes not yet supported
# test "generator in class", ->
#   class Counter
#     *count: ->
#       yield 1
#       yield 2
#       yield 3
