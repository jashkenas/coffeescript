# Exception Handling
# ------------------

# shared nonce
nonce = {}


# Throw

test "basic exception throwing", ->
  throws (-> throw 'error'), /^error$/


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

test "#1595: try/catch with a reused variable name", ->
  # `catch` shouldn’t lead to broken scoping.
  do ->
    try
      inner = 5
    catch inner
      # nothing
  eq typeof inner, 'undefined'

test "#2580: try/catch with destructuring the exception object", ->
  result = try
    missing.object
  catch {message}
    message

  eq message, 'missing is not defined'

test "Try catch finally as implicit arguments", ->
  first = (x) -> x

  foo = no
  try
    first try iamwhoiam() finally foo = yes
  catch e
  eq foo, yes

  bar = no
  try
    first try iamwhoiam() catch e finally
    bar = yes
  catch e
  eq bar, yes

test "#2900: parameter-less catch clause", ->
  # `catch` should not require a parameter.
  try
    throw new Error 'failed'
  catch
    ok true

  try throw new Error 'failed' catch finally ok true

  ok try throw new Error 'failed' catch then true

test "#3709: throwing an if statement", ->
  # `throw if` should return a closure around the `if` block, so that the
  # output is valid JavaScript.
  try
    throw if no
        new Error 'drat!'
      else
        new Error 'no escape!'
  catch err
    eq err.message, 'no escape!'

  try
    throw if yes then new Error 'huh?' else null
  catch err
    eq err.message, 'huh?'

test "#3709: throwing a switch statement", ->
  i = 3
  try
    throw switch i
      when 2
        new Error 'not this one'
      when 3
        new Error 'oh no!'
  catch err
    eq err.message, 'oh no!'

test "#3709: throwing a for loop", ->
  # `throw for` should return a closure around the `for` block, so that the
  # output is valid JavaScript.
  try
    throw for i in [0..3]
      i * 2
  catch err
    arrayEq err, [0, 2, 4, 6]

test "#3709: throwing a while loop", ->
  i = 0
  try
    throw while i < 3
      i++
  catch err
    eq i, 3

test "#3789: throwing a throw", ->
  try
    throw throw throw new Error 'whoa!'
  catch err
    eq err.message, 'whoa!'
