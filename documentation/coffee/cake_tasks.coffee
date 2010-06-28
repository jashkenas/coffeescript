task 'test', 'run each of the unit tests', ->
  for test in files
    fs.readFile test, (err, code) -> eval coffee.compile code
