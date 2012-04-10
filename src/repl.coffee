# A very simple Read-Eval-Print-Loop. Compiles one line at a time to JavaScript
# and evaluates it. Good for simple tests, or poking around the **Node.js** API.
# Using it looks like this:
#
#     coffee> console.log "#{num} bottles of beer" for num in [99..1]

# Start by opening up `stdin` and `stdout`.
stdin = process.openStdin()
stdout = process.stdout

# Require the **coffee-script** module to get access to the compiler.
CoffeeScript = require './coffee-script'
readline     = require 'readline'
{inspect}    = require 'util'
{Script}     = require 'vm'
Module       = require 'module'

# REPL Setup

# Config
REPL_PROMPT = 'coffee> '
REPL_PROMPT_MULTILINE = '------> '
REPL_PROMPT_CONTINUATION = '......> '
enableColours = no
unless process.platform is 'win32'
  enableColours = not process.env.NODE_DISABLE_COLORS

# Log an error.
error = (err) ->
  stdout.write (err.stack or err.toString()) + '\n'

## Autocompletion

# Regexes to match complete-able bits of text.
ACCESSOR  = /\s*([\w\.]+)(?:\.(\w*))$/
SIMPLEVAR = /(\w+)$/i

# Returns a list of completions, and the completed text.
autocomplete = (text) ->
  completeAttribute(text) or completeVariable(text) or [[], text]

# Attempt to autocomplete a chained dotted attribute: `one.two.three`.
completeAttribute = (text) ->
  if match = text.match ACCESSOR
    [all, obj, prefix] = match
    try
      val = Script.runInThisContext obj
    catch error
      return
    completions = getCompletions prefix, Object.getOwnPropertyNames Object val
    [completions, prefix]

# Attempt to autocomplete an in-scope free variable: `one`.
completeVariable = (text) ->
  free = text.match(SIMPLEVAR)?[1]
  free = "" if text is ""
  if free?
    vars = Script.runInThisContext 'Object.getOwnPropertyNames(Object(this))'
    keywords = (r for r in CoffeeScript.RESERVED when r[..1] isnt '__')
    possibilities = vars.concat keywords
    completions = getCompletions free, possibilities
    [completions, free]

# Return elements of candidates for which `prefix` is a prefix.
getCompletions = (prefix, candidates) ->
  (el for el in candidates when el.indexOf(prefix) is 0)

# Make sure that uncaught exceptions don't kill the REPL.
process.on 'uncaughtException', error

# The current backlog of multi-line code.
backlog = ''

# The main REPL function. **run** is called every time a line of code is entered.
# Attempt to evaluate the command. If there's an exception, print it out instead
# of exiting.
run = (buffer) ->
  buffer = buffer.replace /[\r\n]+$/, ""
  if multilineMode
    backlog += "#{buffer}\n"
    repl.setPrompt REPL_PROMPT_CONTINUATION
    repl.prompt()
    return
  if !buffer.toString().trim() and !backlog
    repl.prompt()
    return
  code = backlog += buffer
  if code[code.length - 1] is '\\'
    backlog = "#{backlog[...-1]}\n"
    repl.setPrompt REPL_PROMPT_CONTINUATION
    repl.prompt()
    return
  repl.setPrompt REPL_PROMPT
  backlog = ''
  try
    _ = global._
    returnValue = CoffeeScript.eval "_=(undefined\n;#{code}\n)", {
      filename: 'repl'
      modulename: 'repl'
    }
    if returnValue is undefined
      global._ = _
    repl.output.write "#{inspect returnValue, no, 2, enableColours}\n"
  catch err
    error err
  repl.prompt()

if stdin.readable
  # handle piped input
  pipedInput = ''
  repl =
    prompt: -> stdout.write @_prompt
    setPrompt: (p) -> @_prompt = p
    input: stdin
    output: stdout
    on: ->
  stdin.on 'data', (chunk) ->
    pipedInput += chunk
  stdin.on 'end', ->
    for line in pipedInput.trim().split "\n"
      stdout.write "#{line}\n"
      run line
    stdout.write '\n'
    process.exit 0
else
  # Create the REPL by listening to **stdin**.
  if readline.createInterface.length < 3
    repl = readline.createInterface stdin, autocomplete
    stdin.on 'data', (buffer) -> repl.write buffer
  else
    repl = readline.createInterface stdin, stdout, autocomplete

multilineMode = off

# Handle multi-line mode switch
repl.input.on 'keypress', (char, key) ->
  # test for Ctrl-v
  return unless key and key.ctrl and not key.meta and not key.shift and key.name is 'v'
  cursorPos = repl.cursor
  repl.output.cursorTo 0
  repl.output.clearLine 1
  multilineMode = not multilineMode
  repl._line() if not multilineMode and backlog
  backlog = ''
  repl.setPrompt (newPrompt = if multilineMode then REPL_PROMPT_MULTILINE else REPL_PROMPT)
  repl.prompt()
  repl.output.cursorTo newPrompt.length + (repl.cursor = cursorPos)

# Handle Ctrl-d press at end of last line in multiline mode
repl.input.on 'keypress', (char, key) ->
  return unless multilineMode and repl.line
  # test for Ctrl-d
  return unless key and key.ctrl and not key.meta and not key.shift and key.name is 'd'
  multilineMode = off
  repl._line()

repl.on 'attemptClose', ->
  if multilineMode
    multilineMode = off
    repl.output.cursorTo 0
    repl.output.clearLine 1
    repl._onLine repl.line
    return
  if backlog
    backlog = ''
    repl.output.write '\n'
    repl.setPrompt REPL_PROMPT
    repl.prompt()
  else
    repl.close()

repl.on 'close', ->
  repl.output.write '\n'
  repl.input.destroy()

repl.on 'line', run

repl.setPrompt REPL_PROMPT
repl.prompt()
