# Error Formating
# ---------------

# Ensure that errors of different kinds (lexer, parser and compiler) are shown
# in a consistent way.

{prettyErrorMessage} = CoffeeScript.helpers

assertErrorFormat = (code, expectedErrorFormat) ->
  throws (-> CoffeeScript.compile code), (err) ->
    message = prettyErrorMessage err, 'test.coffee', code
    eq expectedErrorFormat, message
    yes

test "lexer errors formating", ->
  assertErrorFormat '''
    normalObject    = {}
    insideOutObject = }{
  ''',
  '''
    test.coffee:2:19: error: unmatched }
    insideOutObject = }{
                      ^
  '''

test "parser error formating", ->
  assertErrorFormat '''
    foo in bar or in baz
  ''',
  '''
    test.coffee:1:15: error: unexpected RELATION
    foo in bar or in baz
                  ^^
  '''

test "compiler error formatting", ->
  assertErrorFormat '''
    evil = (foo, eval, bar) ->
  ''',
  '''
    test.coffee:1:14: error: parameter name "eval" is not allowed
    evil = (foo, eval, bar) ->
                 ^^^^
  '''