# Basic chained function calls.
identityWrap = (x) ->
  -> x

result = identityWrap(identityWrap(true))()()

ok result


# Chained accesses split on period/newline, backwards and forwards.
str = 'god'

result = str.
  split('').
  reverse().
  reverse().
  reverse()

ok result.join('') is 'dog'

result = str
  .split('')
  .reverse()
  .reverse()
  .reverse()

ok result.join('') is 'dog'


# Newline suppression for operators.
six =
  1 +
  2 +
  3

ok six is 6


# Ensure that indented array literals don't trigger whitespace rewriting.
func = () ->
  ok arguments.length is 1

func(
  [[[[[],
                []],
              [[]]]],
    []])

id = (x) -> x

greeting = id(
              """
              Hello
              """)

ok greeting is "Hello"
