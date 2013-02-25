return if global.testingBrowser

# REPL
# ----
Stream = require 'stream'

class MockInputStream extends Stream
  constructor: ->
    @readable = true

  resume: ->

  emitLine: (val) ->
    @emit 'data', new Buffer("#{val}\n")

class MockOutputStream extends Stream
  constructor: ->
    @writable = true
    @written = []

  write: (data) ->
    #console.log 'output write', arguments
    @written.push data

  lastWrite: (fromEnd = -1) ->
    @written[@written.length - 1 + fromEnd].replace /\n$/, ''


testRepl = (desc, fn) ->
  input = new MockInputStream
  output = new MockOutputStream
  Repl.start {input, output}
  test desc, -> fn input, output

ctrlV = { ctrl: true, name: 'v'}


testRepl "starts with coffee prompt", (input, output) ->
  eq 'coffee> ', output.lastWrite(0)

testRepl "writes eval to output", (input, output) ->
  input.emitLine '1+1'
  eq '2', output.lastWrite()

testRepl "comments are ignored", (input, output) ->
  input.emitLine '1 + 1 #foo'
  eq '2', output.lastWrite()

testRepl "output in inspect mode", (input, output) ->
  input.emitLine '"1 + 1\\n"'
  eq "'1 + 1\\n'", output.lastWrite()

testRepl "variables are saved", (input, output) ->
  input.emitLine "foo = 'foo'"
  input.emitLine 'foobar = "#{foo}bar"'
  eq "'foobar'", output.lastWrite()

testRepl "empty command evaluates to undefined", (input, output) ->
  input.emitLine ''
  eq 'undefined', output.lastWrite()

testRepl "ctrl-v toggles multiline prompt", (input, output) ->
  input.emit 'keypress', null, ctrlV
  eq '------> ', output.lastWrite(0)
  input.emit 'keypress', null, ctrlV
  eq 'coffee> ', output.lastWrite(0)

testRepl "multiline continuation changes prompt", (input, output) ->
  input.emit 'keypress', null, ctrlV
  input.emitLine ''
  eq '....... ', output.lastWrite(0)

testRepl "evaluates multiline", (input, output) ->
  # Stubs. Could assert on their use.
  output.cursorTo = (pos) ->
  output.clearLine = ->

  input.emit 'keypress', null, ctrlV
  input.emitLine 'do ->'
  input.emitLine '  1 + 1'
  input.emit 'keypress', null, ctrlV
  eq '2', output.lastWrite()
