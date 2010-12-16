# Conditionals
# ------------

# shared "identity" function
id = (_) -> _


#### Basic Conditionals

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


#### Interactions With Functions

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
  if trueFn undefined then a += 1
  eq 1, a


#### if-to-ternary

test "if-to-ternary with instanceof requires parentheses", ->
  nonce = {}
  eq nonce, (if {} instanceof Object
    nonce
  else
    undefined)

test "if-to-ternary as part of a larger operation requires parentheses", ->
  ok 2, 1 + if false then 0 else 1


#### Odd Formatting

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
