# A very simple Read-Eval-Print-Loop. Compiles one line at a time to JavaScript
# and evaluates it. Good for simple tests, or poking around the **Node.js** API.
# Using it looks like this:
#
#     coffee> puts "$num bottles of beer" for num in [99..1]

# Require the **coffee-script** module to get access to the compiler.
CoffeeScript: require './coffee-script'
helpers:      require('./helpers').helpers

# Our prompt.
prompt: 'coffee> '

# Quick alias for quitting the REPL.
helpers.extend global, {
  quit: -> process.exit(0)
}

# The main REPL function. **run** is called every time a line of code is entered.
# Attempt to evaluate the command. If there's an exception, print it out instead
# of exiting.
run: (buffer) ->
  try
    val: CoffeeScript.run buffer.toString(), {no_wrap: true, globals: true, source: 'repl'}
    puts inspect val if val isnt undefined
  catch err
    puts err.stack or err.toString()
  print prompt

# Start up the REPL by opening **stdin** and listening for input.
stdin: process.openStdin()
stdin.addListener 'data', run
print prompt