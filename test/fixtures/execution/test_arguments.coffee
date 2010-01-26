area: (x, y, x1, y1) =>
  (x - x1) * (x - y1)

x:  y:  10
x1: y1: 20

print area(x, y, x1, y1) is 100

print(area(x, y,
           x1, y1) is 100)

print(area(
  x
  y
  x1
  y1
) is 100)


# Arguments are turned into arrays.
curried: () =>
  print area.apply(this, arguments.concat(20, 20)) is 100

curried 10, 10


# Arguments is not a special keyword -- it can be assigned to:
func: () =>
  arguments: 25
  arguments

print func(100) is 25
