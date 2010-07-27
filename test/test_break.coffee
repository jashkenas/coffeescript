# Test with break at the top level.
array = [1,2,3]
callWithLambda = (l) -> null
for i in array
  result = callWithLambda(->)
  if i == 2
    puts "i = 2"
  else
    break

ok result is null


# Test with break *not* at the top level.
someFunc = (input) ->
  takesLambda = (l) -> null
  for i in [1,2]
    result = takesLambda(->)
    if input == 1
      return 1
    else
      break

  return 2

ok someFunc(1) is 1
ok someFunc(2) is 2

