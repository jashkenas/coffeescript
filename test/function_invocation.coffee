# Function Invocation
# -------------------

# * Function Invocation
# * Splats in Function Invocations
# * Implicit Returns
# * Explicit Returns

# shared identity function
id = (_) -> if arguments.length is 1 then _ else Array::slice.call(arguments)

test "basic argument passing", ->
  a = {}
  b = {}
  c = {}
  eq 1, (id 1)
  eq 2, (id 1, 2)[1]
  eq a, (id a)
  eq c, (id a, b, c)[2]

test "passing arguments on separate lines", ->
  a = {}
  b = {}
  c = {}
  ok(id(
    a
    b
    c
  )[1] is b)
  eq(0, id(
    0
    10
  )[0])
  eq(a,id(
    a
  ))
  eq b,
  (id b)

test "optional parens can be used in a nested fashion", ->
  call = (func) -> func()
  add = (a,b) -> a + b
  result = call ->
    inner = call ->
      add 5, 5
  ok result is 10

func = ->
  return if true
eq undefined, func()

result = ("hello".slice) 3
ok result is 'lo'

# And even with strange things like this:
funcs  = [((x) -> x), ((x) -> x * x)]
result = funcs[1] 5
ok result is 25

# More fun with optional parens.
fn = (arg) -> arg
ok fn(fn {prop: 101}).prop is 101

okFunc = (f) -> ok(f())
okFunc -> true

test "chained function calls", ->
  nonce = {}
  identityWrap = (x) ->
    -> x
  eq nonce, identityWrap(identityWrap(nonce))()()
  eq nonce, (identityWrap identityWrap nonce)()()

# Multi-blocks with optional parens.
result = fn( ->
  fn ->
    "Wrapped"
)
ok result()() is 'Wrapped'

# method calls
fnId = (fn) -> -> fn.apply this, arguments
math = {
  add: (a, b) -> a + b
  anonymousAdd: (a, b) -> a + b
  fastAdd: fnId (a, b) -> a + b
}
ok math.add(5, 5) is 10
ok math.anonymousAdd(10, 10) is 20
ok math.fastAdd(20, 20) is 40

# Ensure that functions can have a trailing comma in their argument list
mult = (x, mids..., y) ->
  x *= n for n in mids
  x *= y
ok mult(1, 2,) is 2
ok mult(1, 2, 3,) is 6
ok mult(10, (i for i in [1..6])...) is 7200

test "`@` and `this` should both be able to invoke a method", ->
  nonce = {}
  fn          = (arg) -> eq nonce, arg
  fn.withAt   = -> @ nonce
  fn.withThis = -> this nonce
  fn.withAt()
  fn.withThis()

# Trying an implicit object call with a trailing function.
a = null
meth = (arg, obj, func) -> a = [obj.a, arg, func()].join ' '
meth 'apple', b: 1, a: 13, ->
  'orange'
ok a is '13 apple orange'

# Ensure that empty functions don't return mistaken values.
obj =
  func: (@param, @rest...) ->
ok obj.func(101, 102, 103, 104) is undefined
ok obj.param is 101
ok obj.rest.join(' ') is '102 103 104'

# Passing multiple functions without paren-wrapping is legal, and should compile.
sum = (one, two) -> one() + two()
result = sum ->
  7 + 9
, ->
  1 + 3
ok result is 20

# Implicit call with a trailing if statement as a param.
func = -> arguments[1]
result = func 'one', if false then 100 else 13
ok result is 13

# Test more function passing:
result = sum( ->
  1 + 2
, ->
  2 + 1
)
ok result is 6

sum = (a, b) -> a + b
result = sum(1
, 2)
ok result is 3

# Chained blocks, with proper indentation levels:
counter =
  results: []
  tick: (func) ->
    @results.push func()
    this
counter
  .tick ->
    3
  .tick ->
    2
  .tick ->
    1
arrayEq [3,2,1], counter.results

# This is a crazy one.
x = (obj, func) -> func obj
ident = (x) -> x
result = x {one: ident 1}, (obj) ->
  inner = ident(obj)
  ident inner
ok result.one is 1

# More paren compilation tests:
reverse = (obj) -> obj.reverse()
ok reverse([1, 2].concat 3).join(' ') is '3 2 1'

# Test for inline functions with parentheses and implicit calls.
combine = (func, num) -> func() * num
result  = combine (-> 1 + 2), 3
ok result is 9

# Test for calls/parens/multiline-chains.
f = (x) -> x
result = (f 1).toString()
  .length
ok result is 1

# Test implicit calls in functions in parens:
result = ((val) ->
  [].push val
  val
)(10)
ok result is 10

# Ensure that chained calls with indented implicit object literals below are
# alright.
result = null
obj =
  method: (val)  -> this
  second: (hash) -> result = hash.three
obj
  .method(
    101
  ).second(
    one:
      two: 2
    three: 3
  )
eq result, 3

# Test newline-supressed call chains with nested functions.
obj  =
  call: -> this
func = ->
  obj
    .call ->
      one two
    .call ->
      three four
  101
eq func(), 101

# Implicit objects with number arguments.
func = (x, y) -> y
obj =
  prop: func "a", 1
ok obj.prop is 1

# Non-spaced unary and binary operators should cause a function call.
func = (val) -> val + 1
ok (func +5) is 6
ok (func -5) is -4

# Prefix unary assignment operators are allowed in parenless calls.
val = 5
ok (func --val) is 5

test "#855: execution context for `func arr...` should be `null`", ->
  global ?= window
  contextTest = -> eq @, global
  array = []
  contextTest array
  contextTest.apply null, array
  contextTest array...

test "#904: Destructuring function arguments with same-named variables in scope", ->
  a = b = nonce = {}
  fn = ([a,b]) -> {a:a,b:b}
  result = fn([c={},d={}])
  eq c, result.a
  eq d, result.b
  eq nonce, a
  eq nonce, b

obj =
  index: 0
  0: {method: -> this is obj[0]}
ok obj[obj.index++].method([]...), 'should cache base value'


#### Splats in Function Invocations

test "passing splats to functions", ->
  arrayEq [0..4], id id [0..4]...
  fn = (a, b, c..., d) -> [a, b, c, d]
  range = [0..3]
  [first, second, others, last] = fn range..., 4, [5...8]...
  eq 0, first
  eq 1, second
  arrayEq [2..6], others
  eq 7, last

#894: Splatting against constructor-chained functions.
x = null
class Foo
  bar: (y) -> x = y
new Foo().bar([101]...)
eq x, 101

# Functions with splats being called with too few arguments.
pen = null
method = (first, variable..., penultimate, ultimate) ->
  pen = penultimate
method 1, 2, 3, 4, 5, 6, 7, 8, 9
ok pen is 8
method 1, 2, 3
ok pen is 2
method 1, 2
ok pen is 2

# Finally, splats with super() within classes.
class Parent
  meth: (args...) ->
    args
class Child extends Parent
  meth: ->
    nums = [3, 2, 1]
    super nums...
ok (new Child).meth().join(' ') is '3 2 1'


#### Implicit Return

eq ok, new ->
  ok
  ### Should `return` implicitly   ###
  ### even with trailing comments. ###

test "implicit returns with multiple branches", ->
  nonce = {}
  fn = ->
    if false
      for a in b
        return c if d
    else
      nonce
  eq nonce, fn()

test "implicit returns with switches", ->
  nonce = {}
  fn = ->
    switch nonce
      when nonce then nonce
      else return undefined
  eq nonce, fn()

test "preserve context when generating closure wrappers for expression conversions", ->
  nonce = {}
  obj =
    property: nonce
    method: ->
      this.result = if false
        10
      else
        "a"
        "b"
        this.property
  eq nonce, obj.method()
  eq nonce, obj.property


#### Explicit Returns

test "don't wrap \"pure\" statements in a closure", ->
  nonce = {}
  items = [0, 1, 2, 3, nonce, 4, 5]
  fn = (items) ->
    for item in items
      return item if item is nonce
  eq nonce, fn items
