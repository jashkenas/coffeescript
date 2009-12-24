func: =>
  a: 3
  b: []
  while a >= 0
    b.push('o')
    a--.

  c: {
    text: b
  }

  c: 'error' unless 42 > 41

  c.text: if false
    'error'
  else
    c.text + '---'.

  c.list: let for let in c.text.split('') if let is '-'.

  c.single: c.list[1, 1][0].

print(func() == '-')
