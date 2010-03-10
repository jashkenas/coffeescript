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


# If statement with a comment-only clause.


result: if false
  # comment
else
  27

ok result is 27
