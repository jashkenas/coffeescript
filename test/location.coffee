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
  [aToken, equalsToken, numberToken] = tokens

  eq aToken[2].first_line, 0
  eq aToken[2].first_column, 0
  eq aToken[2].last_line, 0
  eq aToken[2].last_column, 0

  eq equalsToken[2].first_line, 0
  eq equalsToken[2].first_column, 2
  eq equalsToken[2].last_line, 0
  eq equalsToken[2].last_column, 2

  eq numberToken[2].first_line, 0
  eq numberToken[2].first_column, 4
  eq numberToken[2].last_line, 0
  eq numberToken[2].last_column, 5

test "Verify location of generated tokens (with indented first line)", ->
  tokens = CoffeeScript.tokens "  a = 83"

  eq tokens.length, 4
  [aToken, equalsToken, numberToken] = tokens

  eq aToken[2].first_line, 0
  eq aToken[2].first_column, 2
  eq aToken[2].last_line, 0
  eq aToken[2].last_column, 2
  eq aToken[2].range[0], 2
  eq aToken[2].range[1], 3

  eq equalsToken[2].first_line, 0
  eq equalsToken[2].first_column, 4
  eq equalsToken[2].last_line, 0
  eq equalsToken[2].last_column, 4

  eq numberToken[2].first_line, 0
  eq numberToken[2].first_column, 6
  eq numberToken[2].last_line, 0
  eq numberToken[2].last_column, 7

getMatchingTokens = (str, wantedTokens...) ->
  tokens = CoffeeScript.tokens str
  matchingTokens = []
  i = 0
  for token in tokens
    if token[1].replace(/^'|'$/g, '"') is wantedTokens[i]
      i++
      matchingTokens.push token
  eq wantedTokens.length, matchingTokens.length
  matchingTokens

test 'Verify locations in string interpolation (in "string")', ->
  [a, b, c] = getMatchingTokens '"a#{b}c"', '"a"', 'b', '"c"'

  eq a[2].first_line, 0
  eq a[2].first_column, 1
  eq a[2].last_line, 0
  eq a[2].last_column, 1

  eq b[2].first_line, 0
  eq b[2].first_column, 4
  eq b[2].last_line, 0
  eq b[2].last_column, 4

  eq c[2].first_line, 0
  eq c[2].first_column, 6
  eq c[2].last_line, 0
  eq c[2].last_column, 6

test 'Verify locations in string interpolation (in "string", multiple interpolation)', ->
  [a, b, c] = getMatchingTokens '"#{a}b#{c}"', 'a', '"b"', 'c'

  eq a[2].first_line, 0
  eq a[2].first_column, 3
  eq a[2].last_line, 0
  eq a[2].last_column, 3

  eq b[2].first_line, 0
  eq b[2].first_column, 5
  eq b[2].last_line, 0
  eq b[2].last_column, 5

  eq c[2].first_line, 0
  eq c[2].first_column, 8
  eq c[2].last_line, 0
  eq c[2].last_column, 8

test 'Verify locations in string interpolation (in "string", multiple interpolation and line breaks)', ->
  [a, b, c] = getMatchingTokens '"#{a}\nb\n#{c}"', 'a', '"\nb\n"', 'c'

  eq a[2].first_line, 0
  eq a[2].first_column, 3
  eq a[2].last_line, 0
  eq a[2].last_column, 3

  eq b[2].first_line, 0
  eq b[2].first_column, 5
  eq b[2].last_line, 1
  eq b[2].last_column, 1

  eq c[2].first_line, 2
  eq c[2].first_column, 2
  eq c[2].last_line, 2
  eq c[2].last_column, 2

test 'Verify locations in string interpolation (in "string", multiple interpolation and starting with line breaks)', ->
  [a, b, c] = getMatchingTokens '"\n#{a}\nb\n#{c}"', 'a', '"\nb\n"', 'c'

  eq a[2].first_line, 1
  eq a[2].first_column, 2
  eq a[2].last_line, 1
  eq a[2].last_column, 2

  eq b[2].first_line, 1
  eq b[2].first_column, 4
  eq b[2].last_line, 2
  eq b[2].last_column, 1

  eq c[2].first_line, 3
  eq c[2].first_column, 2
  eq c[2].last_line, 3
  eq c[2].last_column, 2

test 'Verify locations in string interpolation (in "string", multiple interpolation and starting with line breaks)', ->
  [a, b, c] = getMatchingTokens '"\n\n#{a}\n\nb\n\n#{c}"', 'a', '"\n\nb\n\n"', 'c'

  eq a[2].first_line, 2
  eq a[2].first_column, 2
  eq a[2].last_line, 2
  eq a[2].last_column, 2

  eq b[2].first_line, 2
  eq b[2].first_column, 4
  eq b[2].last_line, 5
  eq b[2].last_column, 0

  eq c[2].first_line, 6
  eq c[2].first_column, 2
  eq c[2].last_line, 6
  eq c[2].last_column, 2

test 'Verify locations in string interpolation (in "string", multiple interpolation and starting with line breaks)', ->
  [a, b, c] = getMatchingTokens '"\n\n\n#{a}\n\n\nb\n\n\n#{c}"', 'a', '"\n\n\nb\n\n\n"', 'c'

  eq a[2].first_line, 3
  eq a[2].first_column, 2
  eq a[2].last_line, 3
  eq a[2].last_column, 2

  eq b[2].first_line, 3
  eq b[2].first_column, 4
  eq b[2].last_line, 8
  eq b[2].last_column, 0

  eq c[2].first_line, 9
  eq c[2].first_column, 2
  eq c[2].last_line, 9
  eq c[2].last_column, 2

test 'Verify locations in string interpolation (in """string""", line breaks)', ->
  [a, b, c] = getMatchingTokens '"""a\n#{b}\nc"""', '"a\n"', 'b', '"\nc"'

  eq a[2].first_line, 0
  eq a[2].first_column, 3
  eq a[2].last_line, 0
  eq a[2].last_column, 4

  eq b[2].first_line, 1
  eq b[2].first_column, 2
  eq b[2].last_line, 1
  eq b[2].last_column, 2

  eq c[2].first_line, 1
  eq c[2].first_column, 4
  eq c[2].last_line, 2
  eq c[2].last_column, 0

test 'Verify locations in string interpolation (in """string""", starting with a line break)', ->
  [b, c] = getMatchingTokens '"""\n#{b}\nc"""', 'b', '"\nc"'

  eq b[2].first_line, 1
  eq b[2].first_column, 2
  eq b[2].last_line, 1
  eq b[2].last_column, 2

  eq c[2].first_line, 1
  eq c[2].first_column, 4
  eq c[2].last_line, 2
  eq c[2].last_column, 0

test 'Verify locations in string interpolation (in """string""", starting with line breaks)', ->
  [a, b, c] = getMatchingTokens '"""\n\n#{b}\nc"""', '"\n\n"', 'b', '"\nc"'

  eq a[2].first_line, 0
  eq a[2].first_column, 3
  eq a[2].last_line, 1
  eq a[2].last_column, 0

  eq b[2].first_line, 2
  eq b[2].first_column, 2
  eq b[2].last_line, 2
  eq b[2].last_column, 2

  eq c[2].first_line, 2
  eq c[2].first_column, 4
  eq c[2].last_line, 3
  eq c[2].last_column, 0

test 'Verify locations in string interpolation (in """string""", multiple interpolation)', ->
  [a, b, c] = getMatchingTokens '"""#{a}\nb\n#{c}"""', 'a', '"\nb\n"', 'c'

  eq a[2].first_line, 0
  eq a[2].first_column, 5
  eq a[2].last_line, 0
  eq a[2].last_column, 5

  eq b[2].first_line, 0
  eq b[2].first_column, 7
  eq b[2].last_line, 1
  eq b[2].last_column, 1

  eq c[2].first_line, 2
  eq c[2].first_column, 2
  eq c[2].last_line, 2
  eq c[2].last_column, 2

test 'Verify locations in string interpolation (in """string""", multiple interpolation, and starting with line breaks)', ->
  [a, b, c] = getMatchingTokens '"""\n\n#{a}\n\nb\n\n#{c}"""', 'a', '"\n\nb\n\n"', 'c'

  eq a[2].first_line, 2
  eq a[2].first_column, 2
  eq a[2].last_line, 2
  eq a[2].last_column, 2

  eq b[2].first_line, 2
  eq b[2].first_column, 4
  eq b[2].last_line, 5
  eq b[2].last_column, 0

  eq c[2].first_line, 6
  eq c[2].first_column, 2
  eq c[2].last_line, 6
  eq c[2].last_column, 2

test 'Verify locations in string interpolation (in """string""", multiple interpolation, and starting with line breaks)', ->
  [a, b, c] = getMatchingTokens '"""\n\n\n#{a}\n\n\nb\n\n\n#{c}"""', 'a', '"\n\n\nb\n\n\n"', 'c'

  eq a[2].first_line, 3
  eq a[2].first_column, 2
  eq a[2].last_line, 3
  eq a[2].last_column, 2

  eq b[2].first_line, 3
  eq b[2].first_column, 4
  eq b[2].last_line, 8
  eq b[2].last_column, 0

  eq c[2].first_line, 9
  eq c[2].first_column, 2
  eq c[2].last_line, 9
  eq c[2].last_column, 2

test 'Verify locations in heregex interpolation (in ///regex///, multiple interpolation)', ->
  [a, b, c] = getMatchingTokens '///#{a}b#{c}///', 'a', '"b"', 'c'

  eq a[2].first_line, 0
  eq a[2].first_column, 5
  eq a[2].last_line, 0
  eq a[2].last_column, 5

  eq b[2].first_line, 0
  eq b[2].first_column, 7
  eq b[2].last_line, 0
  eq b[2].last_column, 7

  eq c[2].first_line, 0
  eq c[2].first_column, 10
  eq c[2].last_line, 0
  eq c[2].last_column, 10

test 'Verify locations in heregex interpolation (in ///regex///, multiple interpolation)', ->
  [a, b, c] = getMatchingTokens '///a#{b}c///', '"a"', 'b', '"c"'

  eq a[2].first_line, 0
  eq a[2].first_column, 3
  eq a[2].last_line, 0
  eq a[2].last_column, 3

  eq b[2].first_line, 0
  eq b[2].first_column, 6
  eq b[2].last_line, 0
  eq b[2].last_column, 6

  eq c[2].first_line, 0
  eq c[2].first_column, 8
  eq c[2].last_line, 0
  eq c[2].last_column, 8

test 'Verify locations in heregex interpolation (in ///regex///, multiple interpolation and line breaks)', ->
  [a, b, c] = getMatchingTokens '///#{a}\nb\n#{c}///', 'a', '"\nb\n"', 'c'

  eq a[2].first_line, 0
  eq a[2].first_column, 5
  eq a[2].last_line, 0
  eq a[2].last_column, 5

  eq b[2].first_line, 0
  eq b[2].first_column, 7
  eq b[2].last_line, 1
  eq b[2].last_column, 1

  eq c[2].first_line, 2
  eq c[2].first_column, 2
  eq c[2].last_line, 2
  eq c[2].last_column, 2

test 'Verify locations in heregex interpolation (in ///regex///, multiple interpolation and line breaks)', ->
  [a, b, c] = getMatchingTokens '///#{a}\n\n\nb\n\n\n#{c}///', 'a', '"\n\n\nb\n\n\n"', 'c'

  eq a[2].first_line, 0
  eq a[2].first_column, 5
  eq a[2].last_line, 0
  eq a[2].last_column, 5

  eq b[2].first_line, 0
  eq b[2].first_column, 7
  eq b[2].last_line, 5
  eq b[2].last_column, 0

  eq c[2].first_line, 6
  eq c[2].first_column, 2
  eq c[2].last_line, 6
  eq c[2].last_column, 2

test 'Verify locations in heregex interpolation (in ///regex///, multiple interpolation and line breaks)', ->
  [a, b, c] = getMatchingTokens '///a\n\n\n#{b}\n\n\nc///', '"a\n\n\n"', 'b', '"\n\n\nc"'

  eq a[2].first_line, 0
  eq a[2].first_column, 3
  eq a[2].last_line, 2
  eq a[2].last_column, 0

  eq b[2].first_line, 3
  eq b[2].first_column, 2
  eq b[2].last_line, 3
  eq b[2].last_column, 2

  eq c[2].first_line, 3
  eq c[2].first_column, 4
  eq c[2].last_line, 6
  eq c[2].last_column, 0

test 'Verify locations in heregex interpolation (in ///regex///, multiple interpolation and line breaks and starting with linebreak)', ->
  [a, b, c] = getMatchingTokens '///\n#{a}\nb\n#{c}///', 'a', '"\nb\n"', 'c'

  eq a[2].first_line, 1
  eq a[2].first_column, 2
  eq a[2].last_line, 1
  eq a[2].last_column, 2

  eq b[2].first_line, 1
  eq b[2].first_column, 4
  eq b[2].last_line, 2
  eq b[2].last_column, 1

  eq c[2].first_line, 3
  eq c[2].first_column, 2
  eq c[2].last_line, 3
  eq c[2].last_column, 2

test 'Verify locations in heregex interpolation (in ///regex///, multiple interpolation and line breaks and starting with linebreak)', ->
  [a, b, c] = getMatchingTokens '///\n\n\n#{a}\n\n\nb\n\n\n#{c}///', 'a', '"\n\n\nb\n\n\n"', 'c'

  eq a[2].first_line, 3
  eq a[2].first_column, 2
  eq a[2].last_line, 3
  eq a[2].last_column, 2

  eq b[2].first_line, 3
  eq b[2].first_column, 4
  eq b[2].last_line, 8
  eq b[2].last_column, 0

  eq c[2].first_line, 9
  eq c[2].first_column, 2
  eq c[2].last_line, 9
  eq c[2].last_column, 2

test 'Verify locations in heregex interpolation (in ///regex///, multiple interpolation and line breaks and starting with linebreak)', ->
  [a, b, c] = getMatchingTokens '///\n\n\na\n\n\n#{b}\n\n\nc///', '"\n\n\na\n\n\n"', 'b', '"\n\n\nc"'

  eq a[2].first_line, 0
  eq a[2].first_column, 3
  eq a[2].last_line, 5
  eq a[2].last_column, 0

  eq b[2].first_line, 6
  eq b[2].first_column, 2
  eq b[2].last_line, 6
  eq b[2].last_column, 2

  eq c[2].first_line, 6
  eq c[2].first_column, 4
  eq c[2].last_line, 9
  eq c[2].last_column, 0

test "#3822: Simple string/regex start/end should include delimiters", ->
  [stringToken] = CoffeeScript.tokens "'string'"
  eq stringToken[2].first_line, 0
  eq stringToken[2].first_column, 0
  eq stringToken[2].last_line, 0
  eq stringToken[2].last_column, 7

  [regexToken] = CoffeeScript.tokens "/regex/"
  eq regexToken[2].first_line, 0
  eq regexToken[2].first_column, 0
  eq regexToken[2].last_line, 0
  eq regexToken[2].last_column, 6

test "#3621: Multiline regex and manual `Regex` call with interpolation should
      result in the same tokens", ->
  tokensA = CoffeeScript.tokens '(RegExp(".*#{a}[0-9]"))'
  tokensB = CoffeeScript.tokens '///.*#{a}[0-9]///'
  eq tokensA.length, tokensB.length
  for i in [0...tokensA.length] by 1
    tokenA = tokensA[i]
    tokenB = tokensB[i]
    eq tokenA[0], tokenB[0] unless tokenB[0] in ['REGEX_START', 'REGEX_END']
    eq "#{tokenA[1]}", "#{tokenB[1]}"
    unless tokenA[0] is 'STRING_START' or tokenB[0] is 'REGEX_START'
      eq tokenA.origin?[1], tokenB.origin?[1]
    eq tokenA.stringEnd, tokenB.stringEnd

test "Verify tokens have locations that are in order", ->
  source = '''
    a {
      b: ->
        return c d,
          if e
            f
    }
    g
  '''
  tokens = CoffeeScript.tokens source
  lastToken = null
  for token in tokens
    if lastToken
      ok token[2].first_line >= lastToken[2].last_line
      if token[2].first_line == lastToken[2].last_line
        ok token[2].first_column >= lastToken[2].last_column
    lastToken = token

test "Verify OUTDENT tokens are located at the end of the previous token", ->
  source = '''
    SomeArr = [ ->
      if something
        lol =
          count: 500
    ]
  '''
  tokens = CoffeeScript.tokens source
  [..., number, curly, outdent1, outdent2, outdent3, bracket, terminator] = tokens
  eq number[0], 'NUMBER'
  for outdent in [outdent1, outdent2, outdent3]
    eq outdent[0], 'OUTDENT'
    eq outdent[2].first_line, number[2].last_line
    eq outdent[2].first_column, number[2].last_column
    eq outdent[2].last_line, number[2].last_line
    eq outdent[2].last_column, number[2].last_column

test "Verify OUTDENT and CALL_END tokens are located at the end of the previous token", ->
  source = '''
    a = b {
      c: ->
        d e,
          if f
            g {},
              if h
                i {}
    }
  '''
  tokens = CoffeeScript.tokens source
  [..., closeCurly1, callEnd1, outdent1, outdent2, callEnd2, outdent3, outdent4,
    callEnd3, outdent5, outdent6, closeCurly2, callEnd4, terminator] = tokens
  eq closeCurly1[0], '}'
  assertAtCloseCurly = (token) ->
    eq token[2].first_line, closeCurly1[2].last_line
    eq token[2].first_column, closeCurly1[2].last_column
    eq token[2].last_line, closeCurly1[2].last_line
    eq token[2].last_column, closeCurly1[2].last_column

  for token in [outdent1, outdent2, outdent3, outdent4, outdent5, outdent6]
    eq token[0], 'OUTDENT'
    assertAtCloseCurly(token)
  for token in [callEnd1, callEnd2, callEnd3]
    eq token[0], 'CALL_END'
    assertAtCloseCurly(token)

test "Verify generated } tokens are located at the end of the previous token", ->
  source = '''
    a(b, ->
      c: () ->
        if d
          e
    )
  '''
  tokens = CoffeeScript.tokens source
  [..., identifier, outdent1, outdent2, closeCurly, outdent3, callEnd,
    terminator] = tokens
  eq identifier[0], 'IDENTIFIER'
  assertAtIdentifier = (token) ->
    eq token[2].first_line, identifier[2].last_line
    eq token[2].first_column, identifier[2].last_column
    eq token[2].last_line, identifier[2].last_line
    eq token[2].last_column, identifier[2].last_column

  for token in [outdent1, outdent2, closeCurly, outdent3]
    assertAtIdentifier(token)

test "Verify real CALL_END tokens have the right position", ->
  source = '''
    a()
  '''
  tokens = CoffeeScript.tokens source
  [identifier, callStart, callEnd, terminator] = tokens
  startIndex = identifier[2].first_column
  eq identifier[2].last_column, startIndex
  eq callStart[2].first_column, startIndex + 1
  eq callStart[2].last_column, startIndex + 1
  eq callEnd[2].first_column, startIndex + 2
  eq callEnd[2].last_column, startIndex + 2

test "Verify normal heredocs have the right position", ->
  source = '''
    """
    a"""
  '''
  [stringToken] = CoffeeScript.tokens source
  eq stringToken[2].first_line, 0
  eq stringToken[2].first_column, 0
  eq stringToken[2].last_line, 1
  eq stringToken[2].last_column, 3

test "Verify heredocs ending with a newline have the right position", ->
  source = '''
    """
    a
    """
  '''
  [stringToken] = CoffeeScript.tokens source
  eq stringToken[2].first_line, 0
  eq stringToken[2].first_column, 0
  eq stringToken[2].last_line, 2
  eq stringToken[2].last_column, 2

test "Verify indented heredocs have the right position", ->
  source = '''
    ->
      """
        a
      """
  '''
  [arrow, indent, stringToken] = CoffeeScript.tokens source
  eq stringToken[2].first_line, 1
  eq stringToken[2].first_column, 2
  eq stringToken[2].last_line, 3
  eq stringToken[2].last_column, 4

test "Verify heregexes with interpolations have the right ending position", ->
  source = '''
    [a ///#{b}///g]
  '''
  [..., stringEnd, comma, flagsString, regexCallEnd, regexEnd, fnCallEnd,
    arrayEnd, terminator] = CoffeeScript.tokens source

  eq comma[0], ','
  eq arrayEnd[0], ']'

  assertColumn = (token, column, width = 0) ->
    eq token[2].first_line, 0
    eq token[2].first_column, column
    eq token[2].last_line, 0
    eq token[2].last_column, column
    eq token[2].last_column_exclusive, column + width

  arrayEndColumn = arrayEnd[2].first_column
  for token in [comma]
    assertColumn token, arrayEndColumn - 2
  for token in [flagsString, regexCallEnd]
    assertColumn token, arrayEndColumn - 1, 1
  for token in [regexEnd, fnCallEnd]
    assertColumn token, arrayEndColumn
  assertColumn arrayEnd, arrayEndColumn, 1

test "Verify all tokens get a location", ->
  doesNotThrow ->
    tokens = CoffeeScript.tokens testScript
    for token in tokens
        ok !!token[2]

test 'Values with properties end up with a location that includes the properties', ->
  source = '''
    a.b
    a.b.c
    a['b']
    a[b.c()].d
  '''
  {body: block} = CoffeeScript.nodes source
  [
    singleProperty
    twoProperties
    indexed
    complexIndex
  ] = block.expressions

  eq singleProperty.locationData.first_line, 0
  eq singleProperty.locationData.first_column, 0
  eq singleProperty.locationData.last_line, 0
  eq singleProperty.locationData.last_column, 2

  eq twoProperties.locationData.first_line, 1
  eq twoProperties.locationData.first_column, 0
  eq twoProperties.locationData.last_line, 1
  eq twoProperties.locationData.last_column, 4

  eq indexed.locationData.first_line, 2
  eq indexed.locationData.first_column, 0
  eq indexed.locationData.last_line, 2
  eq indexed.locationData.last_column, 5

  eq complexIndex.locationData.first_line, 3
  eq complexIndex.locationData.first_column, 0
  eq complexIndex.locationData.last_line, 3
  eq complexIndex.locationData.last_column, 9

test 'StringWithInterpolations::fromStringLiteral() assigns correct location to tagged template literal', ->
  checkLocationData = (source, {stringWithInterpolationsLocationData, stringLocationData}) ->
    {body: block} = CoffeeScript.nodes source
    taggedTemplateLiteral = block.expressions[0].unwrap()
    {args: [stringWithInterpolations]} = taggedTemplateLiteral
    {body} = stringWithInterpolations
    {expressions: [stringValue]} = body
    string = stringValue.unwrap()

    for field in ['first_line', 'first_column', 'last_line', 'last_column', 'last_line_exclusive', 'last_column_exclusive']
      eq stringWithInterpolations.locationData[field], stringWithInterpolationsLocationData[field]
      eq stringValue.locationData[field], stringLocationData[field]
      eq string.locationData[field], stringLocationData[field]

  checkLocationData 'a"b"',
    stringWithInterpolationsLocationData:
      first_line: 0
      first_column: 1
      last_line: 0
      last_column: 3
      last_line_exclusive: 0
      last_column_exclusive: 4
    stringLocationData:
      first_line: 0
      first_column: 2
      last_line: 0
      last_column: 2
      last_line_exclusive: 0
      last_column_exclusive: 3

  checkLocationData '''
    a"""
      b
    """
  ''',
    stringWithInterpolationsLocationData:
      first_line: 0
      first_column: 1
      last_line: 2
      last_column: 2
      last_line_exclusive: 2
      last_column_exclusive: 3
    stringLocationData:
      first_line: 0
      first_column: 4
      last_line: 1
      last_column: 3
      last_line_exclusive: 2
      last_column_exclusive: 0

  checkLocationData '''
    a"""b
    """
  ''',
    stringWithInterpolationsLocationData:
      first_line: 0
      first_column: 1
      last_line: 1
      last_column: 2
      last_line_exclusive: 1
      last_column_exclusive: 3
    stringLocationData:
      first_line: 0
      first_column: 4
      last_line: 0
      last_column: 5
      last_line_exclusive: 1
      last_column_exclusive: 0

test "Verify compound assignment operators have the right position", ->
  source = '''
    a or= b
  '''
  [a, operatorToken] = CoffeeScript.tokens source
  eq operatorToken[2].first_line, 0
  eq operatorToken[2].first_column, 2
  eq operatorToken[2].last_line, 0
  eq operatorToken[2].last_column, 4
  eq operatorToken[2].last_column_exclusive, 5
  eq operatorToken[2].range[0], 2
  eq operatorToken[2].range[1], 5

  source = '''
    a and= b
  '''
  [a, operatorToken] = CoffeeScript.tokens source
  eq operatorToken[2].first_line, 0
  eq operatorToken[2].first_column, 2
  eq operatorToken[2].last_line, 0
  eq operatorToken[2].last_column, 5
  eq operatorToken[2].last_column_exclusive, 6
  eq operatorToken[2].range[0], 2
  eq operatorToken[2].range[1], 6

test "Verify BOM is accounted for in location data", ->
  source = '''
    \ufeffa
    b
  '''
  [aToken, terminator, bToken] = CoffeeScript.tokens source
  eq aToken[2].first_line, 0
  eq aToken[2].first_column, 1
  eq aToken[2].last_line, 0
  eq aToken[2].last_column, 1
  eq aToken[2].last_column_exclusive, 2
  eq aToken[2].range[0], 1
  eq aToken[2].range[1], 2
  eq bToken[2].first_line, 1
  eq bToken[2].first_column, 0
  eq bToken[2].last_line, 1
  eq bToken[2].last_column, 0
  eq bToken[2].last_column_exclusive, 1
  eq bToken[2].range[0], 3
  eq bToken[2].range[1], 4

test "Verify carriage returns are accounted for in location data", ->
  source = '''
    a\r+
    b\r\r- c
  '''
  [aToken, plusToken, bToken, minusToken] = CoffeeScript.tokens source
  eq aToken[2].first_line, 0
  eq aToken[2].first_column, 0
  eq aToken[2].last_line, 0
  eq aToken[2].last_column, 0
  eq aToken[2].last_column_exclusive, 1
  eq aToken[2].range[0], 0
  eq aToken[2].range[1], 1
  eq plusToken[2].first_line, 0
  eq plusToken[2].first_column, 2
  eq plusToken[2].last_line, 0
  eq plusToken[2].last_column, 2
  eq plusToken[2].last_column_exclusive, 3
  eq plusToken[2].range[0], 2
  eq plusToken[2].range[1], 3
  eq bToken[2].first_line, 1
  eq bToken[2].first_column, 0
  eq bToken[2].last_line, 1
  eq bToken[2].last_column, 0
  eq bToken[2].last_column_exclusive, 1
  eq bToken[2].range[0], 4
  eq bToken[2].range[1], 5
  eq minusToken[2].first_line, 1
  eq minusToken[2].first_column, 3
  eq minusToken[2].last_line, 1
  eq minusToken[2].last_column, 3
  eq minusToken[2].last_column_exclusive, 4
  eq minusToken[2].range[0], 7
  eq minusToken[2].range[1], 8

test "Verify object colon location data", ->
  source = '''
    a : b
  '''
  [implicitBraceToken, aToken, colonToken] = CoffeeScript.tokens source
  eq colonToken[2].first_line, 0
  eq colonToken[2].first_column, 2
  eq colonToken[2].last_line, 0
  eq colonToken[2].last_column, 2
  eq colonToken[2].last_column_exclusive, 3
  eq colonToken[2].range[0], 2
  eq colonToken[2].range[1], 3
