# REPL
# ----

# TODO: add more tests

nexpect = require 'nexpect'

testCommands = (input, expectedOutput) ->
  input          = [input]          if typeof input is 'string'
  expectedOutput = [expectedOutput] if typeof expectedOutput is 'string'
  prompt         = "coffee>"

  repl = nexpect.spawn("bin/coffee", stripColors: true).expect prompt

  for i in [0..(input.length - 1)]
    repl.sendline input[i]
    repl.expect   expectedOutput[i]
    repl.expect   prompt

  repl.sendline("process.exit()").run (err) ->
    eq err, null, err

test "comments are ignored", ->
  testCommands "1 + 1 #foo", "2"

test "output in inspect mode", ->
  testCommands '"1 + 1\\n"', "'1 + 1\\n'"

test "variables are saved", ->
  input = [
    "foo = 'foo'"
    'foobar = "#{foo}bar"'
  ]
  testCommands input, [
    "'foo'"
    "'foobar'"
  ]
