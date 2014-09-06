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
    [stdin]:1:15: error: unexpected in
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

test "compiler error formatting with mixed tab and space", ->
  assertErrorFormat """
    \t  if a
    \t  test
  """,
  '''
    [stdin]:1:4: error: unexpected if
    \t  if a
    \t  ^^
  '''


if require?
  fs   = require 'fs'
  path = require 'path'

  test "patchStackTrace line patching", ->
    err = new Error 'error'
    ok err.stack.match /test[\/\\]error_messages\.coffee:\d+:\d+\b/

  test "patchStackTrace stack prelude consistent with V8", ->
    err = new Error
    ok err.stack.match /^Error\n/ # Notice no colon when no message.

    err = new Error 'error'
    ok err.stack.match /^Error: error\n/

  test "#2849: compilation error in a require()d file", ->
    # Create a temporary file to require().
    ok not fs.existsSync 'test/syntax-error.coffee'
    fs.writeFileSync 'test/syntax-error.coffee', 'foo in bar or in baz'

    try
      assertErrorFormat '''
        require './test/syntax-error'
      ''',
      """
        #{path.join __dirname, 'syntax-error.coffee'}:1:15: error: unexpected in
        foo in bar or in baz
                      ^^
      """
    finally
      fs.unlink 'test/syntax-error.coffee'


test "#1096: unexpected generated tokens", ->
  # Unexpected interpolation
  assertErrorFormat '{"#{key}": val}', '''
    [stdin]:1:3: error: unexpected string interpolation
    {"#{key}": val}
      ^^
  '''
  # Implicit ends
  assertErrorFormat 'a:, b', '''
    [stdin]:1:3: error: unexpected ,
    a:, b
      ^
  '''
  # Explicit ends
  assertErrorFormat '(a:)', '''
    [stdin]:1:4: error: unexpected )
    (a:)
       ^
  '''
  # Unexpected end of file
  assertErrorFormat 'a:', '''
    [stdin]:1:3: error: unexpected end of input
    a:
      ^
  '''
  # Unexpected implicit object
  assertErrorFormat '''
    for i in [1]:
      1
  ''', '''
    [stdin]:1:13: error: unexpected :
    for i in [1]:
                ^
  '''

test "#3325: implicit indentation errors", ->
  assertErrorFormat '''
    i for i in a then i
  ''', '''
    [stdin]:1:14: error: unexpected then
    i for i in a then i
                 ^^^^
  '''

test "explicit indentation errors", ->
  assertErrorFormat '''
    a = b
      c
  ''', '''
    [stdin]:2:1: error: unexpected indentation
      c
    ^^
  '''
