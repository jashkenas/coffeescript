# Expression conversion under explicit returns.
first = ->
  return ('do' for x in [1,2,3])

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

eq func(), 42

# Ensure that we don't wrap Nodes that are "pureStatement" in a closure.
items = [1, 2, 3, "bacon", 4, 5]

findit = (items) ->
  for item in items
    return item if item is "bacon"

ok findit(items) is "bacon"


# When a closure wrapper is generated for expression conversion, make sure
# that references to "this" within the wrapper are safely converted as well.
obj =
  num: 5
  func: ->
    this.result = if false
      10
    else
      "a"
      "b"
      this.num

eq obj.num, obj.func()
eq obj.num, obj.result


# Multiple semicolon-separated statements in parentheticals.
eq 3, (1; 2; 3)
eq 3, (-> return (1; 2; 3))()
