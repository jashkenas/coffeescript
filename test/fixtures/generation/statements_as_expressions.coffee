# Everything should be able to be an expression.

result: while sunny?
  go_outside()

puts(3 + try
  nonexistent.no_way
catch error
  puts(error)
  3
)

func: (x) ->
  return throw x

puts(x * x for x in [1..100])