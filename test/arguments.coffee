############
## Arguments
############

id = (_) ->
  if arguments.length is 1 then _ else Array::slice.call(arguments)

# basic argument passing tests
(->
  a = {}
  b = {}
  c = {}
  eq (id 1), 1
  eq (id 1, 2)[1], 2
  eq (id a), a
  eq (id a, b, c)[2], c
)()

# passing arguments on separate lines
(->
  a = {}
  b = {}
  c = {}
  ok(id(
    a
    b
    c
  )[1] is b)
  eq(id(
    0
    10
  )[0], 0)
  eq(id(
    a
  ),a)
  eq (id b),
  b
)()

# reference `arguments` inside of functions
(->
  sumOfArgs = ->
    sum = (a,b)-> a + b
    Array::reduce.call(arguments,sum,0)

  eq sumOfArgs(0, 1, 2, 3, 4), 10
)()


#### Parameter List Features

# splats
eq (((splat...) -> splat) 0,1,2)[2], 2
eq (((_, _, splat...) -> splat) 0,1,2,3)[1], 3
eq (((splat..., _, _) -> splat) 0,1,2,3)[1], 1
eq (((_, _, splat..., _) -> splat) 0,1,2,3)[0], 2

# @-parameters: automatically assign an argument's value to a property of the context
(->
  nonce = {}

  ((@prop) ->).call context = {}, nonce
  eq context.prop, nonce

  # allow splats along side the special argument
  ((splat..., @prop) ->).apply context = {}, [0, 0, nonce]
  eq context.prop, nonce

  # allow the argument itself to be a splat
  ((@prop...) ->).call context = {}, 0, nonce, 0
  eq context.prop[1], nonce

  # the argument should still be able to be referenced normally
  eq (((@prop) -> prop).call {}, nonce), nonce
)()

# @-parameters and splats with constructors
(->
  a = {}
  b = {}
  class Klass
    constructor: (@first, splat..., @last) ->

  obj = new Klass a, 0, 0, b
  eq obj.first, a
  eq obj.last, b
)()

# destructuring in function definition
(([{a: [b], c}]...) ->
  eq b, 1
  eq c, 2
) {a: [1], c: 2}

# default values
(->
  nonceA = {}
  nonceB = {}
  a = (_,_,arg=nonceA) -> arg
  eq a(), nonceA
  eq a(0), nonceA
  eq a(0,0,nonceB), nonceB
  eq a(0,0,undefined), nonceA
  eq a(0,0,null), nonceA
  eq a(0,0,false), false
  eq a(undefined,undefined,nonceB,undefined), nonceB
  b = (_,arg=nonceA,_,_) -> arg
  eq b(), nonceA
  eq b(0), nonceA
  eq b(0,nonceB), nonceB
  eq b(0,undefined), nonceA
  eq b(0,null), nonceA
  eq b(0,false), false
  eq b(undefined,nonceB,undefined), nonceB
  c = (arg=nonceA,_,_) -> arg
  eq c(), nonceA
  eq c(0), 0
  eq c(nonceB), nonceB
  eq c(undefined), nonceA
  eq c(null), nonceA
  eq c(false), false
  eq c(nonceB,undefined,undefined), nonceB
)()

# default values with @-parameters
(->
  a = {}
  b = {}
  obj = f: (q = a, @p = b) -> q
  eq obj.f(), a
  eq obj.p  , b
)()

# default values with splatted arguments
(->
  withSplats = (a = 2, b..., c = 3, d = 5) -> a * (b.length + 1) * c * d
  eq 30, withSplats()
  eq 15, withSplats 1
  eq  5, withSplats 1, 1
  eq  1, withSplats 1, 1, 1
  eq  2, withSplats 1, 1, 1, 1
)()
