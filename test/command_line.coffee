# Command line tool
# -----------------

test "child_process.fork works properly when run via coffee", ->
  child = require('child_process').spawn "#{__dirname}/../bin/coffee", [
    "#{__dirname}/sample_files/forking_test_file.coffee"
  ]
  child.on 'exit', (code) ->
    eq 0, code
