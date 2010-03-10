result: try
  10
finally
  15

ok result is 10


result: try
  throw 'up'
catch err
  err.length

ok result is 2