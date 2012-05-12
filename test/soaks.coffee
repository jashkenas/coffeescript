# Soaks
# -----

# * Soaked Property Access
# * Soaked Method Invocation
# * Soaked Function Invocation


# Soaked Property Access

test "soaked property access", ->
  nonce = {}
  obj = a: b: nonce
  eq nonce    , obj?.a.b
  eq nonce    , obj?['a'].b
  eq nonce    , obj.a?.b
  eq nonce    , obj?.a?['b']
  eq undefined, obj?.a?.non?.existent?.property

test "soaked property access caches method calls", ->
  nonce ={}
  obj = fn: -> a: nonce
  eq nonce    , obj.fn()?.a
  eq undefined, obj.fn()?.b

test "soaked property access caching", ->
  nonce = {}
  counter = 0
  fn = ->
    counter++
    'self'
  obj =
    self: -> @
    prop: nonce
  eq nonce, obj[fn()]()[fn()]()[fn()]()?.prop
  eq 3, counter

test "method calls on soaked methods", ->
  nonce = {}
  obj = null
  eq undefined, obj?.a().b()
  obj = a: -> b: -> nonce
  eq nonce    , obj?.a().b()

test "postfix existential operator mixes well with soaked property accesses", ->
  eq false, nonexistent?.property?

test "function invocation with soaked property access", ->
  id = (_) -> _
  eq undefined, id nonexistent?.method()

test "if-to-ternary should safely parenthesize soaked property accesses", ->
  ok (if nonexistent?.property then false else true)

test "#726", ->
  # TODO: check this test, looks like it's not really testing anything
  eq undefined, nonexistent?[Date()]

test "#756", ->
  # TODO: improve this test
  a = null
  ok isNaN      a?.b.c +  1
  eq undefined, a?.b.c += 1
  eq undefined, ++a?.b.c
  eq undefined, delete a?.b.c

test "operations on soaked properties", ->
  # TODO: improve this test
  a = b: {c: 0}
  eq 1,   a?.b.c +  1
  eq 1,   a?.b.c += 1
  eq 2,   ++a?.b.c
  eq yes, delete a?.b.c


# Soaked Method Invocation

test "soaked method invocation", ->
  nonce = {}
  counter = 0
  obj =
    self: -> @
    increment: -> counter++; @
  eq obj      , obj.self?()
  eq undefined, obj.method?()
  eq nonce    , obj.self?().property = nonce
  eq undefined, obj.method?().property = nonce
  eq obj      , obj.increment().increment().self?()
  eq 2        , counter

test "#733", ->
  a = b: {c: null}
  eq a.b?.c?(), undefined
  a.b?.c or= (it) -> it
  eq a.b?.c?(1), 1
  eq a.b?.c?([2, 3]...), 2


# Soaked Function Invocation

test "soaked function invocation", ->
  nonce = {}
  id = (_) -> _
  eq nonce    , id?(nonce)
  eq nonce    , (id? nonce)
  eq undefined, nonexistent?(nonce)
  eq undefined, (nonexistent? nonce)

test "soaked function invocation with generated functions", ->
  nonce = {}
  id = (_) -> _
  maybe = (fn, arg) -> if typeof fn is 'function' then () -> fn(arg)
  eq maybe(id, nonce)?(), nonce
  eq (maybe id, nonce)?(), nonce
  eq (maybe false, nonce)?(), undefined

test "soaked constructor invocation", ->
  eq 42       , +new Number? 42
  eq undefined,  new Other?  42

test "soaked constructor invocations with caching and property access", ->
  semaphore = 0
  nonce = {}
  class C
    constructor: ->
      ok false if semaphore
      semaphore++
    prop: nonce
  eq nonce, (new C())?.prop
  eq 1, semaphore

test "soaked function invocation safe on non-functions", ->
  eq undefined, 0?(1)
  eq undefined, 0? 1, 2
