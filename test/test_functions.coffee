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


obj = {
  name: 'Fred'

  bound: ->
    (=> eq this, obj)()

  unbound: ->
    (-> ok this isnt obj)()

  nested: ->
    (=>
      (=>
        (=>
          eq this, obj
        )()
      )()
    )()
}

obj.unbound()
obj.bound()
obj.nested()


# Python decorator style wrapper that memoizes any function
memoize = (fn) ->
  cache = {}
  self  = this
  (args...) ->
    key = args.toString()
    return cache[key] if cache[key]
    cache[key] = fn.apply(self, args)

Math = {
  Add: (a, b) -> a + b
  AnonymousAdd: ((a, b) -> a + b)
  FastAdd: memoize (a, b) -> a + b
}

ok Math.Add(5, 5) is 10
ok Math.AnonymousAdd(10, 10) is 20
ok Math.FastAdd(20, 20) is 40


# Parens are optional on simple function calls.
ok 100 > 1 if 1 > 0
ok true unless false
ok true for i in [1..3]

okFunc = (f) -> ok(f())
okFunc -> true

# Optional parens can be used in a nested fashion.
call = (func) -> func()

result = call ->
  inner = call ->
    Math.Add(5, 5)

ok result is 10


# More fun with optional parens.
fn = (arg) -> arg

ok fn(fn {prop: 101}).prop is 101


# Multi-blocks with optional parens.
result = fn( ->
  fn ->
    "Wrapped"
)

ok result()() is 'Wrapped'


# And even with strange things like this:
funcs  = [((x) -> x), ((x) -> x * x)]
result = funcs[1] 5

ok result is 25

result = ("hello".slice) 3

ok result is 'lo'


# And with multiple single-line functions on the same line.
func = (x) -> (x) -> (x) -> x
ok func(1)(2)(3) is 3


# Ensure that functions with the same name don't clash with helper functions.
del = -> 5
ok del() is 5

# Ensure that functions can have a trailing comma in their argument list
mult = (x, mids..., y) ->
  x *= n for n in mids
  x *= y

ok mult(1, 2,) is 2
ok mult(1, 2, 3,) is 6
ok mult(10,[1..6]...,) is 7200


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


# More paren compilation tests:
reverse = (obj) -> obj.reverse()
ok reverse([1, 2].concat 3).join(' ') is '3 2 1'

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


# This is a crazy one.
x = (obj, func) -> func obj
ident = (x) -> x

result = x {one: ident 1}, (obj) ->
  inner = ident(obj)
  ident inner

ok result.one is 1


# Assignment to a Object.prototype-named variable should not leak to outer scope.
# FIXME: fails on IE
(->
  constructor = 'word'
)()

ok constructor isnt 'word'


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


# `@` and `this` should both be able to invoke a method.
func          = (arg) -> ok arg is true
func.withAt   = -> @ true
func.withThis = -> this true

func.withAt()
func.withThis()


# Ensure that constructors invoked with splats return a new object.
args = [1, 2, 3]
Type = (@args) ->
type = new Type args

ok type and type instanceof Type
ok type.args and type.args instanceof Array
ok v is args[i] for v, i in type.args

Type1 = (@a, @b, @c) ->
type1 = new Type1 args...

ok type1 instanceof   Type1
eq type1.constructor, Type1
ok type1.a is args[0] and type1.b is args[1] and type1.c is args[2]


# Ensure that constructors invoked with splats cache the function.
called = 0
get = -> if called++ then false else class Type
new get() args...


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

eq counter.results.join(' '), '3 2 1'


# Make incorrect indentation safe.
func = ->
  obj = {
          key: 10
        }
  obj.key - 5

eq func(), 5


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


# `new` shouldn't add extra parens
ok new Date().constructor is Date


# `new` works against bare function
eq Date, new ->
  eq this, new => this
  Date


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
