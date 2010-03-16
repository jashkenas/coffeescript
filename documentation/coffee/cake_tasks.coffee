task 'test', 'run each of the unit tests', ->
  for test in test_files
    fs.readFile test, (err, code) -> eval coffee.compile code
