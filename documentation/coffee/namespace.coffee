name = 'Outer'

do (name = 'Inner', somethingElse = undefined) ->
  # alerts 'Inner'
  alert(name)

# alerts 'Outer'
alert(name)