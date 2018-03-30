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

test "#738: inline function defintion", ->
  nonce = {}
  fn = if true then -> nonce
  eq nonce, fn()

test "#748: trailing reserved identifiers", ->
  nonce = {}
  obj = delete: true
  result = if obj.delete
    nonce
  eq nonce, result

test 'if-else within an assignment, condition parenthesized', ->
  result = if (1 is 1) then 'correct'
  eq result, 'correct'

  result = if ('whatever' ? no) then 'correct'
  eq result, 'correct'

  f = -> 'wrong'
  result = if (f?()) then 'correct' else 'wrong'
  eq result, 'correct'

# Postfix

test "#3056: multiple postfix conditionals", ->
  temp = 'initial'
  temp = 'ignored' unless true if false
  eq temp, 'initial'

# Loops

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

# Switch

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

# Throw

test "Throw should be usable as an expression.", ->
  try
    false or throw 'up'
    throw new Error 'failed'
  catch e
    ok e is 'up'


test "#2555, strange function if bodies", ->
  success = -> ok true
  failure = -> ok false

  success() if do ->
    yes

  failure() if try
    false

test "#1057: `catch` or `finally` in single-line functions", ->
  ok do -> try throw 'up' catch then yes
  ok do -> try yes finally 'nothing'

test "#2367: super in for-loop", ->
  class Foo
    sum: 0
    add: (val) -> @sum += val

  class Bar extends Foo
    add: (vals...) ->
      super val for val in vals
      @sum

  eq 10, (new Bar).add 2, 3, 5

test "#4267: lots of for-loops in the same scope", ->
  # This used to include the invalid JavaScript `var do = 0`.
  code = """
    do ->
      #{Array(200).join('for [0..0] then\n  ')}
      true
  """
  ok CoffeeScript.eval(code)

# Test for issue #2342: Lexer: Inline `else` binds to wrong `if`/`switch`
test "#2343: if / then / if / then / else", ->
  a = b = yes
  c = e = g = no
  d = 1
  f = 2
  h = 3
  i = 4

  s = ->
    if a
      if b
        if c
          d
        else
          if e
            f
          else
            if g
              h
            else
              i

  t = ->
    if a then if b
      if c then d
      else if e
        f
      else if g
        h
      else
        i

  u = ->
    if a then if b
      if c then d else if e
        f
      else if g
        h
      else i

  v = ->
    if a then if b
      if c then d else if e then f
      else if g then h
      else i

  w = ->
    if a then if b
      if c then d
      else if e
          f
        else
          if g then h
          else i

  x = -> if a then if b then if c then d else if e then f else if g then h else i

  y = -> if a then if b then (if c then d else (if e then f else (if g then h else i)))

  eq 4, s()
  eq 4, t()
  eq 4, u()
  eq 4, v()
  eq 4, w()
  eq 4, x()
  eq 4, y()

  c = yes
  eq 1, s()
  eq 1, t()
  eq 1, u()
  eq 1, v()
  eq 1, w()
  eq 1, x()
  eq 1, y()

  b = no
  eq undefined, s()
  eq undefined, t()
  eq undefined, u()
  eq undefined, v()
  eq undefined, w()
  eq undefined, x()
  eq undefined, y()

test "#2343: if / then / if / then / else / else", ->
  a = b = yes
  c = e = g = no
  d = 1
  f = 2
  h = 3
  i = 4
  j = 5
  k = 6

  s = ->
    if a
      if b
        if c
          d
        else
          e
          if e
            f
          else
            if g
              h
            else
              i
      else
        j
    else
      k

  t = ->
    if a
      if b
        if c then d
        else if e
          f
        else if g
          h
        else
          i
      else
        j
    else
      k

  u = ->
    if a
      if b
        if c then d else if e
          f
        else if g
          h
        else i
      else j
    else k

  v = ->
    if a
      if b
        if c then d else if e then f
        else if g then h
        else i
      else j else k

  w = ->
    if a then if b
        if c then d
        else if e
            f
          else
            if g then h
            else i
    else j else k

  x = -> if a then if b then if c then d else if e then f else if g then h else i else j else k

  y = -> if a then (if b then (if c then d else (if e then f else (if g then h else i))) else j) else k

  eq 4, s()
  eq 4, t()
  eq 4, u()
  eq 4, v()
  eq 4, w()
  eq 4, x()
  eq 4, y()

  c = yes
  eq 1, s()
  eq 1, t()
  eq 1, u()
  eq 1, v()
  eq 1, w()
  eq 1, x()
  eq 1, y()

  b = no
  eq 5, s()
  eq 5, t()
  eq 5, u()
  eq 5, v()
  eq 5, w()
  eq 5, x()
  eq 5, y()

  a = no
  eq 6, s()
  eq 6, t()
  eq 6, u()
  eq 6, v()
  eq 6, w()
  eq 6, x()
  eq 6, y()


test "#2343: switch / when / then / if / then / else", ->
  a = b = yes
  c = e = g = no
  d = 1
  f = 2
  h = 3
  i = 4

  s = ->
    switch
      when a
        if b
          if c
            d
          else
            if e
              f
            else
              if g
                h
              else
                i


  t = ->
    switch
      when a then if b
        if c then d
        else if e
          f
        else if g
          h
        else
          i

  u = ->
    switch
      when a then if b then if c then d
      else if e then f
      else if g then h else i

  v = ->
    switch
      when a then if b then if c then d else if e then f
      else if g then h else i

  w = ->
    switch
      when a then if b then if c then d else if e then f
      else if g
        h
      else i

  x = ->
    switch
     when a then if b then if c then d else if e then f else if g then h else i

  y = -> switch
    when a then if b then (if c then d else (if e then f else (if g then h else i)))

  eq 4, s()
  eq 4, t()
  eq 4, u()
  eq 4, v()
  eq 4, w()
  eq 4, x()
  eq 4, y()

  c = yes
  eq 1, s()
  eq 1, t()
  eq 1, u()
  eq 1, v()
  eq 1, w()
  eq 1, x()
  eq 1, y()

  b = no
  eq undefined, s()
  eq undefined, t()
  eq undefined, u()
  eq undefined, v()
  eq undefined, w()
  eq undefined, x()
  eq undefined, y()

test "#2343: switch / when / then / if / then / else / else", ->
  a = b = yes
  c = e = g = no
  d = 1
  f = 2
  h = 3
  i = 4

  s = ->
    switch
      when a
        if b
          if c
            d
          else if e
            f
          else if g
            h
          else
            i
      else
        0

  t = ->
    switch
      when a
        if b
          if c then d
          else if e
            f
          else if g
            h
          else i
      else 0

  u = ->
    switch
      when a
        if b then if c
            d
          else if e
            f
          else if g
            h
          else i
      else 0

  v = ->
    switch
      when a
        if b then if c then d
        else if e
          f
        else if g
          h
        else i
      else 0

  w = ->
    switch
      when a
        if b then if c then d
        else if e then f
        else if g then h
        else i
      else 0

  x = ->
    switch
     when a
       if b then if c then d else if e then f else if g then h else i
     else 0

  y = -> switch
    when a
      if b then (if c then d else (if e then f else (if g then h else i)))
    else 0

  eq 4, s()
  eq 4, t()
  eq 4, u()
  eq 4, v()
  eq 4, w()
  eq 4, x()
  eq 4, y()

  c = yes
  eq 1, s()
  eq 1, t()
  eq 1, u()
  eq 1, v()
  eq 1, w()
  eq 1, x()
  eq 1, y()

  b = no
  eq undefined, s()
  eq undefined, t()
  eq undefined, u()
  eq undefined, v()
  eq undefined, w()
  eq undefined, x()
  eq undefined, y()

  b = yes
  a = no
  eq 0, s()
  eq 0, t()
  eq 0, u()
  eq 0, v()
  eq 0, w()
  eq 0, x()
  eq 0, y()

test "#2343: switch / when / then / if / then / else / else / else", ->
  a = b = yes
  c = e = g = no
  d = 1
  f = 2
  h = 3
  i = 4
  j = 5

  s = ->
    switch
      when a
        if b
          if c
            d
          else if e
            f
          else if g
            h
          else
            i
        else
          j
      else
        0

  t = ->
    switch
      when a
        if b
          if c then d
          else if e
            f
          else if g
            h
          else i
        else
          j
      else 0

  u = ->
    switch
      when a
        if b
          if c
            d
          else if e
            f
          else if g
            h
          else i
        else j
      else 0

  v = ->
    switch
      when a
        if b
          if c then d
          else if e
            f
          else if g then h
          else i
        else j
      else 0

  w = ->
    switch
      when a
        if b
          if c then d
          else if e then f
          else if g then h
          else i
        else j
      else 0

  x = ->
    switch
     when a
       if b then if c then d else if e then f else if g then h else i else j
     else 0

  y = -> switch
    when a
      if b then (if c then d else (if e then f else (if g then h else i))) else j
    else 0

  eq 4, s()
  eq 4, t()
  eq 4, u()
  eq 4, v()
  eq 4, w()
  eq 4, x()
  eq 4, y()

  c = yes
  eq 1, s()
  eq 1, t()
  eq 1, u()
  eq 1, v()
  eq 1, w()
  eq 1, x()
  eq 1, y()

  b = no
  eq 5, s()
  eq 5, t()
  eq 5, u()
  eq 5, v()
  eq 5, w()
  eq 5, x()
  eq 5, y()

  b = yes
  a = no
  eq 0, s()
  eq 0, t()
  eq 0, u()
  eq 0, v()
  eq 0, w()
  eq 0, x()
  eq 0, y()

# Test for issue #3921: Inline function without parentheses used in condition fails to compile
test "#3921: `if` & `unless`", ->
  a = {}
  eq a, if do -> no then undefined else a
  a1 = undefined
  if do -> yes
    a1 = a
  eq a, a1

  b = {}
  eq b, unless do -> no then b else undefined
  b1 = undefined
  unless do -> no
    b1 = b
  eq b, b1

  c = 0
  if (arg = undefined) -> yes then c++
  eq 1, c
  d = 0
  if (arg = undefined) -> yes
    d++
  eq 1, d

  answer = 'correct'
  eq answer, if do -> 'wrong' then 'correct' else 'wrong'
  eq answer, unless do -> no then 'correct' else 'wrong'
  statm1 = undefined
  if do -> 'wrong'
    statm1 = 'correct'
  eq answer, statm1
  statm2 = undefined
  unless do -> no
    statm2 = 'correct'
  eq answer, statm2

test "#3921: `post if`", ->
  a = {}
  eq a, a unless do -> no
  a1 = a if do -> yes
  eq a, a1

  c = 0
  c++ if (arg = undefined) -> yes
  eq 1, c
  d = 0
  d++ if (arg = undefined) -> yes
  eq 1, d

  answer = 'correct'
  eq answer, 'correct' if do -> 'wrong'
  eq answer, 'correct' unless do -> not 'wrong'
  statm1 = undefined
  statm1 = 'correct' if do -> 'wrong'
  eq answer, statm1
  statm2 = undefined
  statm2 = 'correct' unless do -> not 'wrong'
  eq answer, statm2

test "Issue 3921: `while` & `until`", ->
  i = 5
  assert = (a) -> ok 5 > a > 0
  result1 = while do (num = 1) -> i -= num
    assert i
    i
  ok result1.join(' ') is '4 3 2 1'

  j = 5
  result2 = until do (num = 1) -> (j -= num) < 1
    assert j
    j
  ok result2.join(' ') is '4 3 2 1'

test "#3921: `switch`", ->
  i = 1
  a = switch do (m = 2) -> i * m
    when 5 then "five"
    when 4 then "four"
    when 3 then "three"
    when 2 then "two"
    when 1 then "one"
    else "none"
  eq "two", a

  j = 12
  b = switch do (m = 3) -> j / m
    when 5 then "five"
    when 4 then "four"
    when 3 then "three"
    when 2 then "two"
    when 1 then "one"
    else "none"
  eq "four", b

  k = 20
  c = switch do (m = 4) -> k / m
    when 5 then "five"
    when 4 then "four"
    when 3 then "three"
    when 2 then "two"
    when 1 then "one"
    else "none"
  eq "five", c

# Issue #3909: backslash to break line in `for` loops throw syntax error
test "#3909: backslash `for own ... of`", ->

  obj = {a: 1, b: 2, c: 3}
  arr = ['a', 'b', 'c']

  x1 \
    = ( key for own key of obj )
  arrayEq x1, arr

  x2 = \
    ( key for own key of obj )
  arrayEq x2, arr

  x3 = ( \
    key for own key of obj )
  arrayEq x3, arr

  x4 = ( key \
    for own key of obj )
  arrayEq x4, arr

  x5 = ( key for own key of \
    obj )
  arrayEq x5, arr

  x6 = ( key for own key of obj \
    )
  arrayEq x6, arr

  x7 = ( key for \
    own key of obj )
  arrayEq x7, arr

  x8 = ( key for own \
    key of obj )
  arrayEq x8, arr

  x9 = ( key for own key \
    of obj )
  arrayEq x9, arr


test "#3909: backslash `for ... of`", ->
  obj = {a: 1, b: 2, c: 3}
  arr = ['a', 'b', 'c']

  x1 \
    = ( key for key of obj )
  arrayEq x1, arr

  x2 = \
    ( key for key of obj )
  arrayEq x2, arr

  x3 = ( \
    key for key of obj )
  arrayEq x3, arr

  x4 = ( key \
    for key of obj )
  arrayEq x4, arr

  x5 = ( key for key of \
    obj )
  arrayEq x5, arr

  x6 = ( key for key of obj \
    )
  arrayEq x6, arr

  x7 = ( key for \
    key of obj )
  arrayEq x7, arr

  x8 = ( key for key \
    of obj )
  arrayEq x8, arr


test "#3909: backslash `for ... in`", ->
  arr = ['a', 'b', 'c']

  x1 \
    = ( key for key in arr )
  arrayEq x1, arr

  x2 = \
    ( key for key in arr )
  arrayEq x2, arr

  x3 = ( \
    key for key in arr )
  arrayEq x3, arr

  x4 = ( key \
    for key in arr )
  arrayEq x4, arr

  x5 = ( key for key in \
    arr )
  arrayEq x5, arr

  x6 = ( key for key in arr \
    )
  arrayEq x6, arr

  x7 = ( key for \
    key in arr )
  arrayEq x7, arr

  x8 = ( key for key \
    in arr )
  arrayEq x8, arr

test "#4871: `else if` no longer output together ", ->
   eqJS '''
   if a then b else if c then d else if e then f else g
   ''',
   '''
   if (a) {
     b;
   } else if (c) {
     d;
   } else if (e) {
     f;
   } else {
     g;
   }
   '''

   eqJS '''
   if no
     1
   else if yes
     2
   ''',
   '''
   if (false) {
     1;
   } else if (true) {
     2;
   }
   '''

test "#4898: Lexer: backslash line continuation is inconsistent", ->
  if ( \
      false \
      or \
      true \
    )
    a = 42

  eq a, 42

  if ( \
      false \
      or \
      true \
  )
    b = 42

  eq b, 42

  if ( \
            false \
         or \
   true \
  )
    c = 42

  eq c, 42

  if \
   false \
        or \
   true
    d = 42

  eq d, 42

  if \
              false or \
  true
    e = 42

  eq e, 42

  if \
       false or \
    true \
       then \
   f = 42 \
   else
     f = 24

  eq f, 42
