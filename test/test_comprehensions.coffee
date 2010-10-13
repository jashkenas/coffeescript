# Basic array comprehensions.
nums =    n * n for n in [1, 2, 3] when n % 2 isnt 0
results = n * 2 for n in nums

ok results.join(',') is '2,18'


# Basic object comprehensions.
obj   = {one: 1, two: 2, three: 3}
names = prop + '!' for prop of obj
odds  = prop + '!' for prop, value of obj when value % 2 isnt 0

ok names.join(' ') is "one! two! three!"
ok odds.join(' ')  is "one! three!"


# Basic range comprehensions.
nums = i * 3 for i from 1 to 3
negs = x for x from -20 to -5*2
eq nums.concat(negs.slice 0, 3).join(' '), '3 6 9 -20 -19 -18'


# With range comprehensions, you can loop in steps.
eq "#{ x for x from 0 to 9 by  3 }", '0,3,6,9'
eq "#{ x for x from 9 to 0 by -3 }", '9,6,3,0'
eq "#{ x for x from 3*3 to 0*0 by 0-3 }", '9,6,3,0'


# Multiline array comprehension with filter.
evens = for num in [1, 2, 3, 4, 5, 6] when num % 2 is 0
           num *= -1
           num -= 2
           num * -1
eq evens + '', '4,6,8'


# Backward traversing.
odds = num for num in [0, 1, 2, 3, 4, 5] by -2
eq odds + '', '5,3,1'


# The in operator still works, standalone.
ok 2 of evens

# all/from/to aren't reserved.
all = from = to = 1


# Nested comprehensions.
multiLiner =
  for x from 3 to 5
    for y from 3 to 5
      [x, y]

singleLiner =
  [x, y] for y from 3 to 5 for x from 3 to 5

ok multiLiner.length is singleLiner.length
ok 5 is multiLiner[2][2][1]
ok 5 is singleLiner[2][2][1]


# Comprehensions within parentheses.
result = null
store = (obj) -> result = obj
store (x * 2 for x in [3, 2, 1])

ok result.join(' ') is '6 4 2'


# Closure-wrapped comprehensions that refer to the "arguments" object.
expr = ->
  result = item * item for item in arguments

ok expr(2, 4, 8).join(' ') is '4 16 64'


# Fast object comprehensions over all properties, including prototypal ones.
class Cat
  constructor: -> @name = 'Whiskers'
  breed: 'tabby'
  hair:  'cream'

whiskers = new Cat
own = value for key, value of whiskers
all = value for all key, value of whiskers

ok own.join(' ') is 'Whiskers'
ok all.sort().join(' ') is 'Whiskers cream tabby'


# Comprehensions safely redeclare parameters if they're not present in closest
# scope.
rule = (x) -> x

learn = ->
  rule for rule in [1, 2, 3]

ok learn().join(' ') is '1 2 3'

ok rule(101) is 101
