return if global.testingBrowser

os = require 'os'
fs = require 'fs'
path = require 'path'

# REPL
# ----
Stream = require 'stream'

class MockInputStream extends Stream
  constructor: ->
    super()
    @readable = true

  resume: ->

  emitLine: (val) ->
    @emit 'data', Buffer.from("#{val}\n")

class MockOutputStream extends Stream
  constructor: ->
    super()
    @writable = true
    @written = []

  write: (data) ->
    # console.log 'output write', arguments
    @written.push data

  lastWrite: (fromEnd = -1) ->
    @written[@written.length - 1 + fromEnd].replace /\r?\n$/, ''

# Create a dummy history file
historyFile = path.join os.tmpdir(), '.coffee_history_test'
fs.writeFileSync historyFile, '1 + 2\n'

testRepl = (desc, fn) ->
  input = new MockInputStream
  output = new MockOutputStream
  repl = Repl.start {input, output, historyFile}
  test desc, -> fn input, output, repl

ctrlV = { ctrl: true, name: 'v'}


testRepl 'reads history file', (input, output, repl) ->
  input.emitLine repl.rli.history[0]
  eq '3', output.lastWrite()

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
  # A regression fixed in Node 5.11.0 broke the handling of pressing enter in
  # the Node REPL; see https://github.com/nodejs/node/pull/6090 and
  # https://github.com/jashkenas/coffeescript/issues/4502.
  # Just skip this test for versions of Node < 6.
  return if parseInt(process.versions.node.split('.')[0], 10) < 6
  input.emitLine ''
  eq 'undefined', output.lastWrite()

testRepl "#4763: comment evaluates to undefined", (input, output) ->
  input.emitLine '# comment'
  eq 'undefined', output.lastWrite()

testRepl "#4763: multiple comments evaluate to undefined", (input, output) ->
  input.emitLine '### a ### ### b ### # c'
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

testRepl "variables in scope are preserved", (input, output) ->
  input.emitLine 'a = 1'
  input.emitLine 'do -> a = 2'
  input.emitLine 'a'
  eq '2', output.lastWrite()

testRepl "existential assignment of previously declared variable", (input, output) ->
  input.emitLine 'a = null'
  input.emitLine 'a ?= 42'
  eq '42', output.lastWrite()

testRepl "keeps running after runtime error", (input, output) ->
  input.emitLine 'a = b'
  input.emitLine 'a'
  eq 'undefined', output.lastWrite()

testRepl "#4604: wraps an async function", (input, output) ->
  return unless try new Function 'async () => {}' # Feature detect support for async functions.
  input.emitLine 'await new Promise (resolve) -> setTimeout (-> resolve 33), 10'
  setTimeout ->
    eq '33', output.lastWrite()
  , 20

testRepl "transpile REPL", (input, output) ->
  input.emitLine 'require("./test/importing/transpile_import").getSep()'
  eq "'#{path.sep.replace '\\', '\\\\'}'", output.lastWrite()

process.on 'exit', ->
  try
    fs.unlinkSync historyFile
  catch exception # Already deleted, nothing else to do.
