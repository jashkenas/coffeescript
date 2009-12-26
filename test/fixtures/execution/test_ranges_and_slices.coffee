array: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

a: array[7..9]
b: array[2...4]

result: a.concat(b).join(' ')

print(result is "7 8 9 2 3")