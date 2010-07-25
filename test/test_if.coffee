a = b = d = true
c = false

result = if a
  if b
    if c then false else
      if d
        true

ok result


first = if false then false else second = if false then false else true

ok first
ok second


result = if false
  false
else if NaN
  false
else
  true

ok result


# Testing unless.
result = unless true
  10
else
  11

ok result is 11


# Nested inline if statements.
echo = (x) -> x
result = if true then echo((if false then 'xxx' else 'y') + 'a')
ok result is 'ya'


# Testing inline funcs with inline if-elses.
func = -> if 1 < 0.5 then 1 else -1
ok func() is -1


# Testing empty or commented if statements ... should compile:
result = if false
else if false
else

ok result is undefined

result = if false
  # comment
else if true
  # comment
else

ok result is undefined


# Return an if with no else.
func = ->
  return (if false then callback())

ok func() is null


# If-to-ternary with instanceof requires parentheses (no comment).
if {} instanceof Object
  ok yes
else
  ok no
