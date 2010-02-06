nums:    n * n for n in [1, 2, 3] when n % 2 isnt 0
results: n * 2 for n in nums

print results.join(',') is '2,18'


obj:   {one: 1, two: 2, three: 3}
names: prop + '!' for prop of obj
odds:  prop + '!' for prop, value of obj when value % 2 isnt 0

print names.join(' ') is "one! two! three!"
print odds.join(' ')  is "one! three!"


evens: for num in [1, 2, 3, 4, 5, 6] when num % 2 is 0
           num *= -1
           num -= 2
           num * -1

print evens.join(', ') is '4, 6, 8'


# Make sure that the "in" operator still works.

print 2 in evens


# When functions are being defined within the body of a comprehension, make
# sure that their safely wrapped in a closure to preserve local variables.

obj: {}

methods: ['one', 'two', 'three']

for method in methods
  name: method
  obj[name]: ->
    "I'm " + name

print obj.one()   is "I'm one"
print obj.two()   is "I'm two"
print obj.three() is "I'm three"


# Steps should work for array comprehensions.

array: [0..10]
print num % 2 is 0 for num in array by 2
