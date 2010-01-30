# Assign to try/catch.

result: try
  nonexistent * missing
catch error
  true

result2: try nonexistent * missing catch error then true

puts result is true and result2 is true


# Assign to conditional.

get_x: -> 10

if x: get_x() then 100

puts x is 10

x: if get_x() then 100

puts x is 100