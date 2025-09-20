# Test Complex Operator Precedence

test "chained assignment", ->
  a = b = c = 42
  eq a, 42
  eq b, 42
  eq c, 42
  
  # Modifying one shouldn't affect others
  a = 10
  eq b, 42
  eq c, 42

test "chained compound assignment", ->
  x = 10
  y = 20
  z = 30
  
  x = y += z *= 2
  eq z, 60  # z = 30 * 2
  eq y, 80  # y = 20 + 60
  eq x, 80  # x = y

test "mixed arithmetic precedence", ->
  # Multiplication before addition
  result = 2 + 3 * 4
  eq result, 14  # Not 20
  
  # Exponentiation before multiplication
  result = 2 * 3 ** 2
  eq result, 18  # 2 * 9, not 36
  
  # Parentheses override
  result = (2 + 3) * 4
  eq result, 20

test "logical operator precedence", ->
  # AND has higher precedence than OR
  result = true or false and false
  ok result  # true or (false and false) = true or false = true
  
  result = false and true or true
  ok result  # (false and true) or true = false or true = true
  
  # NOT has highest precedence
  result = not false and true
  ok result  # (not false) and true = true and true = true

test "comparison chaining", ->
  x = 5
  
  # Chained comparisons
  ok 1 < x < 10
  ok 0 <= x <= 10
  ok not (10 < x < 20)
  
  # Mixed comparison operators
  y = 5
  ok 1 < x <= y < 10

test "ternary operator precedence", ->
  # Ternary has low precedence
  condition = true and false
  result = if condition then "yes" else "no"
  eq result, "no"
  
  # Assignment has lower precedence  
  x = if false then 1 else 2
  eq x, 2
  
  # Nested ternary
  result = if true then (if false then "a" else "b") else "c"
  eq result, "b"

test "existence operator precedence", ->
  obj = {a: {b: 5}}
  
  # Property access before existence
  result = obj?.a?.b ? 0
  eq result, 5
  
  # Existence with arithmetic
  x = null
  result = x ? 10 + 5
  eq result, 15  # x ? (10 + 5)
  
  # Existence with function calls
  fn = -> 42
  x = null
  result = x ? fn()
  eq result, 42

test "bitwise operator precedence", ->
  # Bitwise AND before OR
  result = 5 | 3 & 2
  eq result, 7  # 5 | (3 & 2) = 5 | 2 = 7
  
  # Shift before AND
  result = 1 << 2 & 7
  eq result, 4  # (1 << 2) & 7 = 4 & 7 = 4
  
  # Bitwise lower than comparison
  ok (5 & 3) > 0
  ok 5 & 3 > 0  # Error-prone without parens, but valid

test "string concatenation precedence", ->
  # Addition before concatenation in some contexts
  result = "value: " + 2 + 3
  eq result, "value: 23"  # String concatenation
  
  result = 2 + 3 + " items"
  eq result, "5 items"  # Addition first
  
  # With parentheses
  result = "value: " + (2 + 3)
  eq result, "value: 5"

test "instanceof and in precedence", ->
  class MyClass
  obj = new MyClass()
  arr = [1, 2, 3]
  
  # instanceof and in have same precedence
  ok obj instanceof MyClass and 2 in arr
  
  # Lower than arithmetic
  ok 1 + 1 in [2, 3, 4]
  ok not (1 + 1 in [1, 3, 4])

test "comma operator precedence", ->
  # Comma has lowest precedence
  fn = (a, b, c) -> [a, b, c]
  
  result = fn 1, 2 + 3, 4 * 5
  eq result[0], 1
  eq result[1], 5
  eq result[2], 20

test "do operator precedence", ->
  # do with function
  result = do -> 2 + 3
  eq result, 5
  
  # do in expression
  x = 10 + do -> 5
  eq x, 15
  
  # do with parameters
  result = do (a = 1, b = 2) -> a + b
  eq result, 3

test "spread operator precedence", ->
  arr = [2, 3]
  
  # Spread in function calls
  fn = (a, b, c) -> a + b + c
  result = fn 1, arr...
  eq result, 6  # 1 + 2 + 3 = 6
  
  # Spread in arrays
  newArr = [1, arr..., 4]
  eq newArr.length, 4
  eq newArr[2], 3

test "undefined and null precedence", ->
  # undefined in expressions
  x = undefined
  result = x ? 10
  eq result, 10
  
  # null coalescing
  y = null
  result = y ? 20
  eq result, 20
  
  # undefined with arithmetic results in NaN
  result = undefined + 10
  ok isNaN(result)

test "complex nested precedence", ->
  # A complex expression mixing multiple operators
  a = 2
  b = 3
  c = 4
  d = 5
  
  result = a + b * c ** 2 / d - 1 and true or false
  # = 2 + 3 * 16 / 5 - 1 and true or false
  # = 2 + 48 / 5 - 1 and true or false
  # = 2 + 9.6 - 1 and true or false
  # = 10.6 and true or false
  # = true or false
  # = true
  ok result

test "assignment in conditional expressions", ->
  # Assignment in conditions (generally discouraged but legal)
  if x = 5
    eq x, 5
  else
    ok false  # Should not reach here
  
  # Assignment returns the value
  result = (y = 10)
  eq result, 10
  eq y, 10
