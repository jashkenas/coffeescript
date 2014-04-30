a = -> @html = 'Hello World!'; yield

b = -> 
  @html = 'Hello World!'
  yield

a = -> 
  @html = 'Hello World!'
  yield

b = -> loop yield 1

b = ->
  loop
    yield 1

b = ->
  x = yield 1 for i in [1..100]

f1 = ->

# f1 = -> yield from

# SHOULD RETURN AN EMPTY GENERATOR
f1 = -> yield

f1 = -> 
  alert null
  yield

f1 = -> alert null; yield

# SHOULD ERROR (non-terminating yield without identifier)
# f11 = -> yield; return

# TODO: FIX
# SHOULD RETURN AN EMPTY GENERATOR
f1point5 = ->
  yield

f = (num) ->
  for item in [1...10]
    if item > 5 then return else yield num

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

