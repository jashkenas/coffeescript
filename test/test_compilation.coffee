# Ensure that carriage returns don't break compilation on Windows.
CoffeeScript: require('./../lib/coffee-script')
Lexer: require('./../lib/lexer')

js: CoffeeScript.compile("one\r\ntwo", {noWrap: on})

ok js is "one;\ntwo;"


# Try out language extensions to CoffeeScript.

# Create the Node were going to add -- a literal syntax for splitting
# strings into letters.
class SplitNode extends BaseNode
  type: 'Split'

  constructor: (variable) ->
    @variable: variable

  compileNode: (o) ->
    "'${@variable}'.split('')"

# Extend CoffeeScript with our lexing function that matches --wordgoeshere--
# and creates a SplitNode.
CoffeeScript.extend ->
  return false unless variable: @match(/^--(\w+)--/, 1)
  @i: + variable.length + 4
  @token 'EXTENSION', new SplitNode(variable)
  true

# Compile with the extension.
js: CoffeeScript.compile 'return --tobesplit--', {noWrap: on}

ok js is "return 'tobesplit'.split('');"


# Let's try a different extension, for Ruby-style array literals.

class WordArrayNode extends BaseNode
  type: 'WordArray'

  constructor: (words) ->
    @words: words

  compileNode: (o) ->
    strings = ("\"$word\"" for word in @words).join ', '
    "[$strings]"

CoffeeScript.extend ->
  return false unless words: @chunk.match(/^%w\{(.*?)\}/)
  @i: + words[0].length
  @token 'EXTENSION', new WordArrayNode(words[1].split(/\s+/))
  true

js: CoffeeScript.compile 'puts %w{one two three}', {noWrap: on}

ok js is 'puts(["one", "two", "three"]);'


# Finally, let's try an extension that converts `a << b` into `a.push(b)`.

CoffeeScript.extend ->
  return false unless @chunk.match(/^<</)
  @i: + 2
  @token 'PROPERTY_ACCESS', '.'
  @token 'IDENTIFIER', 'push'

js: CoffeeScript.compile 'a << b', {noWrap: on}

ok js is 'a.push(b);'

Lexer.extensions: []

