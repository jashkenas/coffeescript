# Function Partial Application
# ----------------------------

# simplevariadic addition function
add = (args...) -> args.reduce (a,b) -> a + b

test "basic delayed invocation", ->
  a1 = add(1, ...)
  a2 = a1 1, ...
  
  eq 3, (a1 2)
  eq 5, (a2 3)
  eq 3, ((add 1, ...) 2)
  
  # doesn't work
  # yield_add = -> add 
  # d = yield_add() 3, ...
  # eq 8, (d 5)

test "object assignment", ->
  obj = 
    a1: add(1, ...)
    
  eq 3, (obj.a1 2)
  
test "oop outer version", ->

  class A
    constructor: (@value = 0) ->
    increment_by: (val) -> @value += val
    increment: @increment_by(1, ...)
  
  a = new A
  a.increment()
  eq 1, a.value
  
test "oop inner version", ->

  class B
    constructor: (@value = 0) ->
    increment_by: (val) -> @value += val
    increment: -> 
      inc = @increment_by(1, ...)
      inc()

  b = new B
  b.increment()
  eq 1, b.value

