# SHOULD RETURN AN EMPTY GENERATOR
# f1 = -> yield

# SHOULD ERROR (non-terminating yield without identifier)
# f11 = -> yield; return

# TODO: FIX
# SHOULD RETURN AN EMPTY GENERATOR
# f1point5 = ->
#   yield

f2 = -> yield 1

f21 = ->
  yield 1
  return

f3 = (arg1, arg2) ->
  for i in [arg1..arg2]
    yield i

f3 = (arg1, arg2) ->
  for i in [arg1..arg2]
    yield null
  return 1

# alternatively...

f3 = (arg1, arg2) ->
  yield i for i in [arg1..arg2]
  return 1

f4 = (arg1, arg2) ->
  for i in [arg1..arg2]
    if (x = yield i) is 7 
      return
  return 1
  
# alternatively...

f4 = (arg1, arg2) ->
  for i in [arg1..arg2]
    return if (x = yield i) is 7 
  return 1

