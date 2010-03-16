# Test with break at the top level.
array: [1,2,3]
call_with_lambda: (l) -> null
for i in array
  result: call_with_lambda(->)
  if i == 2
    puts "i = 2"
  else
    break

ok result is null


# Test with break *not* at the top level.
some_func: (input) ->
  takes_lambda: (l) -> null
  for i in [1,2]
    result: takes_lambda(->)
    if input == 1
      return 1
    else
      break

  return 2

ok some_func(1) is 1
ok some_func(2) is 2

