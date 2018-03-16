# The `**` and `**=` operators are only supported in Node 7.5+, so the tests
# for these exponentiation operators are split out into their own file to be
# loaded only by supported runtimes.

test "exponentiation operator", ->
  eq 27, 3 ** 3

test "exponentiation operator has higher precedence than other maths operators", ->
  eq 55, 1 + 3 ** 3 * 2
  eq -4, -2 ** 2
  eq 0, (!2) ** 2

test "exponentiation operator is right associative", ->
  eq 2, 2 ** 1 ** 3

test "exponentiation operator compound assignment", ->
  a = 2
  a **= 3
  eq 8, a
