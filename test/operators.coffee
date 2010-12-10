###############
## Operators ##
###############


test "binary (2-ary) math operators do not require spaces", ->
  a = 1
  b = -1
  eq +1, a*-b
  eq -1, a*+b
  eq +1, a/-b
  eq -1, a/+b

test "operators should respect new lines as spaced", ->
  a = 123 +
  456
  eq 579, a

  b = "1#{2}3" +
  "456"
  eq '123456', b

test "multiple operators should space themselves", ->
  eq (+ +1), (- -1)

test "bitwise operators", ->
  eq  2, (10 &   3)
  eq 11, (10 |   3)
  eq  9, (10 ^   3)
  eq 80, (10 <<  3)
  eq  1, (10 >>  3)
  eq  1, (10 >>> 3)
  num = 10; eq  2, (num &=   3)
  num = 10; eq 11, (num |=   3)
  num = 10; eq  9, (num ^=   3)
  num = 10; eq 80, (num <<=  3)
  num = 10; eq  1, (num >>=  3)
  num = 10; eq  1, (num >>>= 3)

test "`instanceof`", ->
  ok new String instanceof String
  ok new Boolean instanceof Boolean
  # `instanceof` supports negation by prefixing the operator with `not`
  ok new Number not instanceof String
  ok new Array not instanceof Boolean


#### Compound Assignment Operators

test "boolean operators", ->
  nonce = {}

  a  = 0
  a or= nonce
  eq nonce, a

  b  = 1
  b or= nonce
  eq 1, b

  c = 0
  c and= nonce
  eq 0, c

  d = 1
  d and= nonce
  eq nonce, d

  # ensure that RHS is treated as a group
  e = f = false
  e and= f or true
  eq false, e

test "compound assignment as a sub expression", ->
  [a, b, c] = [1, 2, 3]
  eq 6, (a + b += c)
  eq 1, a
  eq 5, b
  eq 3, c

# *note: this test could still use refactoring*
test "compound assignment should be careful about caching variables", ->
  count = 0
  list = []

  list[++count] or= 1
  eq 1, list[1]
  eq 1, count

  list[++count] ?= 2
  eq 2, list[2]
  eq 2, count

  list[count++] and= 6
  eq 6, list[2]
  eq 3, count

  base = ->
    ++count
    base

  base().four or= 4
  eq 4, base.four
  eq 4, count

  base().five ?= 5
  eq 5, base.five
  eq 5, count

test "compound assignment with implicit objects", ->
  obj = undefined
  obj ?=
    one: 1

  eq 1, obj.one

  obj and=
    two: 2

  eq undefined, obj.one
  eq         2, obj.two


#### `is`,`isnt`,`==`,`!=`

test "`==` and `is` should be interchangeable", ->
  a = b = 1
  ok a is 1 and b == 1
  ok a == b
  ok a is b

test "`!=` and `isnt` should be interchangeable", ->
  a = 0
  b = 1
  ok a isnt 1 and b != 0
  ok a != b
  ok a isnt b


#### `in`, `of`

# - `in` should check if an array contains a value using `indexOf`
# - `of` should check if a property is defined on an object using `in`
test "in, of", ->
  arr = [1]
  ok 0 of arr
  ok 1 in arr
  # prefixing `not` to `in and `of` should negate them
  ok 1 not of arr
  ok 0 not in arr

test "`in` should be able to operate on an array literal", ->
  ok 2 in [0, 1, 2, 3]
  ok 4 not in [0, 1, 2, 3]
  arr = [0, 1, 2, 3]
  ok 2 in arr
  ok 4 not in arr
  # should cache the value used to test the array
  arr = [0]
  val = 0
  ok val++ in arr
  ok val++ not in arr
  val = 0
  ok val++ of arr
  ok val++ not of arr

test "`of` and `in` should be able to operate on instance variables", ->
  obj = {
    list: [2,3]
    in_list: (value) -> value in @list
    not_in_list: (value) -> value not in @list
    of_list: (value) -> value of @list
    not_of_list: (value) -> value not of @list
  }
  ok obj.in_list 3
  ok obj.not_in_list 1
  ok obj.of_list 0
  ok obj.not_of_list 2

test "#???: `in` with cache and `__indexOf` should work in argument lists", ->
  eq 1, [Object() in Array()].length

test "#737: `in` should have higher precedence than logical operators", ->
  eq 1, 1 in [1] and 1

test "#768: `in` should preserve evaluation order", ->
  share = 0
  a = -> share++ if share is 0
  b = -> share++ if share is 1
  c = -> share++ if share is 2
  ok a() not in [b(),c()]
  eq 3, share


#### Chainable Operators

test "chainable operators", ->
  ok 100 > 10 > 1 > 0 > -1
  ok -1 < 0 < 1 < 10 < 100

test "`is` and `isnt` may be chained", ->
  ok true is not false is true is not false
  ok 0 is 0 isnt 1 is 1

test "different comparison operators (`>`,`<`,`is`,etc.) may be combined", ->
  ok 1 < 2 > 1
  ok 10 < 20 > 2+3 is 5

test "some chainable operators can be negated by `unless`", ->
  ok (true unless 0==10!=100)

test "operator precedence: `|` lower than `<`", ->
  eq 1, 1 | 2 < 3 < 4

test "preserve references", ->
  a = b = c = 1
  # `a == b <= c` should become `a === b && b <= c`
  # (this test does not seem to test for this)
  ok a == b <= c

test "chained operations should evaluate each value only once", ->
  a = 0
  ok 1 > a++ < 1

test "#891: incorrect inversion of chained comparisons", ->
  ok (true unless 0 > 1 > 2)
  ok (true unless (NaN = 0/0) < 0/0 < NaN)
