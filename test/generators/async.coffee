throwsEventually = (promise, message) ->
  promise.then ->
    throw new Error "Did not thrown"
  , (e) -> eq e.message, message if message?

sleep = (ms) -> new Promise (resolved) -> setTimeout resolved, ms

slowAdd = (a,b) -<>
  yield sleep 5
  a + b

test "should return promise", ->
  res = do -<>
  eq res.constructor, global.Promise

test "should resolve successfully", ->
  return do -<>

test "should throw on error", ->
  throwsEventually do -<> throw new Error

test "test throwsEventually", ->
  # test throwsEventually itself
  throwsEventually (throwsEventually do -<>), "Did not thrown"

test "simple function", ->

  do -<>
    eq yield slowAdd(1, 2), 3

test "should throw on non-Promise", ->
  throwsEventually (do -<> yield 123), "Expected Promise/A+"

test "should keep contexts", ->

  ctx =
    fn: ->
      unbound: -<> @
      bound: =<> @
      nested: =<> yield do =<> yield do =<> @

  do -<>
    obj = ctx.fn()
    ok obj is yield obj.unbound()
    ok ctx is yield obj.bound()
    ok ctx is yield obj.nested()

test "should be inheritable when used as method", ->

  class A
    method: -<>
      sum = 0
      for i in [0..4]
        sum = yield slowAdd sum, i
      sum

  class B extends A
    constructor: (@factor) ->
    method: -<>
      @factor * yield super

  do -<>
    a = new A
    b = new B 5
    eq (yield a.method()), 10
    eq (yield b.method()), 50


test "should be inheritable when used as constructor", ->

  class A
    constructor: -<>
      @sum = 0
      for i in [0..4]
        @sum = yield slowAdd @sum, i

  class B extends A
    # Delayed constructor is pretty legal!
    constructor: (@factor) -<>
      yield super
      @sum *= @factor

  do -<>
    a = yield new A
    b = yield new B 5
    eq a.sum, 10
    eq b.sum, 50
    eq b.factor, 5






