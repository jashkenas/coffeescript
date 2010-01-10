nums:    n * n for n in [1, 2, 3] when n % 2 isnt 0
results: n * 2 for n in nums

print(results.join(',') is '2,18')


obj:   {one: 1, two: 2, three: 3}
names: key + '!' for key, value ino obj
odds:  key + '!' for key, value ino obj when value % 2 isnt 0

print(names.join(' ') is "one! two! three!")
print(odds.join(' ')  is "one! three!")


evens: for num in [1, 2, 3, 4, 5, 6] when num % 2 is 0
           num *= -1
           num -= 2
           num * -1

print(evens.join(', ') is '4, 6, 8')

# Make sure that the "in" operator still works.

print(2 in evens)

