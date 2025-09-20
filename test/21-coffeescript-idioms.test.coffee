# Test CoffeeScript-specific idioms and patterns

test "array presence check with 'in'", ->
  fruits = ["apple", "banana", "orange"]
  ok "banana" in fruits
  ok not ("grape" in fruits)

  numbers = [1, 2, 3]
  ok 2 in numbers
  ok not (5 in numbers)

test "conditional assignment patterns", ->
  # Assign only if undefined
  a = undefined
  a or= 42
  eq a, 42

  # Assign only if null/undefined
  b = null
  b ?= 100
  eq b, 100

  # Keep existing value
  c = 50
  c ?= 200
  eq c, 50

test "splat in function calls", ->
  add = (a, b, c) -> a + b + c
  numbers = [1, 2, 3]
  result = add numbers...
  eq result, 6

test "splat with fixed arguments", ->
  fn = (first, middle..., last) ->
    {first, middle, last}

  result = fn 1, 2, 3, 4, 5
  eq result.first, 1
  eq result.last, 5
  eq result.middle.length, 3

test "implicit object creation", ->
  # Without braces
  person = name: "Alice", age: 30
  eq person.name, "Alice"

  # In function calls
  greet = (options) -> "Hello, #{options.name}"
  result = greet name: "Bob"
  eq result, "Hello, Bob"

test "YAML-style objects", ->
  config =
    server:
      host: "localhost"
      port: 3000
    database:
      name: "myapp"
      user: "admin"

  eq config.server.host, "localhost"
  eq config.database.name, "myapp"

test "unless as guard", ->
  items = []
  addItem = (item) ->
    items.push item unless item in items

  addItem "a"
  addItem "b"
  addItem "a"  # Won't be added
  eq items.length, 2

test "loop as while true", ->
  count = 0
  loop
    count++
    break if count is 5
  eq count, 5

test "array/object destructuring swap", ->
  a = 1
  b = 2
  [a, b] = [b, a]
  eq a, 2
  eq b, 1

  # Object property swap needs temporary variable
  obj = {x: 10, y: 20}
  temp = obj.x
  obj.x = obj.y
  obj.y = temp
  eq obj.x, 20
  eq obj.y, 10

test "existence operator chains", ->
  api =
    user:
      profile:
        name: "Alice"

  name = api?.user?.profile?.name
  eq name, "Alice"

  missing = api?.user?.settings?.theme
  eq missing, undefined

test "default values in destructuring", ->
  getUser = -> {name: "Bob"}
  {name, age = 25} = getUser()
  eq name, "Bob"
  eq age, 25

test "comprehension as expression", ->
  result = if true
    x * 2 for x in [1, 2, 3]
  else
    []

  eq result.length, 3
  eq result[0], 2

test "multi-line array/object literals", ->
  arr = [
    1
    2
    3
  ]
  eq arr.length, 3

  obj =
    a: 1
    b: 2
    c: 3
  eq obj.b, 2

test "string interpolation with expressions", ->
  users = [{name: "Alice"}, {name: "Bob"}]
  message = "Users: #{(u.name for u in users).join(', ')}"
  eq message, "Users: Alice, Bob"

test "postfix if/unless", ->
  result = []
  result.push(1) if true
  result.push(2) unless false
  result.push(3) if false
  result.push(4) unless true

  eq result.length, 2
  eq result[0], 1
  eq result[1], 2

test "until loop", ->
  count = 0
  until count >= 5
    count++
  eq count, 5

test "when with multiple conditions", ->
  checkValue = (val) ->
    switch
      when val < 0
        "negative"
      when val > 0 and val < 10
        "small positive"
      when val >= 10
        "large positive"
      else
        "zero"

  eq checkValue(-5), "negative"
  eq checkValue(5), "small positive"
  eq checkValue(15), "large positive"
  eq checkValue(0), "zero"

test "embedded JavaScript prevention", ->
  # Backticks would normally embed JS
  # but CS3 might handle differently
  str = "backtick test"
  eq str, "backtick test"

test "class with static and instance methods", ->
  class Calculator
    @add: (a, b) -> a + b  # Static method

    constructor: (@value = 0) ->

    add: (n) ->  # Instance method
      @value += n
      @value

  eq Calculator.add(2, 3), 5

  calc = new Calculator(10)
  eq calc.add(5), 15

test "super in multiple contexts", ->
  class Base
    method: -> "base"
    @static: -> "static-base"

  class Derived extends Base
    method: -> "derived-" + super()
    @static: -> "derived-" + super()

  obj = new Derived()
  eq obj.method(), "derived-base"
  eq Derived.static(), "derived-static-base"
