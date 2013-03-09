# Control Flow
# ------------

# * Conditionals
# * Loops
#   * For
#   * While
#   * Until
#   * Loop
# * Switch
# * Throw

# TODO: make sure postfix forms and expression coercion are properly tested

# shared identity function
id = (_) -> if arguments.length is 1 then _ else Array::slice.call(arguments)

# Conditionals

test "basic conditionals", ->
  if false
    ok false
  else if false
    ok false
  else
    ok true

  if true
    ok true
  else if true
    ok false
  else
    ok true

  unless true
    ok false
  else unless true
    ok false
  else
    ok true

  unless false
    ok true
  else unless false
    ok false
  else
    ok true

test "single-line conditional", ->
  if false then ok false else ok true
  unless false then ok true else ok false

test "nested conditionals", ->
  nonce = {}
  eq nonce, (if true
    unless false
      if false then false else
        if true
          nonce)

test "nested single-line conditionals", ->
  nonce = {}

  a = if false then undefined else b = if 0 then undefined else nonce
  eq nonce, a
  eq nonce, b

  c = if false then undefined else (if 0 then undefined else nonce)
  eq nonce, c

  d = if true then id(if false then undefined else nonce)
  eq nonce, d

test "empty conditional bodies", ->
  eq undefined, (if false
  else if false
  else)

test "conditional bodies containing only comments", ->
  eq undefined, (if true
    ###
    block comment
    ###
  else
    # comment
  )

  eq undefined, (if false
    # comment
  else if true
    ###
    block comment
    ###
  else)

test "return value of if-else is from the proper body", ->
  nonce = {}
  eq nonce, if false then undefined else nonce

test "return value of unless-else is from the proper body", ->
  nonce = {}
  eq nonce, unless true then undefined else nonce

test "assign inside the condition of a conditional statement", ->
  nonce = {}
  if a = nonce then 1
  eq nonce, a
  1 if b = nonce
  eq nonce, b


# Interactions With Functions

test "single-line function definition with single-line conditional", ->
  fn = -> if 1 < 0.5 then 1 else -1
  ok fn() is -1

test "function resturns conditional value with no `else`", ->
  fn = ->
    return if false then true
  eq undefined, fn()

test "function returns a conditional value", ->
  a = {}
  fnA = ->
    return if false then undefined else a
  eq a, fnA()

  b = {}
  fnB = ->
    return unless false then b else undefined
  eq b, fnB()

test "passing a conditional value to a function", ->
  nonce = {}
  eq nonce, id if false then undefined else nonce

test "unmatched `then` should catch implicit calls", ->
  a = 0
  trueFn = -> true
  if trueFn undefined then a++
  eq 1, a


# if-to-ternary

test "if-to-ternary with instanceof requires parentheses", ->
  nonce = {}
  eq nonce, (if {} instanceof Object
    nonce
  else
    undefined)

test "if-to-ternary as part of a larger operation requires parentheses", ->
  ok 2, 1 + if false then 0 else 1


# Odd Formatting

test "if-else indented within an assignment", ->
  nonce = {}
  result =
    if false
      undefined
    else
      nonce
  eq nonce, result

test "suppressed indentation via assignment", ->
  nonce = {}
  result =
    if      false then undefined
    else if no    then undefined
    else if 0     then undefined
    else if 1 < 0 then undefined
    else               id(
         if false then undefined
         else          nonce
    )
  eq nonce, result

test "tight formatting with leading `then`", ->
  nonce = {}
  eq nonce,
  if true
  then nonce
  else undefined

test "#738", ->
  nonce = {}
  fn = if true then -> nonce
  eq nonce, fn()

test "#748: trailing reserved identifiers", ->
  nonce = {}
  obj = delete: true
  result = if obj.delete
    nonce
  eq nonce, result


test "basic `while` loops", ->

  i = 5
  list = while i -= 1
    i * 2
  ok list.join(' ') is "8 6 4 2"

  i = 5
  list = (i * 3 while i -= 1)
  ok list.join(' ') is "12 9 6 3"

  i = 5
  func   = (num) -> i -= num
  assert = -> ok i < 5 > 0
  results = while func 1
    assert()
    i
  ok results.join(' ') is '4 3 2 1'

  i = 10
  results = while i -= 1 when i % 2 is 0
    i * 2
  ok results.join(' ') is '16 12 8 4'


test "Issue 759: `if` within `while` condition", ->

  2 while if 1 then 0


test "assignment inside the condition of a `while` loop", ->

  nonce = {}
  count = 1
  a = nonce while count--
  eq nonce, a
  count = 1
  while count--
    b = nonce
  eq nonce, b


test "While over break.", ->

  i = 0
  result = while i < 10
    i++
    break
  arrayEq result, []


test "While over continue.", ->

  i = 0
  result = while i < 10
    i++
    continue
  arrayEq result, []


test "Basic `until`", ->

  value = false
  i = 0
  results = until value
    value = true if i is 5
    i++
  ok i is 6


test "Basic `loop`", ->

  i = 5
  list = []
  loop
    i -= 1
    break if i is 0
    list.push i * 2
  ok list.join(' ') is '8 6 4 2'


test "break at the top level", ->
  for i in [1,2,3]
    result = i
    if i == 2
      break
  eq 2, result

test "break *not* at the top level", ->
  someFunc = ->
    i = 0
    while ++i < 3
      result = i
      break if i > 1
    result
  eq 2, someFunc()


test "basic `switch`", ->

  num = 10
  result = switch num
    when 5 then false
    when 'a'
      true
      true
      false
    when 10 then true


    # Mid-switch comment with whitespace
    # and multi line
    when 11 then false
    else false

  ok result


  func = (num) ->
    switch num
      when 2, 4, 6
        true
      when 1, 3, 5
        false

  ok func(2)
  ok func(6)
  ok !func(3)
  eq func(8), undefined


test "Ensure that trailing switch elses don't get rewritten.", ->

  result = false
  switch "word"
    when "one thing"
      doSomething()
    else
      result = true unless false

  ok result

  result = false
  switch "word"
    when "one thing"
      doSomething()
    when "other thing"
      doSomething()
    else
      result = true unless false

  ok result


test "Should be able to handle switches sans-condition.", ->

  result = switch
    when null                     then 0
    when !1                       then 1
    when '' not of {''}           then 2
    when [] not instanceof Array  then 3
    when true is false            then 4
    when 'x' < 'y' > 'z'          then 5
    when 'a' in ['b', 'c']        then 6
    when 'd' in (['e', 'f'])      then 7
    else ok

  eq result, ok


test "Should be able to use `@properties` within the switch clause.", ->

  obj = {
    num: 101
    func: ->
      switch @num
        when 101 then '101!'
        else 'other'
  }

  ok obj.func() is '101!'


test "Should be able to use `@properties` within the switch cases.", ->

  obj = {
    num: 101
    func: (yesOrNo) ->
      result = switch yesOrNo
        when yes then @num
        else 'other'
      result
  }

  ok obj.func(yes) is 101


test "Switch with break as the return value of a loop.", ->

  i = 10
  results = while i > 0
    i--
    switch i % 2
      when 1 then i
      when 0 then break

  eq results.join(', '), '9, 7, 5, 3, 1'


test "Issue #997. Switch doesn't fallthrough.", ->

  val = 1
  switch true
    when true
      if false
        return 5
    else
      val = 2

  eq val, 1


test "Throw should be usable as an expression.", ->
  try
    false or throw 'up'
    throw new Error 'failed'
  catch e
    ok e is 'up'
