# This is always fulfilled.
winLater = (val, ms) ->
  new Promise (resolve) -> setTimeout (-> resolve val), ms

# This is always rejected.
failLater = (val, ms) ->
  new Promise (resolve, reject) -> setTimeout (-> reject new Error val), ms

createAsyncIterable = (syncIterable) ->
  for elem in syncIterable
    yield await winLater elem, 50

test "async iteration", ->
  foo = (x for await x from createAsyncIterable [1,2,3])
  arrayEq foo, [1, 2, 3]

test "async generator functions", ->
  foo = (val) ->
    yield await winLater val + 1, 50

  bar = (val) ->
    yield await failLater val - 1, 50

  a = await foo(41).next()
  eq a.value, 42

  try
    b = do -> await bar(41).next()
    b.catch (err) ->
      eq "40", err.message
  catch err
    ok no
