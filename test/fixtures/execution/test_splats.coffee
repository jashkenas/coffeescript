func: first, second, *rest =>
  rest.join(' ')

result: func(1, 2, 3, 4, 5)

print(result is "3 4 5")