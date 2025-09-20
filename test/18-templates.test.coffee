# Test tagged template literals

test "tagged template basic", ->
  # Tag function that uppercases strings
  upper = (strings, values...) ->
    result = ""
    for str, i in strings
      result += str
      result += values[i].toUpperCase() if values[i]?
    result

  name = "world"
  result = upper"""Hello, #{name}!"""
  eq result, "Hello, WORLD!"

test "tagged template with multiple interpolations", ->
  # Tag function that wraps values in brackets
  bracket = (strings, values...) ->
    result = ""
    for str, i in strings
      result += str
      result += "[#{values[i]}]" if values[i]?
    result

  a = 1
  b = 2
  result = bracket"""Value #{a} and #{b}"""
  eq result, "Value [1] and [2]"

test "raw strings in tagged template", ->
  # Tag function that accesses raw strings
  raw = (strings, values...) ->
    strings.raw?[0] or strings[0]

  result = raw"""Line 1\nLine 2"""
  ok result.includes("Line")

test "tagged template with expressions", ->
  # Tag function that counts interpolations
  count = (strings, values...) ->
    values.length

  x = 5
  y = 10
  result = count"""Sum: #{x + y}, Product: #{x * y}"""
  eq result, 2

test "custom DSL with tagged templates", ->
  # SQL-like tag function
  sql = (strings, values...) ->
    query = ""
    for str, i in strings
      query += str
      query += "?" if values[i]?
    { query, values }

  table = "users"
  id = 42
  result = sql"""SELECT * FROM #{table} WHERE id = #{id}"""
  eq result.query, "SELECT * FROM ? WHERE id = ?"
  eq result.values[0], "users"
  eq result.values[1], 42

test "nested tagged templates", ->
  identity = (strings, values...) ->
    result = ""
    for str, i in strings
      result += str
      result += values[i] if values[i]?
    result

  inner = identity"""world"""
  outer = identity"""Hello, #{inner}!"""
  eq outer, "Hello, world!"

test "tagged template with array destructuring", ->
  first = ([str]) -> str

  result = first"""Hello, World!"""
  eq result, "Hello, World!"

test "empty tagged template", ->
  empty = (strings) -> strings.length

  result = empty""""""
  eq result, 1
