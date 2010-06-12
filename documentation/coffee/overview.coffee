# Assignment:
number: 42
oppositeDay: true

# Conditions:
number: -42 if oppositeDay

# Functions:
square: (x) -> x * x

# Arrays:
list: [1, 2, 3, 4, 5]

# Objects:
math: {
  root:   Math.sqrt
  square: square
  cube:   (x) -> x * square x
}

# Splats:
race: (winner, runners...) ->
  print winner, runners

# Existence:
alert "I knew it!" if elvis?

# Array comprehensions:
cubedList: math.cube num for num in list
