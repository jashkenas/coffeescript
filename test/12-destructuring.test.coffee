# Test advanced destructuring patterns

test "array destructuring with skip", ->
  [, , third] = [1, 2, 3, 4]
  eq third, 3

test "nested array destructuring", ->
  [[a, b], [c, d]] = [[1, 2], [3, 4]]
  eq a, 1
  eq b, 2
  eq c, 3
  eq d, 4

test "object destructuring with rename", ->
  {name: personName, age: personAge} = {name: "Alice", age: 30}
  eq personName, "Alice"
  eq personAge, 30

test "mixed destructuring", ->
  {data: [first, second]} = {data: [10, 20], status: "ok"}
  eq first, 10
  eq second, 20

test "destructuring in function parameters", ->
  greet = ({name, age}) -> "#{name} is #{age}"
  eq greet({name: "Bob", age: 25}), "Bob is 25"

test "destructuring with defaults", ->
  {x = 10, y = 20} = {x: 5}
  eq x, 5
  eq y, 20

test "array destructuring with defaults", ->
  [a = 1, b = 2] = [undefined, 3]
  eq a, 1
  eq b, 3

test "rest in object destructuring", ->
  {a, rest...} = {a: 1, b: 2, c: 3}
  eq a, 1
  eq rest.b, 2
  eq rest.c, 3

test "destructuring in loops", ->
  pairs = [{x: 1, y: 2}, {x: 3, y: 4}]
  sums = []
  for {x, y} in pairs
    sums.push x + y
  eq sums[0], 3
  eq sums[1], 7

test "destructuring return values", ->
  getCoords = -> {x: 10, y: 20}
  {x, y} = getCoords()
  eq x, 10
  eq y, 20

test "swap with destructuring", ->
  a = 1
  b = 2
  [a, b] = [b, a]
  eq a, 2
  eq b, 1

test "deep nested destructuring", ->
  data =
    user:
      profile:
        name: "Alice"
        settings:
          theme: "dark"

  {user: {profile: {name, settings: {theme}}}} = data
  eq name, "Alice"
  eq theme, "dark"
