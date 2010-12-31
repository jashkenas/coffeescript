# Array Literals
# --------------

# * Array Literals
# * Splats in Array Literals

# TODO: refactor array literal tests

trailingComma = [1, 2, 3,]
ok (trailingComma[0] is 1) and (trailingComma[2] is 3) and (trailingComma.length is 3)

trailingComma = [
  1, 2, 3,
  4, 5, 6
  7, 8, 9,
]
(sum = (sum or 0) + n) for n in trailingComma

a = [((x) -> x), ((x) -> x * x)]
ok a.length is 2

# Funky indentation within non-comma-seperated arrays.
result = [['a']
 {b: 'c'}]
ok result[0][0] is 'a'
ok result[1]['b'] is 'c'


#### Splats in Array Literals

test "array splat expansions with assignments", ->
  nums = [1, 2, 3]
  list = [a = 0, nums..., b = 4]
  eq 0, a
  eq 4, b
  arrayEq [0,1,2,3,4], list
