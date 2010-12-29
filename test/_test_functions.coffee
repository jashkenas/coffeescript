
okFunc = (f) -> ok(f())
okFunc -> true



# Ensure that functions with the same name don't clash with helper functions.
del = -> 5
ok del() is 5


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



# This is a crazy one.
x = (obj, func) -> func obj
ident = (x) -> x
result = x {one: ident 1}, (obj) ->
  inner = ident(obj)
  ident inner
ok result.one is 1





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


eq ok, new ->
  ok
  ### Should `return` implicitly   ###
  ### even with trailing comments. ###


#855: execution context for `func arr...` should be `null`
(->
  global = @
  contextTest = -> ok global is @
  array = []
  contextTest array
  contextTest.apply null, array
  contextTest array...
)()


# #894: Splatting against constructor-chained functions.
x = null

class Foo
  bar: (y) -> x = y

new Foo().bar([101]...)

eq x, 101


test "#904: Destructuring function arguments with same-named variables in scope", ->
  a = b = nonce = {}
  fn = ([a,b]) -> {a:a,b:b}
  result = fn([c={},d={}])
  eq c, result.a
  eq d, result.b
  eq nonce, a
  eq nonce, b
