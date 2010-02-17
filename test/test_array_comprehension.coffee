nums:    n * n for n in [1, 2, 3] when n % 2 isnt 0
results: n * 2 for n in nums

ok results.join(',') is '2,18', 'basic array comprehension'


obj:   {one: 1, two: 2, three: 3}
names: prop + '!' for prop of obj
odds:  prop + '!' for prop, value of obj when value % 2 isnt 0

ok names.join(' ') is "one! two! three!", 'basic object comprehension'
ok odds.join(' ')  is "one! three!", 'object comprehension with a filter'


evens: for num in [1, 2, 3, 4, 5, 6] when num % 2 is 0
           num *= -1
           num -= 2
           num * -1

ok evens.join(', ') is '4, 6, 8', 'multiline array comprehension with filter'


ok 2 in evens, 'the in operator still works, standalone'


# Ensure that the closure wrapper preserves local variables.
obj: {}

methods: ['one', 'two', 'three']

for method in methods
  name: method
  obj[name]: ->
    "I'm " + name

ok obj.one()   is "I'm one"
ok obj.two()   is "I'm two"
ok obj.three() is "I'm three"


array: [0..10]
ok(num % 2 is 0 for num in array by 2, 'naked ranges are expanded into arrays')
