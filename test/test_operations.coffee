# CoffeeScript's operations should be chainable, like Python's.
ok 500 > 50 > 5 > -5

ok true is not false is true is not false

ok 0 is 0 isnt 50 is 50

ok 10 < 20 > 10

ok 50 > 10 > 5 is parseInt('5', 10)

i = 0
ok 1 > i++ < 1, 'chained operations should evaluate each value only once'


# `==` and `is` should be interchangeable.
a = b = 1

ok a is 1 and b is 1
ok a == b
ok a is b


# Allow "if x not in y"
obj = {a: true}
ok 'a' of obj
ok 'b' not of obj

# And for "a in b" with array presence.
ok 200 in [100, 200, 300]
array = [100, 200, 300]
ok 200 in array
ok 1 not in array
ok array[0]++ in [99, 100], 'should cache testee'

# And with array presence on an instance variable.
obj = {
  list: [1, 2, 3, 4, 5]
  in_list: (value) -> value in @list
}
ok obj.in_list 4
ok not obj.in_list 0

# Non-spaced values still work.
x = 10
y = -5

ok x*-y is 50
ok x*+y is -50


# Compound operators.
one  = 1
two  = 0
one or= 2
two or= 2

eq one, 1
eq two, 2

zero = 0

zero and= 'one'
one  and= 'one'

eq zero, 0
eq one , 'one'


# Compound assignment should be careful about caching variables.
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

base = -> ++count; base

base().four or= 4
eq base.four, 4
eq count, 4

base().five ?= 5
eq base.five, 5
eq count, 5


# Ensure that RHS is treated as a group.
a = b = false
a and= b or true
ok a is false


# Bitwise operators:
ok (10 &   3) is 2
ok (10 |   3) is 11
ok (10 ^   3) is 9
ok (10 <<  3) is 80
ok (10 >>  3) is 1
ok (10 >>> 3) is 1

num = 10; ok (num <<=  3) is 80
num = 10; ok (num >>=  3) is 1
num = 10; ok (num >>>= 3) is 1
num = 10; ok (num &=   3) is 2
num = 10; ok (num ^=   3) is 9
num = 10; ok (num |=   3) is 11


# Compound assignment with implicit objects.
obj = undefined
obj ?=
  one: 1

ok obj.one is 1

obj and=
  two: 2

ok not obj.one
ok obj.two is 2


# Compound assignment as a sub expression.
[a, b, c] = [1, 2, 3]
ok (a + b += c) is 6
ok a is 1
ok b is 5
ok c is 3


# Instanceof.
ok new String instanceof String
ok new Number not instanceof String


#737: `in` should have higher precedence than logical operators
eq 1, 1 in [1] and 1

#768: `in` should preserve evaluation order
share = 0
a = -> share++ if share is 0
b = -> share++ if share is 1
c = -> share++ if share is 2
ok a() not in [b(),c()] and share is 3 
