some_func: (input) ->
  takes_lambda: (l) -> null
  for i in [1,2]
    arbitraty_var: takes_lambda(->)
    if input == 1
      return 1
    else
      break

  return 2

ok some_func(1) is 1
ok some_func(2) is 2

