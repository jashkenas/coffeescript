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
    [stdin]:1:3: error: unexpected interpolation
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
  assertErrorFormat 'a +', '''
    [stdin]:1:4: error: unexpected end of input
    a +
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

test "#1316: unexpected end of interpolation", ->
  assertErrorFormat '''
    "#{+}"
  ''', '''
    [stdin]:1:5: error: unexpected end of interpolation
    "#{+}"
        ^
  '''
  assertErrorFormat '''
    "#{++}"
  ''', '''
    [stdin]:1:6: error: unexpected end of interpolation
    "#{++}"
         ^
  '''
  assertErrorFormat '''
    "#{-}"
  ''', '''
    [stdin]:1:5: error: unexpected end of interpolation
    "#{-}"
        ^
  '''
  assertErrorFormat '''
    "#{--}"
  ''', '''
    [stdin]:1:6: error: unexpected end of interpolation
    "#{--}"
         ^
  '''
  assertErrorFormat '''
    "#{~}"
  ''', '''
    [stdin]:1:5: error: unexpected end of interpolation
    "#{~}"
        ^
  '''
  assertErrorFormat '''
    "#{!}"
  ''', '''
    [stdin]:1:5: error: unexpected end of interpolation
    "#{!}"
        ^
  '''
  assertErrorFormat '''
    "#{not}"
  ''', '''
    [stdin]:1:7: error: unexpected end of interpolation
    "#{not}"
          ^
  '''
  assertErrorFormat '''
    "#{5) + (4}_"
  ''', '''
    [stdin]:1:5: error: unmatched )
    "#{5) + (4}_"
        ^
  '''
  # #2918
  assertErrorFormat '''
    "#{foo.}"
  ''', '''
    [stdin]:1:8: error: unexpected end of interpolation
    "#{foo.}"
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

test "unclosed strings", ->
  assertErrorFormat '''
    '
  ''', '''
    [stdin]:1:1: error: missing '
    '
    ^
  '''
  assertErrorFormat '''
    "
  ''', '''
    [stdin]:1:1: error: missing "
    "
    ^
  '''
  assertErrorFormat """
    '''
  """, """
    [stdin]:1:1: error: missing '''
    '''
    ^
  """
  assertErrorFormat '''
    """
  ''', '''
    [stdin]:1:1: error: missing """
    """
    ^
  '''
  assertErrorFormat '''
    "#{"
  ''', '''
    [stdin]:1:4: error: missing "
    "#{"
       ^
  '''
  assertErrorFormat '''
    """#{"
  ''', '''
    [stdin]:1:6: error: missing "
    """#{"
         ^
  '''
  assertErrorFormat '''
    "#{"""
  ''', '''
    [stdin]:1:4: error: missing """
    "#{"""
       ^
  '''
  assertErrorFormat '''
    """#{"""
  ''', '''
    [stdin]:1:6: error: missing """
    """#{"""
         ^
  '''
  assertErrorFormat '''
    ///#{"""
  ''', '''
    [stdin]:1:6: error: missing """
    ///#{"""
         ^
  '''
  assertErrorFormat '''
    "a
      #{foo """
        bar
          #{ +'12 }
        baz
        """} b"
  ''', '''
    [stdin]:4:11: error: missing '
          #{ +'12 }
              ^
  '''
  # https://github.com/jashkenas/coffeescript/issues/3301#issuecomment-31735168
  assertErrorFormat '''
    # Note the double escaping; this would be `"""a\"""` real code.
    """a\\"""
  ''', '''
    [stdin]:2:1: error: missing """
    """a\\"""
    ^
  '''

test "unclosed heregexes", ->
  assertErrorFormat '''
    ///
  ''', '''
    [stdin]:1:1: error: missing ///
    ///
    ^
  '''
  # https://github.com/jashkenas/coffeescript/issues/3301#issuecomment-31735168
  assertErrorFormat '''
    # Note the double escaping; this would be `///a\///` real code.
    ///a\\///
  ''', '''
    [stdin]:2:1: error: missing ///
    ///a\\///
    ^
  '''

test "unexpected token after string", ->
  # Parsing error.
  assertErrorFormat '''
    'foo'bar
  ''', '''
    [stdin]:1:6: error: unexpected bar
    'foo'bar
         ^^^
  '''
  assertErrorFormat '''
    "foo"bar
  ''', '''
    [stdin]:1:6: error: unexpected bar
    "foo"bar
         ^^^
  '''
  # Lexing error.
  assertErrorFormat '''
    'foo'bar'
  ''', '''
    [stdin]:1:9: error: missing '
    'foo'bar'
            ^
  '''
  assertErrorFormat '''
    "foo"bar"
  ''', '''
    [stdin]:1:9: error: missing "
    "foo"bar"
            ^
  '''

test "#3348: Location data is wrong in interpolations with leading whitespace", ->
  assertErrorFormat '''
    "#{ {"#{key}": val} }"
  ''', '''
    [stdin]:1:7: error: unexpected interpolation
    "#{ {"#{key}": val} }"
          ^^
  '''

test "octal escapes", ->
  assertErrorFormat '''
    "a\\0\\tb\\\\\\07c"
  ''', '''
    [stdin]:1:10: error: octal escape sequences are not allowed \\07
    "a\\0\\tb\\\\\\07c"
      \  \   \ \ ^
  '''

test "illegal herecomment", ->
  assertErrorFormat '''
    ###
      Regex: /a*/g
    ###
  ''', '''
    [stdin]:2:12: error: block comments cannot contain */
      Regex: /a*/g
               ^
  '''

test "#1724: regular expressions beginning with *", ->
  assertErrorFormat '''
    /* foo/
  ''', '''
    [stdin]:1:2: error: regular expressions cannot begin with *
    /* foo/
     ^
  '''
  assertErrorFormat '''
    ///
      * foo
    ///
  ''', '''
    [stdin]:2:3: error: regular expressions cannot begin with *
      * foo
      ^
  '''

test "invalid regex flags", ->
  assertErrorFormat '''
    /a/ii
  ''', '''
    [stdin]:1:4: error: invalid regular expression flags ii
    /a/ii
       ^
  '''
  assertErrorFormat '''
    /a/G
  ''', '''
    [stdin]:1:4: error: invalid regular expression flags G
    /a/G
       ^
  '''
  assertErrorFormat '''
    /a/gimi
  ''', '''
    [stdin]:1:4: error: invalid regular expression flags gimi
    /a/gimi
       ^
  '''
  assertErrorFormat '''
    /a/g_
  ''', '''
    [stdin]:1:4: error: invalid regular expression flags g_
    /a/g_
       ^
  '''
  assertErrorFormat '''
    ///a///ii
  ''', '''
    [stdin]:1:8: error: invalid regular expression flags ii
    ///a///ii
           ^
  '''
  doesNotThrow -> CoffeeScript.compile '/a/ymgi'

test "missing `)`, `}`, `]`", ->
  assertErrorFormat '''
    (
  ''', '''
    [stdin]:1:1: error: missing )
    (
    ^
  '''
  assertErrorFormat '''
    {
  ''', '''
    [stdin]:1:1: error: missing }
    {
    ^
  '''
  assertErrorFormat '''
    [
  ''', '''
    [stdin]:1:1: error: missing ]
    [
    ^
  '''
  assertErrorFormat '''
    obj = {a: [1, (2+
  ''', '''
    [stdin]:1:15: error: missing )
    obj = {a: [1, (2+
                  ^
  '''
  assertErrorFormat '''
    "#{
  ''', '''
    [stdin]:1:3: error: missing }
    "#{
      ^
  '''
  assertErrorFormat '''
    """
      foo#{ bar "#{1}"
  ''', '''
    [stdin]:2:7: error: missing }
      foo#{ bar "#{1}"
          ^
  '''

test "unclosed regexes", ->
  assertErrorFormat '''
    /
  ''', '''
    [stdin]:1:1: error: missing / (unclosed regex)
    /
    ^
  '''
  assertErrorFormat '''
    # Note the double escaping; this would be `/a\/` real code.
    /a\\/
  ''', '''
    [stdin]:2:1: error: missing / (unclosed regex)
    /a\\/
    ^
  '''
  assertErrorFormat '''
    /// ^
      a #{""" ""#{if /[/].test "|" then 1 else 0}"" """}
    ///
  ''', '''
    [stdin]:2:18: error: missing / (unclosed regex)
      a #{""" ""#{if /[/].test "|" then 1 else 0}"" """}
                     ^
  '''

test "duplicate function arguments", ->
  assertErrorFormat '''
    (foo, bar, foo) ->
  ''', '''
    [stdin]:1:12: error: multiple parameters named foo
    (foo, bar, foo) ->
               ^^^
  '''
  assertErrorFormat '''
    (@foo, bar, @foo) ->
  ''', '''
    [stdin]:1:13: error: multiple parameters named @foo
    (@foo, bar, @foo) ->
                ^^^^
  '''
