# Error Formating
# ---------------

# Ensure that errors of different kinds (lexer, parser and compiler) are shown
# in a consistent way.

assertErrorFormat = (code, expectedErrorFormat) ->
  throws (-> CoffeeScript.run code), (err) ->
    err.colorful = no
    eq expectedErrorFormat, "#{err}"
    yes

test "lexer errors formating", ->
  assertErrorFormat '''
    normalObject    = {}
    insideOutObject = }{
  ''',
  '''
    [stdin]:2:19: error: unmatched }
    insideOutObject = }{
                      ^
  '''

test "parser error formating", ->
  assertErrorFormat '''
    foo in bar or in baz
  ''',
  '''
    [stdin]:1:15: error: unexpected RELATION
    foo in bar or in baz
                  ^^
  '''

test "compiler error formatting", ->
  assertErrorFormat '''
    evil = (foo, eval, bar) ->
  ''',
  '''
    [stdin]:1:14: error: parameter name "eval" is not allowed
    evil = (foo, eval, bar) ->
                 ^^^^
  '''

test "patchStackTrace line patching", ->
  err = new Error 'error'
  ok err.stack.match /test[\/\\]error_messages\.coffee:\d+:\d+\b/

fs   = require 'fs'
path = require 'path'

test "#2849: compilation error in a require()d file", ->
  # Create a temporary file to require().
  ok not fs.existsSync 'test/syntax-error.coffee'
  fs.writeFileSync 'test/syntax-error.coffee', 'foo in bar or in baz'

  try
    assertErrorFormat '''
      require './test/syntax-error'
    ''',
    """
      #{path.join __dirname, 'syntax-error.coffee'}:1:15: error: unexpected RELATION
      foo in bar or in baz
                    ^^
    """
  finally
    fs.unlink 'test/syntax-error.coffee'