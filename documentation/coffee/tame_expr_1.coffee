window.add = (a,b,cb) ->
  await setTimeout defer(), 10
  cb(a+b)
x = (await add 3, 4, defer _) + (await add 1, 2, defer _)
alert "#{x} is 10"
