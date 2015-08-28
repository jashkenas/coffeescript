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
  # Unexpected key in implicit object (an implicit object itself is _not_
  # unexpected here)
  assertErrorFormat '''
    for i in [1]:
      1
  ''', '''
    [stdin]:1:10: error: unexpected [
    for i in [1]:
             ^
  '''
  # Unexpected regex
  assertErrorFormat '{/a/i: val}', '''
    [stdin]:1:2: error: unexpected regex
    {/a/i: val}
     ^^^^
  '''
  assertErrorFormat '{///a///i: val}', '''
    [stdin]:1:2: error: unexpected regex
    {///a///i: val}
     ^^^^^^^^
  '''
  assertErrorFormat '{///#{a}///i: val}', '''
    [stdin]:1:2: error: unexpected regex
    {///#{a}///i: val}
     ^^^^^^^^^^^
  '''
  # Unexpected string
  assertErrorFormat "a''", '''
    [stdin]:1:2: error: unexpected string
    a''
     ^^
  '''
  assertErrorFormat 'a""', '''
    [stdin]:1:2: error: unexpected string
    a""
     ^^
  '''
  assertErrorFormat "a'b'", '''
    [stdin]:1:2: error: unexpected string
    a'b'
     ^^^
  '''
  assertErrorFormat 'a"b"', '''
    [stdin]:1:2: error: unexpected string
    a"b"
     ^^^
  '''
  assertErrorFormat "a'''b'''", """
    [stdin]:1:2: error: unexpected string
    a'''b'''
     ^^^^^^^
  """
  assertErrorFormat 'a"""b"""', '''
    [stdin]:1:2: error: unexpected string
    a"""b"""
     ^^^^^^^
  '''
  assertErrorFormat 'a"#{b}"', '''
    [stdin]:1:2: error: unexpected string
    a"#{b}"
     ^^^^^^
  '''
  assertErrorFormat 'a"""#{b}"""', '''
    [stdin]:1:2: error: unexpected string
    a"""#{b}"""
     ^^^^^^^^^^
  '''
  # Unexpected number
  assertErrorFormat '"a"0x00Af2', '''
    [stdin]:1:4: error: unexpected number
    "a"0x00Af2
       ^^^^^^^
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
    ^^^
  """
  assertErrorFormat '''
    """
  ''', '''
    [stdin]:1:1: error: missing """
    """
    ^^^
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
       ^^^
  '''
  assertErrorFormat '''
    """#{"""
  ''', '''
    [stdin]:1:6: error: missing """
    """#{"""
         ^^^
  '''
  assertErrorFormat '''
    ///#{"""
  ''', '''
    [stdin]:1:6: error: missing """
    ///#{"""
         ^^^
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
    ^^^
  '''

test "unclosed heregexes", ->
  assertErrorFormat '''
    ///
  ''', '''
    [stdin]:1:1: error: missing ///
    ///
    ^^^
  '''
  # https://github.com/jashkenas/coffeescript/issues/3301#issuecomment-31735168
  assertErrorFormat '''
    # Note the double escaping; this would be `///a\///` real code.
    ///a\\///
  ''', '''
    [stdin]:2:1: error: missing ///
    ///a\\///
    ^^^
  '''

test "unexpected token after string", ->
  # Parsing error.
  assertErrorFormat '''
    'foo'bar
  ''', '''
    [stdin]:1:6: error: unexpected identifier
    'foo'bar
         ^^^
  '''
  assertErrorFormat '''
    "foo"bar
  ''', '''
    [stdin]:1:6: error: unexpected identifier
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
    "#{ * }"
  ''', '''
    [stdin]:1:5: error: unexpected *
    "#{ * }"
        ^
  '''

test "octal escapes", ->
  assertErrorFormat '''
    "a\\0\\tb\\\\\\07c"
  ''', '''
    [stdin]:1:10: error: octal escape sequences are not allowed \\07
    "a\\0\\tb\\\\\\07c"
      \  \   \ \ ^\^^
  '''
  assertErrorFormat '''
    "a
      #{b} \\1"
  ''', '''
    [stdin]:2:8: error: octal escape sequences are not allowed \\1
      #{b} \\1"
           ^\^
  '''
  assertErrorFormat '''
    /a\\0\\tb\\\\\\07c/
  ''', '''
    [stdin]:1:10: error: octal escape sequences are not allowed \\07
    /a\\0\\tb\\\\\\07c/
      \  \   \ \ ^\^^
  '''
  assertErrorFormat '''
    ///a
      #{b} \\01///
  ''', '''
    [stdin]:2:8: error: octal escape sequences are not allowed \\01
      #{b} \\01///
           ^\^^
  '''

test "#3795: invalid escapes", ->
  assertErrorFormat '''
    "a\\0\\tb\\\\\\x7g"
  ''', '''
    [stdin]:1:10: error: invalid escape sequence \\x7g
    "a\\0\\tb\\\\\\x7g"
      \  \   \ \ ^\^^^
  '''
  assertErrorFormat '''
    "a
      #{b} \\uA02
     c"
  ''', '''
    [stdin]:2:8: error: invalid escape sequence \\uA02
      #{b} \\uA02
           ^\^^^^
  '''
  assertErrorFormat '''
    /a\\u002space/
  ''', '''
    [stdin]:1:3: error: invalid escape sequence \\u002s
    /a\\u002space/
      ^\^^^^^
  '''
  assertErrorFormat '''
    ///a \\u002 0 space///
  ''', '''
    [stdin]:1:6: error: invalid escape sequence \\u002 
    ///a \\u002 0 space///
         ^\^^^^^
  '''
  assertErrorFormat '''
    ///a
      #{b} \\x0
     c///
  ''', '''
    [stdin]:2:8: error: invalid escape sequence \\x0
      #{b} \\x0
           ^\^^
  '''
  assertErrorFormat '''
    /ab\\u/
  ''', '''
    [stdin]:1:4: error: invalid escape sequence \\u
    /ab\\u/
       ^\^
  '''

test "illegal herecomment", ->
  assertErrorFormat '''
    ###
      Regex: /a*/g
    ###
  ''', '''
    [stdin]:2:12: error: block comments cannot contain */
      Regex: /a*/g
               ^^
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
       ^^
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
       ^^^^
  '''
  assertErrorFormat '''
    /a/g_
  ''', '''
    [stdin]:1:4: error: invalid regular expression flags g_
    /a/g_
       ^^
  '''
  assertErrorFormat '''
    ///a///ii
  ''', '''
    [stdin]:1:8: error: invalid regular expression flags ii
    ///a///ii
           ^^
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

test "reserved words", ->
  assertErrorFormat '''
    case
  ''', '''
    [stdin]:1:1: error: reserved word 'case'
    case
    ^^^^
  '''
  assertErrorFormat '''
    for = 1
  ''', '''
    [stdin]:1:1: error: reserved word 'for' can't be assigned
    for = 1
    ^^^
  '''
  # #2306: Show unaliased name in error messages.
  assertErrorFormat '''
    on = 1
  ''', '''
    [stdin]:1:1: error: reserved word 'on' can't be assigned
    on = 1
    ^^
  '''

test "invalid numbers", ->
  assertErrorFormat '''
    0X0
  ''', '''
    [stdin]:1:2: error: radix prefix in '0X0' must be lowercase
    0X0
     ^
  '''
  assertErrorFormat '''
    10E0
  ''', '''
    [stdin]:1:3: error: exponential notation in '10E0' must be indicated with a lowercase 'e'
    10E0
      ^
  '''
  assertErrorFormat '''
    018
  ''', '''
    [stdin]:1:1: error: decimal literal '018' must not be prefixed with '0'
    018
    ^^^
  '''
  assertErrorFormat '''
    010
  ''', '''
    [stdin]:1:1: error: octal literal '010' must be prefixed with '0o'
    010
    ^^^
'''

test "unexpected object keys", ->
  assertErrorFormat '''
    {[[]]}
  ''', '''
    [stdin]:1:2: error: unexpected [
    {[[]]}
     ^
  '''
  assertErrorFormat '''
    {[[]]: 1}
  ''', '''
    [stdin]:1:2: error: unexpected [
    {[[]]: 1}
     ^
  '''
  assertErrorFormat '''
    [[]]: 1
  ''', '''
    [stdin]:1:1: error: unexpected [
    [[]]: 1
    ^
  '''
  assertErrorFormat '''
    {(a + "b")}
  ''', '''
    [stdin]:1:2: error: unexpected (
    {(a + "b")}
     ^
  '''
  assertErrorFormat '''
    {(a + "b"): 1}
  ''', '''
    [stdin]:1:2: error: unexpected (
    {(a + "b"): 1}
     ^
  '''
  assertErrorFormat '''
    (a + "b"): 1
  ''', '''
    [stdin]:1:1: error: unexpected (
    (a + "b"): 1
    ^
  '''
  assertErrorFormat '''
    a: 1, [[]]: 2
  ''', '''
    [stdin]:1:7: error: unexpected [
    a: 1, [[]]: 2
          ^
  '''
  assertErrorFormat '''
    {a: 1, [[]]: 2}
  ''', '''
    [stdin]:1:8: error: unexpected [
    {a: 1, [[]]: 2}
           ^
  '''

test "invalid object keys", ->
  assertErrorFormat '''
    @a: 1
  ''', '''
    [stdin]:1:1: error: invalid object key
    @a: 1
    ^^
  '''
  assertErrorFormat '''
    f
      @a: 1
  ''', '''
    [stdin]:2:3: error: invalid object key
      @a: 1
      ^^
  '''
  assertErrorFormat '''
    {a=2}
  ''', '''
    [stdin]:1:3: error: unexpected =
    {a=2}
      ^
  '''

test "invalid destructuring default target", ->
  assertErrorFormat '''
    {'a' = 2} = obj
  ''', '''
    [stdin]:1:6: error: unexpected =
    {'a' = 2} = obj
         ^
  '''

test "#4070: lone expansion", ->
  assertErrorFormat '''
    [...] = a
  ''', '''
    [stdin]:1:2: error: Destructuring assignment has no target
    [...] = a
     ^^^
  '''
  assertErrorFormat '''
    [ ..., ] = a
  ''', '''
    [stdin]:1:3: error: Destructuring assignment has no target
    [ ..., ] = a
      ^^^
  '''

test "#3926: implicit object in parameter list", ->
  assertErrorFormat '''
    (a: b) ->
  ''', '''
    [stdin]:1:3: error: unexpected :
    (a: b) ->
      ^
  '''
  assertErrorFormat '''
    (one, two, {three, four: five}, key: value) ->
  ''', '''
    [stdin]:1:36: error: unexpected :
    (one, two, {three, four: five}, key: value) ->
                                       ^
  '''
