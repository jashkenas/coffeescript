# Basic blocks.
results = [1, 2, 3].map (x) ->
  x * x

ok results.join(' ') is '1 4 9'


# Chained blocks, with proper indentation levels:
results = []

counter =
  tick: (func) ->
    results.push func()
    this

counter
  .tick ->
    3
  .tick ->
    2
  .tick ->
    1

ok results.join(' ') is '3 2 1'


# Make incorrect indentation safe.
func = ->
  obj = {
      key: 10
    }
  obj.key - 5

ok func() is 5


# Ensure that chained calls with indented implicit object literals below are
# alright.
result = null
obj =
  method: (val)  -> this
  second: (hash) -> result = hash.three


obj
  .method(
    101
  ).second(
    one:
      two: 2
    three: 3
  )

ok result is 3


# Test newline-supressed call chains with nested functions.
obj  =
  call: -> this
func = ->
  obj
    .call ->
      one two
    .call ->
      three four
  101

ok func() is 101
