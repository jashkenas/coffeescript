# Slice.
array = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

a = array[7..9]
b = array[2...4]

result = a.concat(b).join(' ')

ok result is "7 8 9 2 3"

a = [0, 1, 2, 3, 4, 5, 6, 7]
deepEqual a[2...6], [2, 3, 4, 5]


# Ranges.
countdown = [10..1].join(' ')
ok countdown is "10 9 8 7 6 5 4 3 2 1"

a = 1
b = 5
nums = [a...b]
ok nums.join(' ') is '1 2 3 4'

b = -5
nums = [a..b]
ok nums.join(' ') is '1 0 -1 -2 -3 -4 -5'


# Expression-based range.
array = [(1+5)..1+9]
ok array.join(' ') is "6 7 8 9 10"


# String slicing (at least on Node).
hello = "Hello World"

ok hello[1...1] is ""
ok hello[1..1] is "e"
ok hello[1...5] is "ello"
ok hello[0..4] is "Hello"


# Splice literals.
array = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

array[5..10] = [0, 0, 0]

ok array.join(' ') is '0 1 2 3 4 0 0 0'


