# Function Literals
# -----------------

# TODO: add indexing and method invocation tests: (->)[0], (->).call()

# * Function Definition
# * Bound Function Definition
# * Parameter List Features
#   * Splat Parameters
#   * Context (@) Parameters
#   * Parameter Destructuring
#   * Default Parameters

# Function Definition

x = 1
y = {}
y.x = -> 3
ok x is 1
ok typeof(y.x) is 'function'
ok y.x instanceof Function
ok y.x() is 3

# The empty function should not cause a syntax error.
->
() ->

# Multiple nested function declarations mixed with implicit calls should not
# cause a syntax error.
(one) -> (two) -> three four, (five) -> six seven, eight, (nine) ->

# with multiple single-line functions on the same line.
func = (x) -> (x) -> (x) -> x
ok func(1)(2)(3) is 3

# Make incorrect indentation safe.
func = ->
  obj = {
          key: 10
        }
  obj.key - 5
eq func(), 5

# Ensure that functions with the same name don't clash with helper functions.
del = -> 5
ok del() is 5


# Bound Function Definition

obj =
  bound: ->
    (=> this)()
  unbound: ->
    (-> this)()
  nested: ->
    (=>
      (=>
        (=> this)()
      )()
    )()
eq obj, obj.bound()
ok obj isnt obj.unbound()
eq obj, obj.nested()


test "even more fancy bound functions", ->
  obj =
    one: ->
      do =>
        return this.two()
    two: ->
      do =>
        do =>
          do =>
            return this.three
    three: 3

  eq obj.one(), 3


test "self-referencing functions", ->
  changeMe = ->
    changeMe = 2

  changeMe()
  eq changeMe, 2


# Parameter List Features

test "splats", ->
  arrayEq [0, 1, 2], (((splat...) -> splat) 0, 1, 2)
  arrayEq [2, 3], (((_, _1, splat...) -> splat) 0, 1, 2, 3)
  arrayEq [0, 1], (((splat..., _, _1) -> splat) 0, 1, 2, 3)
  arrayEq [2], (((_, _1, splat..., _2) -> splat) 0, 1, 2, 3)

test "destructured splatted parameters", ->
  arr = [0,1,2]
  splatArray = ([a...]) -> a
  splatArrayRest = ([a...],b...) -> arrayEq(a,b); b
  arrayEq splatArray(arr), arr
  arrayEq splatArrayRest(arr,0,1,2), arr

test "@-parameters: automatically assign an argument's value to a property of the context", ->
  nonce = {}

  ((@prop) ->).call context = {}, nonce
  eq nonce, context.prop

  # allow splats along side the special argument
  ((splat..., @prop) ->).apply context = {}, [0, 0, nonce]
  eq nonce, context.prop

  # allow the argument itself to be a splat
  ((@prop...) ->).call context = {}, 0, nonce, 0
  eq nonce, context.prop[1]

  # the argument should still be able to be referenced normally
  eq nonce, (((@prop) -> prop).call {}, nonce)

test "@-parameters and splats with constructors", ->
  a = {}
  b = {}
  class Klass
    constructor: (@first, splat..., @last) ->

  obj = new Klass a, 0, 0, b
  eq a, obj.first
  eq b, obj.last

test "destructuring in function definition", ->
  (([{a: [b], c}]...) ->
    eq 1, b
    eq 2, c
  ) {a: [1], c: 2}

test "default values", ->
  nonceA = {}
  nonceB = {}
  a = (_,_1,arg=nonceA) -> arg
  eq nonceA, a()
  eq nonceA, a(0)
  eq nonceB, a(0,0,nonceB)
  eq nonceA, a(0,0,undefined)
  eq nonceA, a(0,0,null)
  eq false , a(0,0,false)
  eq nonceB, a(undefined,undefined,nonceB,undefined)
  b = (_,arg=nonceA,_1,_2) -> arg
  eq nonceA, b()
  eq nonceA, b(0)
  eq nonceB, b(0,nonceB)
  eq nonceA, b(0,undefined)
  eq nonceA, b(0,null)
  eq false , b(0,false)
  eq nonceB, b(undefined,nonceB,undefined)
  c = (arg=nonceA,_,_1) -> arg
  eq nonceA, c()
  eq      0, c(0)
  eq nonceB, c(nonceB)
  eq nonceA, c(undefined)
  eq nonceA, c(null)
  eq false , c(false)
  eq nonceB, c(nonceB,undefined,undefined)

test "default values with @-parameters", ->
  a = {}
  b = {}
  obj = f: (q = a, @p = b) -> q
  eq a, obj.f()
  eq b, obj.p

test "default values with splatted arguments", ->
  withSplats = (a = 2, b..., c = 3, d = 5) -> a * (b.length + 1) * c * d
  eq 30, withSplats()
  eq 15, withSplats(1)
  eq  5, withSplats(1,1)
  eq  1, withSplats(1,1,1)
  eq  2, withSplats(1,1,1,1)

test "default values with function calls", ->
  doesNotThrow -> CoffeeScript.compile "(x = f()) ->"

test "arguments vs parameters", ->
  doesNotThrow -> CoffeeScript.compile "f(x) ->"
  f = (g) -> g()
  eq 5, f (x) -> 5

test "#1844: bound functions in nested comprehensions causing empty var statements", ->
  a = ((=>) for a in [0] for b in [0])
  eq 1, a.length

test "#1859: inline function bodies shouldn't modify prior postfix ifs", ->
  list = [1, 2, 3]
  ok true if list.some (x) -> x is 2

test "#2258: allow whitespace-style parameter lists in function definitions", ->
  func = (
    a, b, c
  ) -> c
  eq func(1, 2, 3), 3

  func = (
    a
    b
    c
  ) -> b
  eq func(1, 2, 3), 2

test "#2621: fancy destructuring in parameter lists", ->
  func = ({ prop1: { key1 }, prop2: { key2, key3: [a, b, c] } }) ->
    eq(key2, 'key2')
    eq(a, 'a')

  func({prop1: {key1: 'key1'}, prop2: {key2: 'key2', key3: ['a', 'b', 'c']}})

test "#1435 Indented property access", ->
  rec = -> rec: rec

  eq 1, do ->
    rec()
      .rec ->
        rec()
          .rec ->
            rec.rec()
          .rec()
    1
