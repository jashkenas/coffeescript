# A very simple Read-Eval-Print-Loop. Compiles one line at a time to JavaScript
# and evaluates it. Good for simple tests, or poking around the **Node.js** API.
# Using it looks like this:
#
#     coffee> console.log "#{num} bottles of beer" for num in [99..1]

# Require the **coffee-script** module to get access to the compiler.
CoffeeScript = require './coffee-script'
helpers      = require './helpers'
autocomplete = require './autocomplete'
readline     = require 'readline'

# Start by opening up **stdio**.
stdio = process.openStdin()

# Log an error.
error = (err) ->
  stdio.write (err.stack or err.toString()) + '\n\n'

# Quick alias for quitting the REPL.
helpers.extend global, quit: -> process.exit(0)

# The main REPL function. **run** is called every time a line of code is entered.
# Attempt to evaluate the command. If there's an exception, print it out instead
# of exiting.
run = (buffer) ->
  try
    val = CoffeeScript.eval buffer.toString(), bare: on, globals: on, fileName: 'repl'
    console.log val if val isnt undefined
  catch err
    error err
  repl.prompt()

# Make sure that uncaught exceptions don't kill the REPL.
process.on 'uncaughtException', error

# Create the REPL by listening to **stdin**.
repl = readline.createInterface stdio, autocomplete.complete
repl.setPrompt 'coffee> '
stdio.on 'data',   (buffer) -> repl.write buffer
repl.on  'close',  -> stdio.destroy()
repl.on  'line',   run
repl.prompt()
