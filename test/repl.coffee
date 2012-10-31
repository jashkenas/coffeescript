# REPL
# ----

# TODO: add more tests
{spawn} = require 'child_process'
PROMPT  = 'coffee> '

testOutput = (expected, actual) ->
  eq expected, actual.slice(0, expected.length)
  actual.substr expected.length

testCommands = (input, expectedOutput) ->
  input          = [input]          if typeof input is 'string'
  expectedOutput = [expectedOutput] if typeof expectedOutput is 'string'
  output         = ''
  coffee         = spawn 'bin/coffee'
  input.push 'process.exit()'

  coffee.stdout.on 'data', (data) ->
    output += data.toString().replace(/\u001b\[\d{0,2}m/g, '')
    coffee.stdin.write "#{input.shift()}\n"

  coffee.on 'exit', ->
    output = testOutput PROMPT, output
    while expectedOutput.length > 0
      output = testOutput "#{expectedOutput.shift()}\n#{PROMPT}", output
    eq '', output

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
