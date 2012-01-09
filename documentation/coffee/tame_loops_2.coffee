await
  for i in [0..3]
    slowAlert 200, "loop iteration #{i}", defer()
