window.slowAlert = (w,s,cb) ->
  await setTimeout defer(), w
  alert s
  cb()
await
  slowAlert 500, "hello", defer()
  slowAlert 1000, "friend", defer()
await slowAlert 500, "back after a delay", defer()
