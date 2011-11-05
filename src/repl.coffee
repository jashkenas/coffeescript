# A very simple Read-Eval-Print-Loop. Compiles one line at a time to JavaScript
# and evaluates it. Good for simple tests, or poking around the **Node.js** API.
# Using it looks like this:
#
#     coffee> console.log "#{num} bottles of beer" for num in [99..1]

# Require the **coffee-script** module to get access to the compiler.
CoffeeScript = require './coffee-script'
readline     = require 'readline'
{inspect}    = require 'util'
{Script}     = require 'vm'
Module       = require 'module'

# REPL Setup

# Config
REPL_PROMPT = 'coffee> '
REPL_PROMPT_CONTINUATION = '......> '
enableColours = no
unless process.platform is 'win32'
  enableColours = not process.env.NODE_DISABLE_COLORS

# Start by opening up `stdin` and `stdout`.
stdin = process.openStdin()
stdout = process.stdout

# Log an error.
error = (err) ->
  stdout.write (err.stack or err.toString()) + '\n'

# The current backlog of multi-line code.
backlog = ''

# The main REPL function. **run** is called every time a line of code is entered.
# Attempt to evaluate the command. If there's an exception, print it out instead
# of exiting.
run = (buffer) ->
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
    returnValue = CoffeeScript.eval "_=(#{code}\n)", {
      filename: 'repl'
      modulename: 'repl'
    }
    if returnValue is undefined
      global._ = _
    process.stdout.write inspect(returnValue, no, 2, enableColours) + '\n'
  catch err
    error err
  repl.prompt()

## Autocompletion

# Regexes to match complete-able bits of text.
ACCESSOR  = /\s*([\w\.]+)(?:\.(\w*))$/
SIMPLEVAR = /\s*(\w*)$/i

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
    completions = getCompletions prefix, Object.getOwnPropertyNames val
    [completions, prefix]

# Attempt to autocomplete an in-scope free variable: `one`.
completeVariable = (text) ->
  free = (text.match SIMPLEVAR)?[1]
  if free?
    vars = Script.runInThisContext 'Object.getOwnPropertyNames(this)'
    keywords = (r for r in CoffeeScript.RESERVED when r[0..1] isnt '__')
    possibilities = vars.concat keywords
    completions = getCompletions free, possibilities
    [completions, free]

# Return elements of candidates for which `prefix` is a prefix.
getCompletions = (prefix, candidates) ->
  (el for el in candidates when el.indexOf(prefix) is 0)

# Make sure that uncaught exceptions don't kill the REPL.
process.on 'uncaughtException', error

# Create the REPL by listening to **stdin**.
if readline.createInterface.length < 3
  repl = readline.createInterface stdin, autocomplete
  stdin.on 'data', (buffer) -> repl.write buffer
else
  repl = readline.createInterface stdin, stdout, autocomplete

repl.on 'attemptClose', ->
  if backlog
    backlog = ''
    process.stdout.write '\n'
    repl.setPrompt REPL_PROMPT
    repl.prompt()
  else
    repl.close()

repl.on 'close', ->
  process.stdout.write '\n'
  stdin.destroy()

repl.on 'line', run

repl.setPrompt REPL_PROMPT
repl.prompt()
