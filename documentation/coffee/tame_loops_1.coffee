for i in [0..3]
  await slowAlert 200, "loop iteration #{i}", defer()
