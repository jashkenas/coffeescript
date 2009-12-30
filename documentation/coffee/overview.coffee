# Assignment:
number: 42
opposite_day: true

# Conditions:
number: -42 if opposite_day

# Functions:
square: x => x * x

# Arrays:
list: [1, 2, 3, 4, 5]

# Objects:
math: {
  root:   Math.sqrt
  square: square
  cube:   x => x * square(x)
}

# Array comprehensions:
cubed_list: math.cube(num) for num in list
