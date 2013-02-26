# Error Formating
# ---------------

# Ensure that errors of different kinds (lexer, parser and compiler) are shown
# in a consistent way.

assertErrorFormat = (code, expectedErrorFormat) ->
  throws (-> CoffeeScript.compile code), (err) ->
    eq expectedErrorFormat, (err.prettyMessage 'test.coffee', code)
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

# FIXME Test not passing. See "parser.yy.parseError" in coffee-script.coffee
test "parser error formating", ->
  assertErrorFormat '''
    foo in bar or in baz
  ''',
  '''
    test.coffee:1:12: error: unexpected RELATION
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