task 'test', 'run each of the unit tests', ->
  for test in testFiles
    fs.readFile test, (err, code) -> eval coffee.compile code
