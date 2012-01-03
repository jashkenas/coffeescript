# Exception Handling
# ------------------

# shared nonce
nonce = {}


# Throw

test "basic exception throwing", ->
  throws (-> throw 'error'), 'error'


# Empty Try/Catch/Finally

test "try can exist alone", ->
  try

test "try/catch with empty try, empty catch", ->
  try
    # nothing
  catch err
    # nothing

test "single-line try/catch with empty try, empty catch", ->
  try catch err

test "try/finally with empty try, empty finally", ->
  try
    # nothing
  finally
    # nothing

test "single-line try/finally with empty try, empty finally", ->
  try finally

test "try/catch/finally with empty try, empty catch, empty finally", ->
  try
  catch err
  finally

test "single-line try/catch/finally with empty try, empty catch, empty finally", ->
  try catch err then finally


# Try/Catch/Finally as an Expression

test "return the result of try when no exception is thrown", ->
  result = try
    nonce
  catch err
    undefined
  finally
    undefined
  eq nonce, result

test "single-line result of try when no exception is thrown", ->
  result = try nonce catch err then undefined
  eq nonce, result

test "return the result of catch when an exception is thrown", ->
  fn = ->
    try
      throw ->
    catch err
      nonce
  doesNotThrow fn
  eq nonce, fn()

test "single-line result of catch when an exception is thrown", ->
  fn = ->
    try throw (->) catch err then nonce
  doesNotThrow fn
  eq nonce, fn()

test "optional catch", ->
  fn = ->
    try throw ->
    nonce
  doesNotThrow fn
  eq nonce, fn()


# Try/Catch/Finally Interaction With Other Constructs

test "try/catch with empty catch as last statement in a function body", ->
  fn = ->
    try nonce
    catch err
  eq nonce, fn()


# Catch leads to broken scoping: #1595

test "try/catch with a reused variable name.", ->
  do ->
    try
      inner = 5
    catch inner
      # nothing
  eq typeof inner, 'undefined'

