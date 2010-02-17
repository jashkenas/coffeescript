identity_wrap: (x) ->
  -> x

result: identity_wrap(identity_wrap(true))()()

puts result


str: 'god'

result: str.
  split('').
  reverse().
  reverse().
  reverse()

puts result.join('') is 'dog'

result: str
  .split('')
  .reverse()
  .reverse()
  .reverse()

puts result.join('') is 'dog'