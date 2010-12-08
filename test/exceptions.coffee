################
## Exceptions ##
################

# shared nonce
nonce = {}

#### Throw

# basic exception throwing
throws (-> throw ->), ->
throws (-> throw new ->), ->

#### Empty Try/Catch/Finally

# try can exist alone
try

# try/catch with empty try, empty catch
try
  # nothing
catch err
  # nothing

# single-line try/catch with empty try, empty catch
try catch err

# try/finally with empty try, empty finally
try
  # nothing
finally
  # nothing

# single-line try/finally with empty try, empty finally
try finally

# try/catch/finally with empty try, empty catch, empty finally
try
catch err
finally

# single-line try/catch/finally with empty try, empty catch, empty finally
try catch err then finally


#### Try/Catch/Finally as an Expression

# return the result of try when no exception is thrown
result = try
  nonce
catch err
  undefined
finally
  undefined
eq nonce, result

# single-line result of try when no exception is thrown
result = try nonce catch err then undefined
eq nonce, result

# return the result of catch when an exception is thrown
result = try
  throw ->
catch err
  nonce
eq nonce, result

# single-line result of catch when an exception is thrown
result = try throw -> catch err then nonce
eq nonce, result

# optional catch
fn = ->
  try throw ->
  nonce
eq nonce, fn()


#### Try/Catch/Finally Interaction With Other Constructs

# try/catch with empty catch as last statement in a function body
func = ->
  try nonce
  catch err
ok func() is nonce
