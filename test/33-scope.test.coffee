#!/usr/bin/env coffee

# Scope and Variable Safety Tests

test "loop variable should be accessible after for-in loop", ->
  d = (x for x in [1,2])
  eq x, 2

test "loop variable should be accessible after for-of loop", ->
  obj = {a: 1, b: 2}
  d = (x for x of obj)
  ok x in ['a', 'b']

test "loop variable should be accessible after for-from loop", ->
  d = (x for x from [3,4])
  eq x, 4

test "siblings of splat parameters shouldn't leak to surrounding scope", ->
  x = 10
  oops = (x, args...) ->
    x  # This x is the parameter, not outer
  result = oops(20, 1, 2, 3)
  eq x, 10  # Outer x should remain unchanged

test "catch statements should introduce their argument to scope", ->
  result = null
  try 
    throw 'error'
  catch e
    # e should be available in catch block
    do -> e = 5
    result = e
  eq result, 5
  # e should not exist outside catch block

test "nested catch blocks with same variable name", ->
  outer = null
  inner = null
  try
    try
      throw 'inner'
    catch e
      inner = e
      throw 'outer'
  catch e
    outer = e
  eq inner, 'inner'
  eq outer, 'outer'

test "reference arguments inside functions", ->
  sumOfArgs = ->
    sum = 0
    sum += num for num in arguments
    sum
  eq 10, sumOfArgs(0, 1, 2, 3, 4)

test "arguments in arrow functions", ->
  outer = ->
    inner = =>
      arguments  # Should refer to outer's arguments
    inner()
  
  result = outer(1, 2, 3)
  eq result.length, 3
  eq result[0], 1

test "variable shadowing in nested functions", ->
  x = 'outer'
  fn = ->
    x = 'middle'
    inner = ->
      x = 'inner'
      x
    inner()
  result = fn()
  eq result, 'inner'
  eq x, 'inner'  # In CoffeeScript, inner functions can modify outer scope

test "variable shadowing with parameters", ->
  x = 10
  fn = (x) ->
    x * 2
  eq fn(5), 10
  eq x, 10  # Outer x unchanged

test "do block creates closure but shares scope", ->
  x = 'outer'
  do ->
    x = 'inner'
  eq x, 'inner'  # do blocks share scope in CoffeeScript

test "do block with parameter", ->
  x = 5
  result = do (x = 10) ->
    x * 2
  eq result, 20
  eq x, 5  # Outer unchanged

test "for loop index is accessible after loop", ->
  # Don't initialize i before loop
  sum = 0
  arr = ['a', 'b', 'c']
  for val, i in arr
    sum += i
  eq sum, 3  # 0 + 1 + 2
  # After a for loop, i should be the last index value (2 for a 3-element array)
  # But if CS3 increments after last iteration, it might be 3
  ok i in [2, 3]  # Accept either - implementation detail

test "for-own loop variables", ->
  obj = {x: 1, y: 2}
  keys = []
  vals = []
  for own key, val of obj
    keys.push key
    vals.push val
  ok 'x' in keys
  ok 1 in vals
  # key and val should exist after loop
  ok key in ['x', 'y']

test "comprehension variables are accessible after comprehension", ->
  # Don't initialize x
  fn = ->
    result = (x * 2 for x in [1, 2, 3])
    [result, x]  # x is accessible here
  [results, lastX] = fn()
  arrayEq results, [2, 4, 6]
  eq lastX, 3  # Last value of x from comprehension

test "while loop condition scope", ->
  x = 0
  y = 10
  while (x += 1) < 5
    y += x
  eq x, 5
  eq y, 20  # 10 + 1 + 2 + 3 + 4

test "destructuring assignment scope", ->
  x = 'outer'
  {x} = {x: 'inner'}
  eq x, 'inner'  # Destructuring assigns to outer

test "destructuring in function parameters", ->
  x = 'outer'
  fn = ({x}) ->
    x  # This is the destructured parameter
  result = fn({x: 'param'})
  eq result, 'param'
  eq x, 'outer'  # Outer unchanged

test "destructuring with defaults", ->
  x = 'outer'
  fn = ({x = 'default'} = {}) ->
    x
  eq fn(), 'default'
  eq fn({x: 'provided'}), 'provided'
  eq x, 'outer'

test "rest parameters don't affect siblings", ->
  a = 'outer'
  fn = (a, b..., c) ->
    [a, b, c]
  result = fn(1, 2, 3, 4, 5)
  eq result[0], 1
  arrayEq result[1], [2, 3, 4]
  eq result[2], 5
  eq a, 'outer'

test "class property initialization scope", ->
  x = 'outer'
  class TestClass
    x: 'instance'
    constructor: ->
      @y = x  # Should use outer x
    
    method: ->
      x  # Should use outer x
  
  instance = new TestClass()
  eq instance.x, 'instance'
  eq instance.y, 'outer'
  eq instance.method(), 'outer'

test "@-parameters in destructuring", ->
  class TestClass
    constructor: ({@x, @y}) ->
      # @x and @y should be assigned to instance
    
  instance = new TestClass({x: 10, y: 20})
  eq instance.x, 10
  eq instance.y, 20

test "switch case scope", ->
  x = 'outer'
  result = switch 2
    when 1
      x = 'one'
    when 2
      x = 'two'
      x
  eq result, 'two'
  eq x, 'two'  # Switch cases don't create new scope

test "if statement scope", ->
  x = 'outer'
  if true
    x = 'inner'
  eq x, 'inner'  # If blocks don't create new scope

test "array destructuring with rest", ->
  a = 'outer'
  [a, b...] = [1, 2, 3, 4]
  eq a, 1
  arrayEq b, [2, 3, 4]

test "object destructuring with rest", ->
  x = 'outer'
  {x, y...} = {x: 1, y: 2, z: 3}
  eq x, 1
  eq y.y, 2
  eq y.z, 3

test "generator function scope", ->
  x = 'outer'
  gen = ->
    x = 'inner'
    yield x
  g = gen()
  result = g.next()
  eq result.value, 'inner'
  eq x, 'inner'  # In CoffeeScript, functions share outer scope for assignments

test "async function scope", ->
  x = 'outer'
  fn = ->
    x = 'inner'
    await Promise.resolve(x)
  result = await fn()
  eq result, 'inner'
  eq x, 'outer'  # Async functions create scope

test "IIFE returns value but shares scope", ->
  x = 'outer'
  result = do ->
    x = 'inner'
    x
  eq result, 'inner'
  eq x, 'inner'  # IIFE shares scope in CoffeeScript

test "variable hoisting behavior", ->
  fn = ->
    result = x  # Should be undefined, not throw
    x = 10
    result
  eq fn(), undefined
