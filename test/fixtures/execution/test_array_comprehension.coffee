nums:    n * n for n in [1, 2, 3] when n % 2 isnt 0
results: n * 2 for n in nums

obj:   {one: 1, two: 2, three: 3}
names: key + '!' for value, key in obj
odds:  key + '!' for value, key in obj when value % 2 isnt 0

# next: for n in [1, 2, 3] if n % 2 isnt 0
#   print('hi') if false
#   n * n * 2

print(results.join(',') is '2,18')
print(names.join(' ')   is "one! two! three!")
print(odds.join(' ')    is "one! three!")