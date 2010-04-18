# Basic chained function calls.
identity_wrap: (x) ->
  -> x

result: identity_wrap(identity_wrap(true))()()

ok result


# Chained accesses split on period/newline, backwards and forwards.
str: 'god'

result: str.
  split('').
  reverse().
  reverse().
  reverse()

ok result.join('') is 'dog'

result: str
  .split('')
  .reverse()
  .reverse()
  .reverse()

ok result.join('') is 'dog'


# Newline suppression for operators.
six:
  1 +
  2 +
  3

ok six is 6

# Bug due to rewriting issue with indented array literals
func: () ->
  ok arguments.length is 1

func(
  [[[[[], 
                []],
              [[]]]],
    []])
