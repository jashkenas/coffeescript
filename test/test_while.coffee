i = 5
list = while i -= 1
  i * 2

ok list.join(' ') is "8 6 4 2"


i = 5
list = (i * 3 while i -= 1)

ok list.join(' ') is "12 9 6 3"


i = 5
func   = (num) -> i -= num
assert = -> ok i < 5 > 0

results = while func 1
  assert()
  i

ok results.join(' ') is '4 3 2 1'


i = 10
results = while i -= 1 when i % 2 is 0
  i * 2

ok results.join(' ') is '16 12 8 4'


value = false
i = 0
results = until value
  value = true if i is 5
  i += 1

ok i is 6


# And, the loop form of while.
i = 5
list = []
loop
  i -= 1
  break if i is 0
  list.push i * 2

ok list.join(' ') is '8 6 4 2'


#759: `if` within `while` condition
2 while if 1 then 0
