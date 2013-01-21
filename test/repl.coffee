# REPL
# ----
Stream = require 'stream'

class MockInputStream extends Stream
  constructor: () ->
    @readable = true

  resume: ->

  emitLine: (val) ->
    @emit 'data', new Buffer("#{val}\n")

class MockOutputStream extends Stream
  constructor: () ->
    @writable = true
    @written = []

  write: (data) ->
    #console.log 'output write', arguments
    @written.push data

  lastWrite: (fromEnd=-1) ->
    @written[@written.length - 1 + fromEnd].replace /\n$/, ''

testRepl = (desc, fn) ->
  input = new MockInputStream()
  output = new MockOutputStream()
  Repl.start {input, output}
  fn input, output

assertEqual = (expected, value) ->
  eq expected, value, "Expected '#{value}' to equal '#{expected}'"


testRepl "starts with coffee prompt", (input, output) ->
  assertEqual 'coffee> ', output.lastWrite(0)

testRepl "writes eval to output", (input, output) ->
  input.emitLine '1+1'
  assertEqual '2', output.lastWrite()

testRepl "comments are ignored", (input, output) ->
  input.emitLine '1 + 1 #foo'
  assertEqual '2', output.lastWrite()

testRepl "output in inspect mode", (input, output) ->
  input.emitLine '"1 + 1\\n"'
  assertEqual "'1 + 1\\n'", output.lastWrite()

testRepl "variables are saved", (input, output) ->
  input.emitLine "foo = 'foo'"
  input.emitLine 'foobar = "#{foo}bar"'
  assertEqual "'foobar'", output.lastWrite()

testRepl "empty command evaluates to undefined", (input, output) ->
  input.emitLine ''
  assertEqual 'undefined', output.lastWrite()

ctrlV = { ctrl: true, name: 'v'}
testRepl "ctrl-v toggles multiline prompt", (input, output) ->
  input.emit 'keypress', null, ctrlV
  assertEqual '------> ', output.lastWrite(0)
  input.emit 'keypress', null, ctrlV
  assertEqual 'coffee> ', output.lastWrite(0)

testRepl "multiline continuation changes prompt", (input, output) ->
  input.emit 'keypress', null, ctrlV
  input.emitLine ''
  assertEqual '....... ', output.lastWrite(0)

testRepl "evaluates multiline", (input, output) ->
  # Stubs. Could assert on their use.
  output.cursorTo = (pos) ->
  output.clearLine = ->

  input.emit 'keypress', null, ctrlV
  input.emitLine '(->'
  input.emitLine '  1 + 1'
  input.emitLine ')()'
  input.emit 'keypress', null, ctrlV
  assertEqual '2', output.lastWrite()
