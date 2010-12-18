# Basic chained function calls.
identityWrap = (x) ->
  -> x

result = identityWrap(identityWrap(true))()()

ok result


# Should be able to look at prototypes on keywords.
obj =
  withAt:   -> @::prop
  withThis: -> this::prop
  proto:
    prop: 100
obj.prototype = obj.proto
eq obj.withAt()  , 100
eq obj.withThis(), 100


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

greeting = id(
              """
              Hello
              """)

ok greeting is "Hello"

ok not Date
::
?.foo, '`?.` and `::` should also continue lines'
