# A CoffeeScript port/version of the Node.js REPL.

# Required modules.
coffee: require 'coffee-script'
process.mixin require 'sys'

# Shortcut variables.
prompt: 'coffee> '
quit:   -> process.exit(0)

# The main REPL function. Called everytime a line of code is entered.
# Attempt to evaluate the command. If there's an exception, print it.
readline: (code) ->
  try
    js:  coffee.compile code, {no_wrap: true, globals: true}
    val: eval(js)
    p val if val isnt undefined
  catch err
    puts err.stack or err.toString()
  print prompt

# Start up the REPL.
process.stdio.addListener 'data', readline
process.stdio.open()
print prompt