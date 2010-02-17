identity_wrap: (x) ->
  -> x

result: identity_wrap(identity_wrap(true))()()

ok result, 'basic chained function calls'


str: 'god'

result: str.
  split('').
  reverse().
  reverse().
  reverse()

ok result.join('') is 'dog', 'chained accesses split on period/newline'

result: str
  .split('')
  .reverse()
  .reverse()
  .reverse()

ok result.join('') is 'dog', 'chained accesses split on newline/period'