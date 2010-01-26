identity_wrap: (x) =>
  () => x

result: identity_wrap(identity_wrap(true))()()

print result


str: 'god'

result: str.
  split('').
  reverse().
  reverse().
  reverse()

print result.join('') is 'dog'

result: str
  .split('')
  .reverse()
  .reverse()
  .reverse()

print result.join('') is 'dog'