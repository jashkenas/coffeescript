# A very simple Read-Eval-Print-Loop. Compiles one line at a time to JavaScript
# and evaluates it. Good for simple tests, or poking around the **Node.js** API.
# Using it looks like this:
#
#     coffee> puts "#{num} bottles of beer" for num in [99..1]

# Require the **coffee-script** module to get access to the compiler.
CoffeeScript = require './coffee-script'
helpers      = require './helpers'
readline     = require 'readline'

# Start by opening up **stdio**.
stdio = process.openStdin()

# Quick alias for quitting the REPL.
helpers.extend global, quit: -> process.exit(0)

# The main REPL function. **run** is called every time a line of code is entered.
# Attempt to evaluate the command. If there's an exception, print it out instead
# of exiting.
run = (buffer) ->
  try
    val = CoffeeScript.eval buffer.toString(), bare: on, globals: on, fileName: 'repl'
    puts inspect val if val isnt undefined
  catch err
    puts err.stack or err.toString()
  repl.prompt()

# Create the REPL by listening to **stdin**.
repl = readline.createInterface stdio
repl.setPrompt 'coffee> '
stdio.on 'data',   (buffer) -> repl.write buffer
repl.on  'close',  -> stdio.destroy()
repl.on  'line',   run
repl.prompt()
