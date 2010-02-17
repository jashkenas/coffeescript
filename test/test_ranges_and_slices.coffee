array: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

a: array[7..9]
b: array[2...4]

result: a.concat(b).join(' ')

ok result is "7 8 9 2 3"


countdown: [10..1].join(' ')
ok countdown is "10 9 8 7 6 5 4 3 2 1"


array: [(1+5)..1+9]
ok array.join(' ') is "6 7 8 9 10"