# Can assign the result of a try/catch block.
result: try
  nonexistent * missing
catch error
  true

result2: try nonexistent * missing catch error then true

ok result is true and result2 is true


# Can assign a conditional statement.
get_x: -> 10

if x: get_x() then 100

ok x is 10

x: if get_x() then 100

ok x is 100


# This-assignment.
tester: ->
  @example: -> puts 'example function'
  this

ok tester().example.name is 'example'