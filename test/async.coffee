# Functions that contain the `await` keyword will compile into async functions,
# supported by Node 7.6+, Chrome 55+, Firefox 52+, Safari 10.1+ and Edge.
# But runtimes that don’t support the `await` keyword will throw an error just
# from parsing this file, even without executing it, even if we put
# `return unless try new Function 'async () => {}'` at the top of this file.
# Therefore we need to prevent runtimes which will choke on such code from
# parsing it, which is handled in `Cakefile`.


# This is always fulfilled.
winning = (val) -> Promise.resolve val

# This is always rejected.
failing = (val) -> Promise.reject new Error val


test "async as argument", ->
  ok ->
    await winning()

test "explicit async", ->
  a = do ->
    await return 5
  eq a.constructor, Promise
  a.then (val) ->
    eq val, 5

test "implicit async", ->
  a = do ->
    x = await winning(5)
    y = await winning(4)
    z = await winning(3)
    [x, y, z]

  eq a.constructor, Promise

test "async return value (implicit)", ->
  out = null
  a = ->
    x = await winning(5)
    y = await winning(4)
    z = await winning(3)
    [x, y, z]

  b = do ->
    out = await a()

  b.then ->
    arrayEq out, [5, 4, 3]

test "async return value (explicit)", ->
  out = null
  a = ->
    await return [5, 2, 3]

  b = do ->
    out = await a()

  b.then ->
    arrayEq out, [5, 2, 3]


test "async parameters", ->
  [out1, out2] = [null, null]
  a = (a, [b, c])->
    arr = [a]
    arr.push b
    arr.push c
    await return arr

  b = (a, b, c = 5)->
    arr = [a]
    arr.push b
    arr.push c
    await return arr

  c = do ->
    out1 = await a(5, [4, 3])
    out2 = await b(4, 4)

  c.then ->
    arrayEq out1, [5, 4, 3]
    arrayEq out2, [4, 4, 5]

test "async `this` scoping", ->
  bnd = null
  ubnd = null
  nst = null
  obj =
    bound: ->
      return do =>
        await return this
    unbound: ->
      return do ->
        await return this
    nested: ->
      return do =>
        await do =>
          await do =>
            await return this

  promise = do ->
    bnd = await obj.bound()
    ubnd = await obj.unbound()
    nst = await obj.nested()

  promise.then ->
    eq bnd, obj
    ok ubnd isnt obj
    eq nst, obj

test "await precedence", ->
  out = null

  fn = (win, fail) ->
    win(3)

  promise = do ->
    # assert precedence between unary (new) and power (**) operators
    out = 1 + await new Promise(fn) ** 2

  promise.then ->
    eq out, 10

test "`await` inside IIFEs", ->
  [x, y, z] = new Array(3)

  a = do ->
    x = switch (4)  # switch 4
      when 2
        await winning(1)
      when 4
        await winning(5)
      when 7
        await winning(2)

    y = try
      text = "this should be caught"
      throw new Error(text)
      await winning(1)
    catch e
      await winning(4)

    z = for i in [0..5]
      a = i * i
      await winning(a)

  a.then ->
    eq x, 5
    eq y, 4

    arrayEq z, [0, 1, 4, 9, 16, 25]

test "error handling", ->
  res = null
  val = 0
  a = ->
    try
      await failing("fail")
    catch e
      val = 7  # to assure the catch block runs
      return e

  b = do ->
    res = await a()

  b.then ->
    eq val, 7

    ok res.message?
    eq res.message, "fail"

test "await expression evaluates to argument if not A+", ->
  eq(await 4, 4)


test "implicit call with `await`", ->
  addOne = (arg) -> arg + 1

  a = addOne await 3
  eq a, 4

test "async methods in classes", ->
  class Base
    @static: ->
      await 1
    method: ->
      await 2

  eq await Base.static(), 1
  eq await new Base().method(), 2

  class Child extends Base
    @static: -> super()
    method: -> super()

  eq await Child.static(), 1
  eq await new Child().method(), 2
