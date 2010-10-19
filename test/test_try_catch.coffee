# Basic exception throwing.
block = -> throw 'up'
throws block, 'up'


# Basic try/catch.
result = try
  10
finally
  15

ok result is 10

result = try
  throw 'up'
catch err
  err.length

ok result is 2


result = try throw 'error' catch err then err.length

ok result is 5

try throw 'catch is optional'

# try/catch with empty clauses still compiles.
try

try
  # nothing
catch err
  # nothing

try
  # nothing
finally
  # nothing

try
catch err
finally

ok yes
