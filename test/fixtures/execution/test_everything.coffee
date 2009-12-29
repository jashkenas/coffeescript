func: =>
  a: 3
  b: []

  while a >= 0
    b.push('o')
    a--

  c: {
    "text": b
  }

  c: 'error' unless 42 > 41

  c.text: if false
    'error'
  else
    c.text + '---'

  d = {
    text = c.text
  }

  c.list: l for l in d.text.split('') when l is '-'

  c.single: c.list[1..1][0]

print(func() == '-')
