a: [(x) => x, (x) => x * x]

print a.length is 2


regex: /match/i
words: "I think there is a match in here."

print !!words.match(regex)


neg: (3 -4)

print neg is -1


func: () =>
  return if true

print func() is null


str: "\\"
reg: /\\/

print reg(str) and str is '\\'


i: 10
while i -= 1

print i is 0


money$: 'dollars'

print money$ is 'dollars'