fibonacci = ->
  [previous, current] = [1, 1]
  loop
    [previous, current] = [current, previous + current]
    yield current
  return

getFibonacciNumbers = (length) ->
  results = [1]
  for n from fibonacci()
    results.push n
    break if results.length is length
  results
