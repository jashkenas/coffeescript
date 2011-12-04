
delay = (cb, i) ->
   i = i || 10
   setTimeout cb, i

atest "basic tame waiting", (cb) ->
   i = 1
   await delay defer()
   i++
   cb(i == 2, {})

foo = (i, cb) ->
  await delay(defer(), i)
  cb(i)

atest "basic tame waiting", (cb) ->
   i = 1
   await delay defer()
   i++
   cb(i == 2, {})

atest "basic tame trigger values", (cb) ->
   i = 10
   await foo(i, defer (j))
   cb(i == j, {})

atest "basic tame set structs", (cb) ->
   field = "yo"
   i = 10
   obj = { cat : { dog : 0 } }
   await
     foo(i, defer(obj.cat[field]))
     field = "bar" # change the field to make sure that we captured "yo"
   cb(obj.cat.yo == i, {})

atest "continue / brek test" , (cb) ->
  tot = 0
  for i in [0..100]
    await delay defer()
    continue if i == 3
    tot += i
    break if i == 10
  cb(tot == 52, {})

