# CoffeeScript's operations should be chainable, like Python's.

puts 500 > 50 > 5 > -5

puts true is not false is true is not false

puts 10 < 20 > 10

puts 50 > 10 > 5 is parseInt('5', 10)


# Make sure that each argument is only evaluated once, even if used
# more than once.

i: 0
func: -> i++

puts 1 > func() < 1
