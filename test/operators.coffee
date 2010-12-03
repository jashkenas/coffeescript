############
## Operators
############

# binary (2-ary) math operators do not require spaces
(->
  a = 1
  b = -1
  eq a*-b, 1
  eq a*+b, -1
  eq a/-b, 1
  eq a/+b, -1
)()

# operators should respect new lines as spaced
(->
  a = 123 +
  456
  eq a, 579

  b = "1#{2}3" +
  "456"
  eq b, '123456'
)()

# multiple operators should space themselves
eq (+ +1), (- -1)

# bitwise operators
(->
  eq (10 &   3), 2
  eq (10 |   3), 11
  eq (10 ^   3), 9
  eq (10 <<  3), 80
  eq (10 >>  3), 1
  eq (10 >>> 3), 1

  num = 10; eq (num &=   3), 2
  num = 10; eq (num |=   3), 11
  num = 10; eq (num ^=   3), 9
  num = 10; eq (num <<=  3), 80
  num = 10; eq (num >>=  3), 1
  num = 10; eq (num >>>= 3), 1
)()

# `instanceof`
(->
  ok new String instanceof String
  ok new Boolean instanceof Boolean
  # `instanceof` supports negation by prefixing the operator with `not`
  ok new Number not instanceof String
  ok new Array not instanceof Boolean
)()


#### compound assignment operators

# boolean operators
(->
  a  = 0
  a or= 2
  eq a, 2

  b  = 1
  b or= 2
  eq b, 1

  c = 0
  c and= 2
  eq c, 0

  d = 1
  d and= 2
  eq d, 2

  # ensure that RHS is treated as a group
  e = f = false
  e and= f or true
  eq e, false
)()

# compound assignment as a sub expression
(->
  [a, b, c] = [1, 2, 3]
  eq (a + b += c), 6
  eq a, 1
  eq b, 5
  eq c, 3
)()

# compound assignment should be careful about caching variables
(->
  count = 0
  list = []

  list[++count] or= 1
  eq list[1], 1
  eq count, 1

  list[++count] ?= 2
  eq list[2], 2
  eq count, 2

  list[count++] and= 'two'
  eq list[2], 'two'
  eq count, 3

  base = ->
    ++count
    base

  base().four or= 4
  eq base.four, 4
  eq count, 4

  base().five ?= 5
  eq base.five, 5
  eq count, 5
)()

# compound assignment with implicit objects
(->
  obj = undefined
  obj ?=
    one: 1

  eq obj.one, 1

  obj and=
    two: 2

  eq obj.one, undefined
  eq obj.two, 2
)()


#### `is`,`isnt`,`==`,`!=`

# `==` and `is` should be interchangeable.
(->
  a = b = 1
  ok a is 1 and b == 1
  ok a == b
  ok a is b
)()

# `!=` and `isnt` should be interchangeable.
(->
  a = 0
  b = 1
  ok a isnt 1 and b != 0
  ok a != b
  ok a isnt b
)()


#### `in`, `of`

# - `in` should check if an array contains a value using `indexOf`
# - `of` should check if a property is defined on an object using `in`
(->
  arr = [1]
  ok 0 of arr
  ok 1 in arr
  # prefixing `not` to `in and `of` should negate them
  ok 1 not of arr
  ok 0 not in arr
)()

# `in` should be able to operate on an array literal
(->
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
)()

# `of` and `in` should be able to operate on instance variables
(->
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
)()

#???: `in` with cache and `__indexOf` should work in argument lists
eq [Object() in Array()].length, 1

#737: `in` should have higher precedence than logical operators.
eq 1, 1 in [1] and 1

#768: `in` should preserve evaluation order.
(->
  share = 0
  a = -> share++ if share is 0
  b = -> share++ if share is 1
  c = -> share++ if share is 2
  ok a() not in [b(),c()]
  eq share, 3
)()


#### chainable operators

ok 100 > 10 > 1 > 0 > -1
ok -1 < 0 < 1 < 10 < 100

# `is` and `isnt` may be chained
ok true is not false is true is not false
ok 0 is 0 isnt 1 is 1

# different comparison operators (`>`,`<`,`is`,etc.) may be combined
ok 1 < 2 > 1
ok 10 < 20 > 2+3 is 5

# some chainable operators can be negated by `unless`
ok (true unless 0==10!=100)

# operator precedence: `|` lower than `<`
eq 1, 1 | 2 < 3 < 4

# preserve references
(->
  a = b = c = 1
  # `a == b <= c` should become `a === b && b <= c`
  ok a == b <= c
)()

# chained operations should evaluate each value only once
(->
  a = 0
  ok 1 > a++ < 1
)()

#891: incorrect inversion of chained comparisons
(->
  ok (true unless 0 > 1 > 2)
  ok (true unless (NaN = 0/0) < 0/0 < NaN)
)()
