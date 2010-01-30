a: b: d: true
c: false

result: if a
  if b
    if c then false else
      if d
        true

puts result


first: if false then false else second: if false then false else true

puts first
puts second