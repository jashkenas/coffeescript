for i in [0..2]
  await
    slowAlert 100, "fast alert #{i}", defer()
    slowAlert 200, "slow alert #{i}", defer()

