# Generators
# -----------------
#
# * Generator Definition

test "most basic generator support", ->
  ok -> yield 0

test "empty generator", ->
  x = do -> yield return

  y = x.next()
  ok y.value is undefined and y.done is true

test "generator iteration", ->
  x = do ->
    yield 0
    yield 1
    yield 2
  y = x.next()
  ok y.value is 0 and y.done is false

  y = x.next()
  ok y.value is 1 and y.done is false

  y = x.next()
  ok y.value is 2 and y.done is false

  y = x.next()
  ok y.value is undefined and y.done is true

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

test "bound generator", ->
  obj =
    bound: ->
      do =>
        yield this
    unbound: ->
      do ->
        yield this
    nested: ->
      do =>
        yield do =>
          yield do =>
            yield this

  eq obj, obj.bound().next().value
  ok obj isnt obj.unbound().next().value
  eq obj, obj.nested().next().value.next().value.next().value

test "error if `yield` occurs outside of a function", ->
  throws -> CoffeeScript.compile 'yield 1'

test "`yield` by itself not at the end of a function errors", ->
  throws -> CoffeeScript.compile 'x = -> yield; return'

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
  throws -> CoffeeScript.compile 'yield from 1'

test "`yield from` at the end of a function errors", ->
  throws -> CoffeeScript.compile 'x = -> x = 1; yield from'

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

test "yielding for loop expressions", ->
  x = do ->
    yield for i in [1..3]
      i * 2

  y = x.next()
  arrayEq y.value, [2, 4, 6]
  ok y.done is false

  y = x.next 42
  ok y.value is 42 and y.done is true

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
  symbolic   = '+ - * / << >> & | || && ** ^ // or and'.split ' '
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
    yield for item in [1]
      yield => this
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
