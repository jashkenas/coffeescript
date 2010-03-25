first: ->
  return 'do' for x in [1,2,3]

second: ->
  return ['re' for x in [1,2,3]]

third: ->
  return ('mi' for x in [1,2,3])

ok first().join(' ')     is 'do do do'
ok second()[0].join(' ') is 're re re'
ok third().join(' ')     is 'mi mi mi'