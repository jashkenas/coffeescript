# Ensure that carriage returns don't break compilation on Windows.

js: CoffeeScript.compile("one\r\ntwo", {no_wrap: on})

ok js is "one;\ntwo;"


# Try out language extensions to CoffeeScript.

# Create the Node were going to add -- a literal syntax for splitting
# strings into letters.
class SplitNode extends BaseNode
  type: 'Split'

  constructor: (variable) ->
    @variable: variable

  compile_node: (o) ->
    "'${@variable}'.split('')"

# Extend CoffeeScript with our lexing function that matches --wordgoeshere--
# and creates a SplitNode.
CoffeeScript.extend ->
  return false unless variable: @match /^--(\w+)--/, 1
  @i += variable.length + 4
  @token 'EXTENSION', new SplitNode(variable)
  true

# Compile with the extension.
js: CoffeeScript.compile('return --tobesplit--', {no_wrap: on})

ok js is "return 'tobesplit'.split('');"

Lexer.extensions: []