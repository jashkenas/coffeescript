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


# Ensure that trailing switch elses don't get rewritten.
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


# Should be able to handle switches sans-condition.
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


# Should be able to use "@properties" within the switch clause.
obj = {
  num: 101
  func: ->
    switch @num
      when 101 then '101!'
      else 'other'
}

ok obj.func() is '101!'


# Should be able to use "@properties" within the switch cases.
obj = {
  num: 101
  func: (yesOrNo) ->
    result = switch yesOrNo
      when yes then @num
      else 'other'
    result
}

ok obj.func(yes) is 101


# Switch with break as the return value of a loop.
i = 10
results = while i > 0
  i--
  switch i % 2
    when 1 then i
    when 0 then break

eq results.join(', '), '9, , 7, , 5, , 3, , 1, '
