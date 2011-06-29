# Scope
# -----

# * Variable Safety
# * Variable Shadowing
# * Auto-closure (`do`)
# * Global Scope Leaks

test "reference `arguments` inside of functions", ->
  sumOfArgs = ->
    sum = (a,b) -> a + b
    sum = 0
    sum += num for num in arguments
    sum
  eq 10, sumOfArgs(0, 1, 2, 3, 4)

test "assignment to an Object.prototype-named variable should not leak to outer scope", ->
  # FIXME: fails on IE
  (->
    constructor = 'word'
  )()
  ok constructor isnt 'word'

test "siblings of variadic arguments shouldn't break out.", ->
  x = 10
  oops = (x,args...) ->
  oops(20, 1,2,3)
  eq x, 10

test "catch statements should introduce their argument to scope", ->
  try throw ''
  catch e
    do -> e = 5
    eq 5, e

test "catch statements should create shared scope with their argument", ->
  g = ->
    try
    catch e
    e = 2 # e should local to g
    try
      throw "error"
    catch e
      e = 3 # e should local to catch clause
      x = 1 # x should local to g, not catch clause

    ok e is 2
    ok x is 1

  e = 1 # this e should be different to e in g
  g()
  ok e is 1
