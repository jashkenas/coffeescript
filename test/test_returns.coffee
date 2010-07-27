# Expression conversion under explicit returns.
first = ->
  return 'do' for x in [1,2,3]

second = ->
  return ['re' for x in [1,2,3]]

third = ->
  return ('mi' for x in [1,2,3])

ok first().join(' ')     is 'do do do'
ok second()[0].join(' ') is 're re re'
ok third().join(' ')     is 'mi mi mi'


# Testing returns with multiple branches.
func = ->
  if false
    for a in b
      return c if d
  else
    "word"

ok func() is 'word'


# And with switches.
func = ->
  switch 'a'
    when 'a' then 42
    else return 23

ok func() is 42