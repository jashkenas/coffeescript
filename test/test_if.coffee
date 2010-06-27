a: b: d: true
c: false

result: if a
  if b
    if c then false else
      if d
        true

ok result


first: if false then false else second: if false then false else true

ok first
ok second


result: if false
  false
else if NaN
  false
else
  true

ok result


# Testing unless.
result: unless true
  10
else
  11

ok result is 11


# Nested inline if statements.
echo: (x) -> x
result: if true then echo((if false then 'xxx' else 'y') + 'a')
ok result is 'ya'


# Testing inline funcs with inline if-elses.
func: -> if 1 < 0.5 then 1 else -1
ok func() is -1
