a: [1,2,3]
call_with_lambda: (l) -> null
for i in a
  a: call_with_lambda(->)
  if i == 2
    puts "i = 2"
  else
    break

ok a is null

