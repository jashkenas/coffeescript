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


test "arguments in bound functions inherit from parent function", ->
  # The `arguments` object in an ES arrow function refers to the `arguments`
  # of the parent scope, just like `this`. In the CoffeeScript 1.x
  # implementation of `=>`, the `arguments` object referred to the arguments
  # of the arrow function; but per the ES2015 spec, `arguments` should refer
  # to the parent.
  arrayEq ((a...) -> a)([1, 2, 3]), ((a...) => a)([1, 2, 3])

  parent = (a, b, c) ->
    (bound = =>
      [arguments[0], arguments[1], arguments[2]]
    )()
  arrayEq [1, 2, 3], parent(1, 2, 3)


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

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  arrayEq [0, 1, 2], (((splat ...) -> splat) 0, 1, 2)
  arrayEq [2, 3], (((_, _1, splat ...) -> splat) 0, 1, 2, 3)
  arrayEq [0, 1], (((splat ..., _, _1) -> splat) 0, 1, 2, 3)
  arrayEq [2], (((_, _1, splat ..., _2) -> splat) 0, 1, 2, 3)

test "destructured splatted parameters", ->
  arr = [0,1,2]
  splatArray = ([a...]) -> a
  splatArrayRest = ([a...],b...) -> arrayEq(a,b); b
  arrayEq splatArray(arr), arr
  arrayEq splatArrayRest(arr,0,1,2), arr

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  splatArray = ([a ...]) -> a
  splatArrayRest = ([a ...],b ...) -> arrayEq(a,b); b

test "#4884: object-destructured splatted parameters", ->
  f = ({length}...) -> length
  eq f(4, 5, 6), 3
  f = ({length: len}...) -> len
  eq f(4, 5, 6), 3
  f = ({length}..., last) -> [length, last]
  arrayEq f(4, 5, 6), [2, 6]
  f = ({length: len}..., last) -> [len, last]
  arrayEq f(4, 5, 6), [2, 6]

test "@-parameters: automatically assign an argument's value to a property of the context", ->
  nonce = {}

  ((@prop) ->).call context = {}, nonce
  eq nonce, context.prop

  # Allow splats alongside the special argument
  ((splat..., @prop) ->).apply context = {}, [0, 0, nonce]
  eq nonce, context.prop

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  ((splat ..., @prop) ->).apply context = {}, [0, 0, nonce]
  eq nonce, context.prop

  # Allow the argument itself to be a splat
  ((@prop...) ->).call context = {}, 0, nonce, 0
  eq nonce, context.prop[1]

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  ((@prop ...) ->).call context = {}, 0, nonce, 0
  eq nonce, context.prop[1]

  # The argument should not be able to be referenced normally
  code = '((@prop) -> prop).call {}'
  doesNotThrowCompileError code
  throws (-> CoffeeScript.run code), ReferenceError
  code = '((@prop) -> _at_prop).call {}'
  doesNotThrowCompileError code
  throws (-> CoffeeScript.run code), ReferenceError

test "@-parameters and splats with constructors", ->
  a = {}
  b = {}
  class Klass
    constructor: (@first, splat..., @last) ->

  obj = new Klass a, 0, 0, b
  eq a, obj.first
  eq b, obj.last

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  class Klass
    constructor: (@first, splat ..., @last) ->

  obj = new Klass a, 0, 0, b
  eq a, obj.first
  eq b, obj.last

test "destructuring in function definition", ->
  (([{a: [b], c}]...) ->
    eq 1, b
    eq 2, c
  ) {a: [1], c: 2}

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  (([{a: [b], c}] ...) ->
    eq 1, b
    eq 2, c
  ) {a: [1], c: 2}

  context = {}
  (([{a: [b, c = 2], @d, e = 4}]...) ->
    eq 1, b
    eq 2, c
    eq @d, 3
    eq context.d, 3
    eq e, 4
  ).call context, {a: [1], d: 3}

  (({a: aa = 1, b: bb = 2}) ->
    eq 5, aa
    eq 2, bb
  ) {a: 5}

  ajax = (url, {
    async = true,
    beforeSend = (->),
    cache = true,
    method = 'get',
    data = {}
  }) ->
    {url, async, beforeSend, cache, method, data}

  fn = ->
  deepEqual ajax('/home', beforeSend: fn, method: 'post'), {
    url: '/home', async: true, beforeSend: fn, cache: true, method: 'post', data: {}
  }

test "#4005: `([a = {}]..., b) ->` weirdness", ->
  fn = ([a = {}]..., b) -> [a, b]
  deepEqual fn(5), [{}, 5]

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  fn = ([a = {}] ..., b) -> [a, b]
  deepEqual fn(5), [{}, 5]

test "default values", ->
  nonceA = {}
  nonceB = {}
  a = (_,_1,arg=nonceA) -> arg
  eq nonceA, a()
  eq nonceA, a(0)
  eq nonceB, a(0,0,nonceB)
  eq nonceA, a(0,0,undefined)
  eq null, a(0,0,null) # Per ES2015, `null` doesn’t trigger a parameter default value
  eq false , a(0,0,false)
  eq nonceB, a(undefined,undefined,nonceB,undefined)
  b = (_,arg=nonceA,_1,_2) -> arg
  eq nonceA, b()
  eq nonceA, b(0)
  eq nonceB, b(0,nonceB)
  eq nonceA, b(0,undefined)
  eq null, b(0,null)
  eq false , b(0,false)
  eq nonceB, b(undefined,nonceB,undefined)
  c = (arg=nonceA,_,_1) -> arg
  eq nonceA, c()
  eq      0, c(0)
  eq nonceB, c(nonceB)
  eq nonceA, c(undefined)
  eq null, c(null)
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

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  withSplats = (a = 2, b ..., c = 3, d = 5) -> a * (b.length + 1) * c * d
  eq 30, withSplats()
  eq 15, withSplats(1)
  eq  5, withSplats(1,1)
  eq  1, withSplats(1,1,1)
  eq  2, withSplats(1,1,1,1)

test "#156: parameter lists with expansion", ->
  expandArguments = (first, ..., lastButOne, last) ->
    eq 1, first
    eq 4, lastButOne
    last
  eq 5, expandArguments 1, 2, 3, 4, 5

  throwsCompileError "(..., a, b...) ->", null, null, "prohibit expansion and a splat"
  throwsCompileError "(...) ->",          null, null, "prohibit lone expansion"

test "#156: parameter lists with expansion in array destructuring", ->
  expandArray = (..., [..., last]) ->
    last
  eq 3, expandArray 1, 2, 3, [1, 2, 3]

test "#3502: variable definitions and expansion", ->
  a = b = 0
  f = (a, ..., b) -> [a, b]
  arrayEq [1, 5], f 1, 2, 3, 4, 5
  eq 0, a
  eq 0, b

test "variable definitions and splat", ->
  a = b = 0
  f = (a, middle..., b) -> [a, middle, b]
  arrayEq [1, [2, 3, 4], 5], f 1, 2, 3, 4, 5
  eq 0, a
  eq 0, b

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  f = (a, middle ..., b) -> [a, middle, b]
  arrayEq [1, [2, 3, 4], 5], f 1, 2, 3, 4, 5
  eq 0, a
  eq 0, b

test "default values with function calls", ->
  doesNotThrowCompileError "(x = f()) ->"

test "arguments vs parameters", ->
  doesNotThrowCompileError "f(x) ->"
  f = (g) -> g()
  eq 5, f (x) -> 5

test "reserved keyword as parameters", ->
  f = (_case, @case) -> [_case, @case]
  [a, b] = f(1, 2)
  eq 1, a
  eq 2, b

  f = (@case, _case...) -> [@case, _case...]
  [a, b, c] = f(1, 2, 3)
  eq 1, a
  eq 2, b
  eq 3, c

test "reserved keyword at-splat", ->
  f = (@case...) -> @case
  [a, b] = f(1, 2)
  eq 1, a
  eq 2, b

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  f = (@case ...) -> @case
  [a, b] = f(1, 2)
  eq 1, a
  eq 2, b

test "#1574: Destructuring and a parameter named _arg", ->
  f = ({a, b}, _arg, _arg1) -> [a, b, _arg, _arg1]
  arrayEq [1, 2, 3, 4], f a: 1, b: 2, 3, 4

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

test "#1038 Optimize trailing return statements", ->
  compile = (code) -> CoffeeScript.compile(code, bare: yes).trim().replace(/\s+/g, " ")

  eq "(function() {});",                 compile("->")
  eq "(function() {});",                 compile("-> return")
  eq "(function() { return void 0; });", compile("-> undefined")
  eq "(function() { return void 0; });", compile("-> return undefined")
  eq "(function() { foo(); });",         compile("""
                                                 ->
                                                   foo()
                                                   return
                                                 """)

test "#4406 Destructured parameter default evaluation order with incrementing variable", ->
  i = 0
  f = ({ a = ++i }, b = ++i) -> [a, b]
  arrayEq f({}), [1, 2]

test "#4406 Destructured parameter default evaluation order with generator function", ->
  current = 0
  next    = -> ++current
  foo = ({ a = next() }, b = next()) -> [ a, b ]
  arrayEq foo({}), [1, 2]

test "Destructured parameter with default value, that itself has a default value", ->
  # Adapted from https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Destructuring_assignment
  draw = ({size = 'big', coords = {x: 0, y: 0}, radius = 25} = {}) -> "#{size}-#{coords.x}-#{coords.y}-#{radius}"
  output = draw
    coords:
      x: 18
      y: 30
    radius: 30
  eq output, 'big-18-30-30'

test "#4566: destructuring with nested default values", ->
  f = ({a: {b = 1}}) ->
    b
  eq 2, f a: b: 2

test "#1043: comma after function glyph", ->
  x = (a=->, b=2) ->
    a()
  eq x(), undefined

  f = (a) -> a()
  g = f ->, 2
  eq g, undefined
  h = f(=>, 2)
  eq h, undefined

test "#3845/#3446: chain after function glyph", ->
  angular = module: -> controller: -> controller: ->

  eq undefined,
    angular.module 'foo'
    .controller 'EmailLoginCtrl', ->
    .controller 'EmailSignupCtrl', ->

  beforeEach = (f) -> f()
  getPromise = -> then: -> catch: ->

  eq undefined,
    beforeEach ->
      getPromise()
      .then (@result) =>
      .catch (@error) =>

  doThing = -> then: -> catch: (f) -> f()
  handleError = -> 3
  eq 3,
    doThing()
    .then (@result) =>
    .catch handleError

test "#4413: expressions in function parameters that create generated variables have those variables declared correctly", ->
  'use strict'
  # We’re in strict mode because we want an error to be thrown if the generated
  # variable (`ref`) is assigned before being declared.
  foo = -> null
  bar = -> 33
  f = (a = foo() ? bar()) -> a
  g = (a = foo() ? bar()) -> a + 1
  eq f(), 33
  eq g(), 34

test "#4657: destructured array param declarations", ->
  a = 1
  b = 2
  f = ([a..., b]) ->
  f [3, 4, 5]
  eq a, 1
  eq b, 2

test "#4657: destructured array parameters", ->
  f = ([a..., b]) -> {a, b}
  result = f [1, 2, 3, 4]
  arrayEq result.a, [1, 2, 3]
  eq result.b, 4

test "#5128: default parameters of function in binary operation", ->
  foo = yes or (a, b = {}) -> null
  eq foo, yes

test "#5121: array end bracket after function glyph", ->
  a = [->]
  eq a.length, 1

  b = [c: ->]
  eq b.length, 1
