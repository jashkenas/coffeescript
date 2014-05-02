return unless global.generators

test "`yield` auto-creates a generator from a function", ->
  genA = -> 
    yield 1

  myGen = genA()

  res = myGen.next()
  ok res.value is 1 and res.done is false

  res = myGen.next()
  ok res.value is undefined and res.done is true

test "bugfix: `yield` can occur after another function declaration", ->
  genB = ->
    funcA = ->
      2
    yield funcA()

  myGen = genB()

  res = myGen.next()
  ok res.value is 2 and res.done is false

  res = myGen.next()
  ok res.value is undefined and res.done is true

test "error if `yield` occurs outside of a function", ->
  throws -> CoffeeScript.compile 'yield 1'

test "error if `yield from` occurs outside of a function", ->
  throws -> CoffeeScript.compile 'yield from 1'

test "multiple `yield`s in one generator", ->
  multiGen = ->
    yield 1
    yield 2
    yield 3

  myGen = multiGen()

  res = myGen.next()
  ok res.value is 1 and res.done is false

  res = myGen.next()
  ok res.value is 2 and res.done is false

  res = myGen.next()
  ok res.value is 3 and res.done is false

  res = myGen.next()
  ok res.value is undefined and res.done is true

test "`yield from` support", ->
  yfGen = ->
    yield from (-> yield i for i in [6..7])()

  myGen = yfGen()

  res = myGen.next()
  ok res.value is 6 and res.done is false

  res = myGen.next()
  ok res.value is 7 and res.done is false

  res = myGen.next()
  ok res.value is undefined and res.done is true


test "single-line `yield`", ->
  slGen = -> yield 1

  myGen = slGen()

  res = myGen.next()
  ok res.value is 1 and res.done is false  

  res = myGen.next()
  ok res.value is undefined and res.done is true

test "single-line `yield from`", ->
  slyfGen = -> yield from (-> yield 1)()

  myGen = slyfGen()

  res = myGen.next()
  ok res.value is 1 and res.done is false  

  res = myGen.next()
  ok res.value is undefined and res.done is true

test "`yield` at the end of a function creates empty generator", ->
  egGen = -> 
    x = 1
    yield

  myGen = egGen()
  
  res = myGen.next()
  ok res.value is undefined and res.done is true 

test "single-line terminating `yield`", ->
  sltGen = -> yield

  myGen = sltGen()
  
  res = myGen.next()
  ok res.value is undefined and res.done is true 

test "`yield` by itself not at the end of a function errors", ->
  throws -> CoffeeScript.compile 'x = -> yield; return'

test "`yield from` at the end of a function errors", ->
  throws -> CoffeeScript.compile 'x = -> x = 1; yield from'

test "`yield` and `yield from` together", ->
  yyfGen = ->
    yield 1
    yield from (-> yield i for i in [2..3])()
    yield 4

  myGen = yyfGen()

  res = myGen.next()
  ok res.value is 1 and res.done is false 

  res = myGen.next()
  ok res.value is 2 and res.done is false 

  res = myGen.next()
  ok res.value is 3 and res.done is false 

  res = myGen.next()
  ok res.value is 4 and res.done is false 

  res = myGen.next()
  ok res.value is undefined and res.done is true

# Note: send() is currently unimplemented as of v0.11.13-pre

# test "generator `send()` works as expected", ->
#   sGen = ->
#     loop
#       x = yield 1
#       yield x

#   myGen = sGen()

#   res = myGen.next()
#   ok res.value is 1 and res.done is false 

#   res = myGen.send 2
#   ok res.value is 2 and res.done is false 

#   res = myGen.next()
#   ok res.value is 1 and res.done is false


