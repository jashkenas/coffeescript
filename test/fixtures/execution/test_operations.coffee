# CoffeeScript's operations should be chainable, like Python's.

print(500 > 50 > 5 > -5)

print(true is not false is true is not false)

print(10 < 20 > 10)

print(50 > 10 > 5 is parseInt('5', 10))


# Make sure that each argument is only evaluated once, even if used
# more than once.

i: 0
func: => i++

print(1 > func() < 1)


# The conditional assignment based on existence.

a: 5
a: null
a ?= 10
b ?= 10

print(a is 10 and b is 10)