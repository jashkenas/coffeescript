i: 100
while i -= 1

ok i is 0


i: 5
list: while i -= 1
  i * 2

ok list.join(' ') is "8 6 4 2"


i: 5
list: (i * 3 while i -= 1)

ok list.join(' ') is "12 9 6 3"


i: 5
func:   (num) -> i -= num
assert: -> ok i < 5 > 0

results: while func 1
  assert()
  i

ok results.join(' ') is '4 3 2 1'