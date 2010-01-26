num: 10

result: switch num
  when 5 then false
  when 'a'
    true
    true
    false
  when 10 then true


  # Mid-switch comment with whitespace
  # and multi line
  when 11 then false
  else false

print result

func: (num) =>
  switch num
    when 2, 4, 6
      true
    when 1, 3, 5
      false
    else false

print func(2)
print func(6)
print !func(3)
print !func(8)
