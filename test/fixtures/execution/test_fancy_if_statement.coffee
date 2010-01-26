a: b: d: true
c: false

result: if a
  if b
    if c then false else
      if d
        true

print result


first: if false then false else second: if false then false else true

print first
print second