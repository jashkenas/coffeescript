num: 10

result: switch num
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


func: (num) ->
  switch num
    when 2, 4, 6
      true
    when 1, 3, 5
      false
    else false

ok func(2)
ok func(6)
ok !func(3)
ok !func(8)


# Should cache the switch value, if anything fancier than a literal.
num: 5
result: switch num: + 5
  when 5 then false
  when 15 then false
  when 10 then true
  else false

ok result


# Ensure that trailing switch elses don't get rewritten.
result: false
switch "word"
  when "one thing"
    do_something()
  else
    result: true unless false

ok result

result: false
switch "word"
  when "one thing"
    do_something()
  when "other thing"
    do_something()
  else
    result: true unless false

ok result


# Should be able to handle switches sans-condition.
result: switch
  when null then 1
  when 'truthful string' then 2
  else 3

ok result is 2
