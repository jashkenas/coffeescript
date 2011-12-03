
atest "basic tame waiting", (cb) ->
   i = 1
   await setTimeout(defer(), 10)
   i++
   cb(i == 2, {})

foo = (i, cb) ->
  await setTimeout(defer(), i);
  cb(i)

atest "basic tame waiting", (cb) ->
   i = 1
   await setTimeout(defer(), 10)
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


