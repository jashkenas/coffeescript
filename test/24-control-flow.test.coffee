# Test Control Flow

test "if-else chains", ->
  fn = (x) ->
    if x < 0
      'negative'
    else if x == 0
      'zero'
    else if x < 10
      'small'
    else
      'large'

  eq fn(-5), 'negative'
  eq fn(0), 'zero'
  eq fn(5), 'small'
  eq fn(15), 'large'

test "unless statement", ->
  x = 1
  y = 0
  unless x == 0
    y = 42
  eq y, 42

test "postfix if", ->
  x = 0
  x = 42 if true
  eq x, 42

  y = 0
  y = 100 if false
  eq y, 0

test "postfix unless", ->
  x = 0
  x = 42 unless false
  eq x, 42

test "ternary operator", ->
  x = true
  result = if x then 'yes' else 'no'
  eq result, 'yes'

test "switch with multiple values", ->
  fn = (x) ->
    switch x
      when 1, 2, 3 then 'small'
      when 4, 5, 6 then 'medium'
      else 'other'

  eq fn(2), 'small'
  eq fn(5), 'medium'
  eq fn(10), 'other'

test "switch with range-like conditions", ->
  # Note: Direct ranges in when clauses (when 1..3) are not supported
  # Use conditionals instead
  fn = (x) ->
    switch
      when x >= 1 and x <= 3 then 'small'
      when x >= 4 and x <= 6 then 'medium'
      else 'other'

  eq fn(2), 'small'
  eq fn(5), 'medium'

test "switch without value", ->
  x = 5
  result = switch
    when x < 0 then 'negative'
    when x == 0 then 'zero'
    when x < 10 then 'small'
    else 'large'
  eq result, 'small'

test "nested conditionals", ->
  fn = (x, y) ->
    if x > 0
      if y > 0
        'both positive'
      else
        'x positive'
    else
      'x not positive'

  eq fn(1, 1), 'both positive'
  eq fn(1, -1), 'x positive'
  eq fn(-1, 1), 'x not positive'

test "conditional assignment", ->
  x = null
  x ?= 42
  eq x, 42

  y = 10
  y ?= 100
  eq y, 10

test "conditional access", ->
  obj =
    prop: 42
  eq obj?.prop, 42
  eq obj?.missing, undefined
  eq null?.prop, undefined

test "loop control with break", ->
  sum = 0
  for i in [1, 2, 3, 4, 5]
    break if i > 3
    sum += i
  eq sum, 6

test "loop control with continue", ->
  sum = 0
  for i in [1, 2, 3, 4, 5]
    continue if i == 3
    sum += i
  eq sum, 12

test "try-catch-finally", ->
  fn = ->
    try
      throw new Error('test')
    catch e
      return 'caught'
    finally
      # finally always runs
  eq fn(), 'caught'

test "try without catch", ->
  x = 0
  try
    x = 42
  finally
    x += 1
  eq x, 43

test "conditional return", ->
  fn = (x) ->
    return 'early' if x < 0
    x * 2

  eq fn(-1), 'early'
  eq fn(5), 10

test "switch with break", ->
  fn = (x) ->
    result = []
    switch x
      when 1
        result.push 'one'
        break
      when 2
        result.push 'two'
    result

  arrayEq fn(1), ['one']

test "logical operators for control flow", ->
  x = null
  y = x || 42
  eq y, 42

  z = true && 'yes'
  eq z, 'yes'

test "guard clauses in comprehensions", ->
  result = []
  for x in [1, 2, 3, 4, 5]
    result.push(x) if x % 2 == 0
  ok result[0] == 2
  ok result[1] == 4
