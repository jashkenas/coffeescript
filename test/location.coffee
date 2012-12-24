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
  tokens = CoffeeScript.tokens "a = 7"

  eq tokens.length, 4
  a = tokens[0]

test "Verify all tokens get a location", ->
  doesNotThrow ->
    tokens = CoffeeScript.tokens testScript
    for token in tokens
        ok !!token.locationData
