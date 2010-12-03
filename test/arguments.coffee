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
  ((@prop) ->).call context = {}, 1
  eq context.prop, 1

  # allow splats along side the special argument
  ((splat..., @prop) ->).apply context = {}, [1, 2, 3]
  eq context.prop, 3

  # allow the argument itself to be a splat
  ((@prop...) ->).call context = {}, 1, 2, 3
  eq context.prop.join(' '), '1 2 3'

  # the argument should still be able to be referenced normally
  eq (((@prop) -> prop).call {}, 1), 1
)()

# @-parameters and splats with constructors
(->
  class Klass
    constructor: (@first, splat..., @last) ->

  obj = new Klass 0, 1, 2
  eq obj.first, 0
  eq obj.last, 2
)()

# destructuring in function definition
(([{a: [b], c}]...) ->
  eq b, 1
  eq c, 2
) {a: [1], c: 2}

# default values
(->
  obj = f: (q = 123, @p = 456) -> q
  eq obj.f(), 123
  eq obj.p  , 456
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







