multipliers = [1, 2, 3]
multiples = for j in multipliers
  do (j) ->
    (x) -> x * j

alert(f(2) for f in multiples)
