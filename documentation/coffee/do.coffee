coefficients = [1, 2, 3]
multiples = for j in coefficients
  do (j) ->
    (x) -> x * j

alert(f(2) for f in multiples)
