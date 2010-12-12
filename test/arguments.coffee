# Arguments
# ---------

id = (_) ->
  if arguments.length is 1 then _ else Array::slice.call(arguments)

test "basic argument passing tests", ->
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

test "reference `arguments` inside of functions", ->
  sumOfArgs = ->
    sum = (a,b)-> a + b
    Array::reduce.call(arguments,sum,0)

  eq 10, sumOfArgs(0, 1, 2, 3, 4)


#### Parameter List Features

test "splats", ->
  eq 2, (((splat...) -> splat) 0,1,2)[2]
  eq 3, (((_, _, splat...) -> splat) 0,1,2,3)[1]
  eq 1, (((splat..., _, _) -> splat) 0,1,2,3)[1]
  eq 2, (((_, _, splat..., _) -> splat) 0,1,2,3)[0]

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
  a = (_,_,arg=nonceA) -> arg
  eq nonceA, a()
  eq nonceA, a(0)
  eq nonceB, a(0,0,nonceB)
  eq nonceA, a(0,0,undefined)
  eq nonceA, a(0,0,null)
  eq false , a(0,0,false)
  eq nonceB, a(undefined,undefined,nonceB,undefined)
  b = (_,arg=nonceA,_,_) -> arg
  eq nonceA, b()
  eq nonceA, b(0)
  eq nonceB, b(0,nonceB)
  eq nonceA, b(0,undefined)
  eq nonceA, b(0,null)
  eq false , b(0,false)
  eq nonceB, b(undefined,nonceB,undefined)
  c = (arg=nonceA,_,_) -> arg
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
