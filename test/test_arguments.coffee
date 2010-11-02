area = (x, y, x1, y1) ->
  (x - x1) * (x - y1)

x  = y  = 10
x1 = y1 = 20

ok area(x, y, x1, y1) is 100

# ok(area(x, y,
#            x1, y1) is 100)

ok(area(
  x
  y
  x1
  y1
) is 100)


sumOfArgs = ->
  sum = 0
  sum += val for val in arguments
  sum

ok sumOfArgs(1, 2, 3, 4, 5) is 15


((@arg) ->).call context = {}, 1
ok context.arg is 1

((splat..., @arg) ->).call context, 1, 2, 3
eq context.arg, 3

((@arg...) ->).call context, 1, 2, 3
eq context.arg.join(' '), '1 2 3'

class Klass
  constructor: (@one, @two) ->

obj = new Klass 1, 2

eq obj.one, 1
eq obj.two, 2


# Destructuring.
(([{a: [b], c}]...) ->
  eq b, 123
  eq c, 456
) {a: [123], c: 456}


# Default values.
obj = f: (q = 123, @p = 456) -> q
eq obj.f(), 123
eq obj.p  , 456

withSplats = (a = 2, b..., c = 3, d = 5) -> a * (b.length + 1) * c * d
eq 30, withSplats()
eq 15, withSplats 1
eq  5, withSplats 1, 1
eq  1, withSplats 1, 1, 1
eq  2, withSplats 1, 1, 1, 1
