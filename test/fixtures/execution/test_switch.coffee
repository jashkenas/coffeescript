num: 10

result: switch num
  when 5 then false
  when 'a'
    true
    true
    false
  when 10 then true
  when 11 then false
  else false
  
print(result)
