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


func: ->
  arguments: 25
  arguments

ok func(100) is 25, 'arguments as a regular identifier'


this.arguments: 10
ok @arguments is 10, 'arguments accessed as a property'


sum_of_args: ->
  sum: 0
  sum += val for val in arguments
  sum

ok sum_of_args(1, 2, 3, 4, 5) is 15