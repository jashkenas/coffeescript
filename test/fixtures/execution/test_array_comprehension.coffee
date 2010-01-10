nums:    n * n for n in [1, 2, 3] when n % 2 isnt 0
results: n * 2 for n in nums

print(results.join(',') is '2,18')


evens: for num in [1, 2, 3, 4, 5, 6] when num % 2 is 0
           num *= -1
           num -= 2
           num * -1

print(evens.join(', ') is '4, 6, 8')

# Make sure that the "in" operator still works.

print(2 in evens)

