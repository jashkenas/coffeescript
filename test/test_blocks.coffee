results: [1, 2, 3].map (x) ->
  x * x

ok results.join(' ') is '1 4 9', 'basic block syntax'


# Chained blocks, with proper indentation levels:
results: []

counter: {
  tick: (func) ->
    results.push func()
    this
}

counter
  .tick ->
    3
  .tick ->
    2
  .tick ->
    1

ok results.join(' ') is '3 2 1'