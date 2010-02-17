result: try
  nonexistent * missing
catch error
  true

result2: try nonexistent * missing catch error then true

ok result is true and result2 is true, 'can assign the result of a try/catch block'


get_x: -> 10

if x: get_x() then 100

ok x is 10, 'can assign a conditional statement'

x: if get_x() then 100

ok x is 100, 'can assign a conditional statement'