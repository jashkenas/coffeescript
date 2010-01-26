# Everything should be able to be an expression.

result: while sunny?
  go_outside()

print(3 + try
  nonexistent.no_way
catch error
  print(error)
  3
)

func: (x) ->
  return throw x

print(x * x for x in [1..100])