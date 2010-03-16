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


sum_of_args: ->
  sum: 0
  sum += val for val in arguments
  sum

ok sum_of_args(1, 2, 3, 4, 5) is 15