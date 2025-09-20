# Test string operations and interpolation

test "string interpolation", ->
  name = "World"
  eq "Hello, #{name}!", "Hello, World!"

test "multiline strings", ->
  str = """
  Line 1
  Line 2
  """
  ok str.includes("Line 1")
  ok str.includes("Line 2")

test "string interpolation with expressions", ->
  x = 5
  y = 3
  eq "#{x} + #{y} = #{x + y}", "5 + 3 = 8"

test "nested interpolation", ->
  a = 2
  b = 3
  eq "Result: #{a * b}", "Result: 6"

test "interpolation with objects", ->
  obj = {name: "Alice", age: 30}
  eq "Name: #{obj.name}", "Name: Alice"

test "interpolation with function calls", ->
  double = (x) -> x * 2
  eq "Double of 5 is #{double(5)}", "Double of 5 is 10"

test "escaped interpolation", ->
  eq "\\#{test}", "\\#{test}"

test "template literals", ->
  name = "CS3"
  str = "Welcome to #{name}"
  eq str, "Welcome to CS3"

test "string methods in interpolation", ->
  word = "hello"
  eq "#{word.toUpperCase()}", "HELLO"

test "complex interpolation", ->
  users = [{name: "Alice"}, {name: "Bob"}]
  eq "First user: #{users[0].name}", "First user: Alice"

test "interpolation with ternary", ->
  score = 85
  eq "Grade: #{if score >= 80 then 'B' else 'C'}", "Grade: B"

test "block strings preserve indentation", ->
  html = """
    <div>
      <p>Hello</p>
    </div>
    """
  ok html.includes("  <p>")

test "single vs double quotes", ->
  single = 'Hello'
  double = "Hello"
  eq single, double

test "string concatenation", ->
  eq "Hello" + " " + "World", "Hello World"
