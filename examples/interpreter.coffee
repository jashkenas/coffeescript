###
Interactive interpreter example. Creates a new interactive interpreter
with a custom prompt and custom objects available in the default context.
###
CoffeeScript = require '../lib/coffee-script'

# Output custom messages or objects
console.log 'Welcome to the CoffeeScript interpreter!'

# Create a new interpreter on stdin/stdout
repl = CoffeeScript.repl.start
    prompt: 'interpreter> '

# Add imports, custom objects and methods
repl.context.myAssert = require 'assert'

class repl.context.MyObj
    constructor: (@name = 'world') ->
    getHello: ->
        "Hello, #{@name}!"
    sayHello: ->
        console.log @getHello()

repl.context.multiply = (x, y) ->
    x * y
