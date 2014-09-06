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

  eq tokens.length, 4
  [aToken, equalsToken, numberToken] = tokens

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

test 'Verify locations in string interpolation (in "string")', ->
  tokens = CoffeeScript.tokens '"a#{b}c"'

  eq tokens.length, 8
  [openParen, a, firstPlus, b, secondPlus, c, closeParen] = tokens

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
  tokens = CoffeeScript.tokens '"#{a}b#{c}"'

  eq tokens.length, 10
  [{}, {}, {}, a, {}, b, {}, c] = tokens

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
  tokens = CoffeeScript.tokens '"#{a}\nb\n#{c}"'

  eq tokens.length, 10
  [{}, {}, {}, a, {}, b, {}, c] = tokens

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
  tokens = CoffeeScript.tokens '"\n#{a}\nb\n#{c}"'

  eq tokens.length, 10
  [{}, {}, {}, a, {}, b, {}, c] = tokens

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
  tokens = CoffeeScript.tokens '"\n\n#{a}\n\nb\n\n#{c}"'

  eq tokens.length, 10
  [{}, {}, {}, a, {}, b, {}, c] = tokens

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
  tokens = CoffeeScript.tokens '"\n\n\n#{a}\n\n\nb\n\n\n#{c}"'

  eq tokens.length, 10
  [{}, {}, {}, a, {}, b, {}, c] = tokens

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
  tokens = CoffeeScript.tokens '"""a\n#{b}\nc"""'

  eq tokens.length, 8
  [{}, a, {}, b, {}, c, {}, {}] = tokens

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
  tokens = CoffeeScript.tokens '"""\n#{b}\nc"""'

  eq tokens.length, 8
  [{}, a, {}, b, {}, c] = tokens

  eq a[2].first_line, 0
  eq a[2].first_column, 0
  eq a[2].last_line, 0
  eq a[2].last_column, 0

  eq b[2].first_line, 1
  eq b[2].first_column, 2
  eq b[2].last_line, 1
  eq b[2].last_column, 2

  eq c[2].first_line, 1
  eq c[2].first_column, 4
  eq c[2].last_line, 2
  eq c[2].last_column, 0

test 'Verify locations in string interpolation (in """string""", starting with line breaks)', ->
  tokens = CoffeeScript.tokens '"""\n\n#{b}\nc"""'

  eq tokens.length, 8
  [{}, a, {}, b, {}, c] = tokens

  eq a[2].first_line, 1
  eq a[2].first_column, 0
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
  tokens = CoffeeScript.tokens '"""#{a}\nb\n#{c}"""'

  eq tokens.length, 10
  [{}, {}, {}, a, {}, b, {}, c] = tokens

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
  tokens = CoffeeScript.tokens '"""\n\n#{a}\n\nb\n\n#{c}"""'

  eq tokens.length, 10
  [{}, {}, {}, a, {}, b, {}, c] = tokens

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
  tokens = CoffeeScript.tokens '"""\n\n\n#{a}\n\n\nb\n\n\n#{c}"""'

  eq tokens.length, 10
  [{}, {}, {}, a, {}, b, {}, c] = tokens

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
  tokens = CoffeeScript.tokens '///#{a}b#{c}///'

  eq tokens.length, 11
  [{}, {}, {}, {}, a, {}, b, {}, c] = tokens

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
  tokens = CoffeeScript.tokens '///a#{b}c///'

  eq tokens.length, 9
  [{}, {}, a, {}, b, {}, c] = tokens

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
  tokens = CoffeeScript.tokens '///#{a}\nb\n#{c}///'

  eq tokens.length, 11
  [{}, {}, {}, {}, a, {}, b, {}, c] = tokens

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
  tokens = CoffeeScript.tokens '///#{a}\n\n\nb\n\n\n#{c}///'

  eq tokens.length, 11
  [{}, {}, {}, {}, a, {}, b, {}, c] = tokens

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
  tokens = CoffeeScript.tokens '///a\n\n\n#{b}\n\n\nc///'

  eq tokens.length, 9
  [{}, {}, a, {}, b, {}, c] = tokens

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

test 'Verify locations in heregex interpolation (in ///regex///, multiple interpolation and line breaks and stating with linebreak)', ->
  tokens = CoffeeScript.tokens '///\n#{a}\nb\n#{c}///'

  eq tokens.length, 11
  [{}, {}, {}, {}, a, {}, b, {}, c] = tokens

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

test 'Verify locations in heregex interpolation (in ///regex///, multiple interpolation and line breaks and stating with linebreak)', ->
  tokens = CoffeeScript.tokens '///\n\n\n#{a}\n\n\nb\n\n\n#{c}///'

  eq tokens.length, 11
  [{}, {}, {}, {}, a, {}, b, {}, c] = tokens

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

test 'Verify locations in heregex interpolation (in ///regex///, multiple interpolation and line breaks and stating with linebreak)', ->
  tokens = CoffeeScript.tokens '///\n\n\na\n\n\n#{b}\n\n\nc///'

  eq tokens.length, 9
  [{}, {}, a, {}, b, {}, c] = tokens

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

test "Verify all tokens get a location", ->
  doesNotThrow ->
    tokens = CoffeeScript.tokens testScript
    for token in tokens
        ok !!token[2]
