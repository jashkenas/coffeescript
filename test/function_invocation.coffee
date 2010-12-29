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

result = ("hello".slice) 3
ok result is 'lo'

# And even with strange things like this:
funcs  = [((x) -> x), ((x) -> x * x)]
result = funcs[1] 5
ok result is 25

# More fun with optional parens.
fn = (arg) -> arg
ok fn(fn {prop: 101}).prop is 101

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

