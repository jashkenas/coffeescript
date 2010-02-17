area: (x, y, x1, y1) ->
  (x - x1) * (x - y1)

x:  y:  10
x1: y1: 20

ok area(x, y, x1, y1) is 100, 'basic arguments'

ok(area(x, y,
           x1, y1) is 100, 'arguments on split lines')

ok(area(
  x
  y
  x1
  y1
) is 100, 'newline delimited arguments')


curried: ->
  ok area.apply(this, arguments.concat(20, 20)) is 100, 'arguments converted into an array'

curried 10, 10


func: ->
  arguments: 25
  arguments

ok func(100) is 25, 'arguments as a regular identifier'


this.arguments: 10
ok @arguments is 10, 'arguments accessed as a property'
