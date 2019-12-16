# Generators
# -----------------
#
# * Generator Definition

test "most basic generator support", ->
  ok -> yield

test "empty generator", ->
  x = do -> yield return

  y = x.next()
  ok y.value is undefined and y.done is true

test "generator iteration", ->
  x = do ->
    yield 0
    yield
    yield 2
    3

  y = x.next()
  ok y.value is 0 and y.done is false

  y = x.next()
  ok y.value is undefined and y.done is false

  y = x.next()
  ok y.value is 2 and y.done is false

  y = x.next()
  ok y.value is 3 and y.done is true

test "last line yields are returned", ->
  x = do ->
    yield 3
  y = x.next()
  ok y.value is 3 and y.done is false

  y = x.next 42
  ok y.value is 42 and y.done is true

test "yield return can be used anywhere in the function body", ->
  x = do ->
    if 2 is yield 1
      yield return 42
    throw new Error "this code shouldn't be reachable"

  y = x.next()
  ok y.value is 1 and y.done is false

  y = x.next 2
  ok y.value is 42 and y.done is true

test "`yield from` support", ->
  x = do ->
    yield from do ->
      yield i for i in [3..4]

  y = x.next()
  ok y.value is 3 and y.done is false

  y = x.next 1
  ok y.value is 4 and y.done is false

  y = x.next 2
  arrayEq y.value, [1, 2]
  ok y.done is true

test "error if `yield from` occurs outside of a function", ->
  throwsCompileError 'yield from 1'

test "`yield from` at the end of a function errors", ->
  throwsCompileError 'x = -> x = 1; yield from'

test "yield in if statements", ->
  x = do -> if 1 is yield 2 then 3 else 4

  y = x.next()
  ok y.value is 2 and y.done is false

  y = x.next 1
  ok y.value is 3 and y.done is true

test "yielding if statements", ->
  x = do -> yield if true then 3 else 4

  y = x.next()
  ok y.value is 3 and y.done is false

  y = x.next 42
  ok y.value is 42 and y.done is true

test "yield in for loop expressions", ->
  x = do ->
    y = for i in [1..3]
      yield i * 2

  z = x.next()
  ok z.value is 2 and z.done is false

  z = x.next 10
  ok z.value is 4 and z.done is false

  z = x.next 20
  ok z.value is 6 and z.done is false

  z = x.next 30
  arrayEq z.value, [10, 20, 30]
  ok z.done is true

test "yield in switch expressions", ->
  x = do ->
    y = switch yield 1
      when 2 then yield 1337
      else 1336

  z = x.next()
  ok z.value is 1 and z.done is false

  z = x.next 2
  ok z.value is 1337 and z.done is false

  z = x.next 3
  ok z.value is 3 and z.done is true

test "yielding switch expressions", ->
  x = do ->
    yield switch 1337
      when 1337 then 1338
      else 1336

  y = x.next()
  ok y.value is 1338 and y.done is false

  y = x.next 42
  ok y.value is 42 and y.done is true

test "yield in try expressions", ->
  x = do ->
    try yield 1 catch

  y = x.next()
  ok y.value is 1 and y.done is false

  y = x.next 42
  ok y.value is 42 and y.done is true

test "yielding try expressions", ->
  x = do ->
    yield try 1

  y = x.next()
  ok y.value is 1 and y.done is false

  y = x.next 42
  ok y.value is 42 and y.done is true

test "`yield` can be thrown", ->
  x = do ->
    throw yield null
  x.next()
  throws -> x.next new Error "boom"

test "`throw` can be yielded", ->
  x = do ->
    yield throw new Error "boom"
  throws -> x.next()

test "symbolic operators has precedence over the `yield`", ->
  symbolic   = '+ - * / << >> & | || && ^ // or and'.split ' '
  compound   = ("#{op}=" for op in symbolic)
  relations  = '< > == != <= >= is isnt'.split ' '

  operators  = [symbolic..., '=', compound..., relations...]

  collect = (gen) -> ref.value until (ref = gen.next()).done

  values = [0, 1, 2, 3]
  for op in operators
    expression = "i #{op} 2"

    yielded = CoffeeScript.eval "(arr) ->  yield #{expression} for i in arr"
    mapped  = CoffeeScript.eval "(arr) ->       (#{expression} for i in arr)"

    arrayEq mapped(values), collect yielded values

test "yield handles 'this' correctly", ->
  x = ->
    yield switch
      when true then yield => this
    array = for item in [1]
      yield => this
    yield array
    yield if true then yield => this
    yield try throw yield => this
    throw yield => this

  y = x.call [1, 2, 3]

  z = y.next()
  arrayEq z.value(), [1, 2, 3]
  ok z.done is false

  z = y.next 123
  ok z.value is 123 and z.done is false

  z = y.next()
  arrayEq z.value(), [1, 2, 3]
  ok z.done is false

  z = y.next 42
  arrayEq z.value, [42]
  ok z.done is false

  z = y.next()
  arrayEq z.value(), [1, 2, 3]
  ok z.done is false

  z = y.next 456
  ok z.value is 456 and z.done is false

  z = y.next()
  arrayEq z.value(), [1, 2, 3]
  ok z.done is false

  z = y.next new Error "ignore me"
  ok z.value is undefined and z.done is false

  z = y.next()
  arrayEq z.value(), [1, 2, 3]
  ok z.done is false

  throws -> y.next new Error "boom"

test "for-from loops over generators", ->
  array1 = [50, 30, 70, 20]
  gen = -> yield from array1

  array2 = []
  array3 = []
  array4 = []

  iterator = gen()
  for x from iterator
    array2.push(x)
    break if x is 30

  for x from iterator
    array3.push(x)

  for x from iterator
    array4.push(x)

  arrayEq array2, [50, 30]
  # Different JS engines have different opinions on the value of array3:
  # https://github.com/jashkenas/coffeescript/pull/4306#issuecomment-257066877
  # As a temporary measure, either result is accepted.
  ok array3.length is 0 or array3.join(',') is '70,20'
  arrayEq array4, []

test "for-from comprehensions over generators", ->
  gen = ->
    yield from [30, 41, 51, 60]

  iterator = gen()
  array1 = (x for x from iterator when x %% 2 is 1)
  array2 = (x for x from iterator)

  ok array1.join(' ') is '41 51'
  ok array2.length is 0

test "from as an iterable variable name in a for loop declaration", ->
  from = [1, 2, 3]
  out = []
  for i from from
    out.push i
  arrayEq from, out

test "from as an iterator variable name in a for loop declaration", ->
  a = [1, 2, 3]
  b = []
  for from from a
    b.push from
  arrayEq a, b

test "from as a destructured object variable name in a for loop declaration", ->
  a = [
      from: 1
      to: 2
    ,
      from: 3
      to: 4
  ]
  b = []
  for {from, to} in a
    b.push from
  arrayEq b, [1, 3]

  c = []
  for {to, from} in a
    c.push from
  arrayEq c, [1, 3]

test "from as a destructured, aliased object variable name in a for loop declaration", ->
  a = [
      b: 1
      c: 2
    ,
      b: 3
      c: 4
  ]
  out = []

  for {b: from} in a
    out.push from
  arrayEq out, [1, 3]

test "from as a destructured array variable name in a for loop declaration", ->
  a = [
    [1, 2]
    [3, 4]
  ]
  b = []
  for [from, to] from a
    b.push from
  arrayEq b, [1, 3]

test "generator methods in classes", ->
  class Base
    @static: ->
      yield 1
    method: ->
      yield 2

  arrayEq [1], Array.from Base.static()
  arrayEq [2], Array.from new Base().method()

  class Child extends Base
    @static: -> super()
    method: -> super()

  arrayEq [1], Array.from Child.static()
  arrayEq [2], Array.from new Child().method()
