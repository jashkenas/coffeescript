results: [1, 2, 3].map (x) ->
  x * x

ok results.join(' ') is '1 4 9', 'basic block syntax'