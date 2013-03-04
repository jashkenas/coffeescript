testScript = '''
if true
  x = 6
  console.log "A console #{x + 7} log"

foo = "bar"
z = /// ^ (a#{foo}) ///

x = () ->
    try
        console.log "foo"
    catch err
        # Rewriter will generate explicit indentation here.

    return null
'''

test "Verify location of generated tokens", ->
  tokens = CoffeeScript.tokens "a = 79"

  eq tokens.length, 4

  aToken = tokens[0]
  eq aToken[2].first_line, 0
  eq aToken[2].first_column, 0
  eq aToken[2].last_line, 0
  eq aToken[2].last_column, 0

  equalsToken = tokens[1]
  eq equalsToken[2].first_line, 0
  eq equalsToken[2].first_column, 2
  eq equalsToken[2].last_line, 0
  eq equalsToken[2].last_column, 2

  numberToken = tokens[2]
  eq numberToken[2].first_line, 0
  eq numberToken[2].first_column, 4
  eq numberToken[2].last_line, 0
  eq numberToken[2].last_column, 5

test "Verify location of generated tokens (with indented first line)", ->
  tokens = CoffeeScript.tokens "  a = 83"

  eq tokens.length, 6
  [IndentToken, aToken, equalsToken, numberToken] = tokens

  eq aToken[2].first_line, 0
  eq aToken[2].first_column, 2
  eq aToken[2].last_line, 0
  eq aToken[2].last_column, 2

  eq equalsToken[2].first_line, 0
  eq equalsToken[2].first_column, 4
  eq equalsToken[2].last_line, 0
  eq equalsToken[2].last_column, 4

  eq numberToken[2].first_line, 0
  eq numberToken[2].first_column, 6
  eq numberToken[2].last_line, 0
  eq numberToken[2].last_column, 7

test "Verify all tokens get a location", ->
  doesNotThrow ->
    tokens = CoffeeScript.tokens testScript
    for token in tokens
        ok !!token[2]
