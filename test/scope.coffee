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

test "siblings of splat parameters shouldn't leak to surrounding scope", ->
  x = 10
  oops = (x, args...) ->
  oops(20, 1, 2, 3)
  eq x, 10

test "catch statements should introduce their argument to scope", ->
  try throw ''
  catch e
    do -> e = 5
    eq 5, e

class Array then slice: fail # needs to be global
class Object then hasOwnProperty: fail
test "#1973: redefining Array/Object constructors shouldn't confuse __X helpers", ->
  arr = [1..4]
  arrayEq [3, 4], arr[2..]
  obj = {arr}
  for own k of obj
    eq arr, obj[k]

test "#2255: global leak with splatted @-params", ->
  ok not x?
  arrayEq [0], ((@x...) -> @x).call {}, 0
  ok not x?

test "#1183: super + fat arrows", ->
  dolater = (cb) -> cb()

  class A
  	constructor: ->
  		@_i = 0
  	foo : (cb) ->
  		dolater => 
  			@_i += 1 
  			cb()

  class B extends A
  	constructor : ->
  		super
  	foo : (cb) ->
  		dolater =>
  			dolater =>
  				@_i += 2
  				super cb
          
  b = new B
  b.foo => eq b._i, 3

test "#1183: super + wrap", ->
  class A
    m : -> 10
    
  class B extends A
    constructor : -> super
    
  B::m = -> r = try super()
  
  eq (new B).m(), 10

test "#1183: super + closures", ->
  class A
    constructor: ->
      @i = 10
    foo : -> @i
    
  class B extends A
    foo : ->
      ret = switch 1
        when 0 then 0
        when 1 then super()
      ret
  eq (new B).foo(), 10
 
test "#2331: bound super regression", ->
  class A
    @value = 'A'
    method: -> @constructor.value
    
  class B extends A
    method: => super
  
  eq (new B).method(), 'A'