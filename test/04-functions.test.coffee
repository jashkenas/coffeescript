# Test function operations

test "simple function", ->
  add = (a, b) -> a + b
  eq add(2, 3), 5

test "function with default parameters", ->
  greet = (name = "World") -> "Hello, #{name}"
  eq greet(), "Hello, World"
  eq greet("CS3"), "Hello, CS3"

test "arrow function", ->
  multiply = (x) -> x * 2
  eq multiply(5), 10

test "function with rest parameters", ->
  sum = (nums...) ->
    total = 0
    total += n for n in nums
    total
  eq sum(1, 2, 3), 6

test "function with destructured parameters", ->
  getName = ({name}) -> name
  eq getName({name: "Alice", age: 30}), "Alice"

test "nested functions", ->
  outer = (x) ->
    inner = (y) -> x + y
    inner(10)
  eq outer(5), 15

test "immediately invoked function", ->
  result = do -> 42
  eq result, 42

test "function returning object", ->
  makePoint = (x, y) -> {x, y}
  point = makePoint(3, 4)
  eq point.x, 3
  eq point.y, 4

test "function with multiple return paths", ->
  abs = (x) ->
    if x < 0
      -x
    else
      x
  eq abs(-5), 5
  eq abs(5), 5

test "bound function", ->
  obj =
    value: 42
    getValue: -> @value
    getBoundValue: => @value
  
  eq obj.getValue(), 42
