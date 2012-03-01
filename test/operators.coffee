# Operators
# ---------

# * Operators
# * Existential Operator (Binary)
# * Existential Operator (Unary)
# * Aliased Operators
# * [not] in/of
# * Chained Comparison

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

test "use `::` operator on keywords `this` and `@`", ->
  nonce = {}
  obj =
    withAt:   -> @::prop
    withThis: -> this::prop
  obj.prototype = prop: nonce
  eq nonce, obj.withAt()
  eq nonce, obj.withThis()


# Existential Operator (Binary)

test "binary existential operator", ->
  nonce = {}

  b = a ? nonce
  eq nonce, b

  a = null
  b = undefined
  b = a ? nonce
  eq nonce, b

  a = false
  b = a ? nonce
  eq false, b

  a = 0
  b = a ? nonce
  eq 0, b

test "binary existential operator conditionally evaluates second operand", ->
  i = 1
  func = -> i -= 1
  result = func() ? func()
  eq result, 0

test "binary existential operator with negative number", ->
  a = null ? - 1
  eq -1, a


# Existential Operator (Unary)

test "postfix existential operator", ->
  ok (if nonexistent? then false else true)
  defined = true
  ok defined?
  defined = false
  ok defined?

test "postfix existential operator only evaluates its operand once", ->
  semaphore = 0
  fn = ->
    ok false if semaphore
    ++semaphore
  ok(if fn()? then true else false)

test "negated postfix existential operator", ->
  ok !nothing?.value

test "postfix existential operator on expressions", ->
  eq true, (1 or 0)?, true


# `is`,`isnt`,`==`,`!=`

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


# [not] in/of

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

test "#1099: empty array after `in` should compile to `false`", ->
  eq 1, [5 in []].length
  eq false, do -> return 0 in []

test "#1354: optimized `in` checks should not happen when splats are present", ->
  a = [6, 9]
  eq 9 in [3, a...], true

test "#1100: precedence in or-test compilation of `in`", ->
  ok 0 in [1 and 0]
  ok 0 in [1, 1 and 0]
  ok not (0 in [1, 0 or 1])

test "#1630: `in` should check `hasOwnProperty`", ->
  ok undefined not in length: 1

test "#1714: lexer bug with raw range `for` followed by `in`", ->
  0 for [1..2]
  ok not ('a' in ['b'])

  0 for [1..2]; ok not ('a' in ['b'])

  0 for [1..10] # comment ending
  ok not ('a' in ['b'])

test "#1099: statically determined `not in []` reporting incorrect result", ->
  ok 0 not in []


# Chained Comparison

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

test "#1234: Applying a splat to :: applies the splat to the wrong object", ->
  nonce = {}
  class C
    method: -> @nonce
    nonce: nonce

  arr = []
  eq nonce, C::method arr... # should be applied to `C::`

test "#1102: String literal prevents line continuation", ->
  eq "': '", '' +
     "': '"

test "#1703, ---x is invalid JS", ->
  x = 2
  eq (- --x), -1

test "Regression with implicit calls against an indented assignment", ->
  eq 1, a =
    1

  eq a, 1

test "#2155 ... conditional assignment to a closure", ->
  x = null
  func = -> x ?= (-> if true then 'hi')
  func()
  eq x(), 'hi'