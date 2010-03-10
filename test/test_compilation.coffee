# Ensure that carriage returns don't break compilation on Windows.

js: CoffeeScript.compile("one\r\ntwo", {no_wrap: on})

ok js is "one;\ntwo;"


# Try out language extensions to CoffeeScript. (Not yet working.)

# class SplitNode extends BaseNode
#   type: 'Split'
#
#   constructor: (variable) ->
#     @variable: variable
#
#   compile_node: (o) ->
#     "${variable}.split('')"
#
# CoffeeScript.extend ->
#   return false unless variable: @match /^--(\w+)--/, 1
#   @i += variable.length + 4
#   node: new SplitNode(variable)
#   p node
#   @token 'EXTENSION', node
#   true
#
# js: CoffeeScript.tokens('print --tobesplit--', {no_wrap: on})
#
# p js
#
# Lexer.extensions: []