# Regular Expression Literals
# ---------------------------

# TODO: add method invocation tests: /regex/.toString()

# * Regexen
# * Heregexen

test "basic regular expression literals", ->
  ok 'a'.match(/a/)
  ok 'a'.match /a/
  ok 'a'.match(/a/g)
  ok 'a'.match /a/g

test "division is not confused for a regular expression", ->
  # Any spacing around the slash is allowed when it cannot be a regex.
  eq 2, 4 / 2 / 1
  eq 2, 4/2/1
  eq 2, 4/ 2 / 1
  eq 2, 4 /2 / 1
  eq 2, 4 / 2/ 1
  eq 2, 4 / 2 /1
  eq 2, 4 /2/ 1

  a = (regex) -> regex.test 'a b c'
  a.valueOf = -> 4
  b = 2
  g = 1

  eq 2, a / b/g
  eq 2, a/ b/g
  eq 2, a / b/ g
  eq 2, a	/	b/g # Tabs.
  eq 2, a / b/g # Non-breaking spaces.
  eq true, a /b/g
  # Use parentheses to disambiguate.
  eq true, a(/ b/g)
  eq true, a(/ b/)
  eq true, a (/ b/)
  # Escape to disambiguate.
  eq true, a /\ b/g
  eq false, a	/\	b/g
  eq true, a /\ b/

  obj = method: -> 2
  two = 2
  eq 2, (obj.method()/two + obj.method()/two)

  i = 1
  eq 2, (4)/2/i
  eq 1, i/i/i

  a = ''
  a += ' ' until /   /.test a
  eq a, '   '

  a = if /=/.test '=' then yes else no
  eq a, yes

  a = if !/=/.test '=' then yes else no
  eq a, no

  #3182:
  match = 'foo=bar'.match /=/
  eq match[0], '='

  #3410:
  ok ' '.match(/ /)[0] is ' '


test "division vs regex after a callable token", ->
  b = 2
  g = 1
  r = (r) -> r.test 'b'

  a = 4
  eq 2, a / b/g
  eq 2, a/b/g
  eq 2, a/ b/g
  eq true, r /b/g
  eq 2, (1 + 3) / b/g
  eq 2, (1 + 3)/b/g
  eq 2, (1 + 3)/ b/g
  eq true, (r) /b/g
  eq 2, [4][0] / b/g
  eq 2, [4][0]/b/g
  eq 2, [4][0]/ b/g
  eq true, [r][0] /b/g
  eq 0.5, 4? / b/g
  eq 0.5, 4?/b/g
  eq 0.5, 4?/ b/g
  eq true, r? /b/g
  (->
    eq 2, @ / b/g
    eq 2, @/b/g
    eq 2, @/ b/g
  ).call 4
  (->
    eq true, @ /b/g
  ).call r
  (->
    eq 2, this / b/g
    eq 2, this/b/g
    eq 2, this/ b/g
  ).call 4
  (->
    eq true, this /b/g
  ).call r
  class A
    p: (regex) -> if regex then r regex else 4
  class B extends A
    p: ->
      eq 2, super / b/g
      eq 2, super/b/g
      eq 2, super/ b/g
      eq true, super /b/g
  new B().p()

test "always division and never regex after some tokens", ->
  b = 2
  g = 1

  eq 2, 4 / b/g
  eq 2, 4/b/g
  eq 2, 4/ b/g
  eq 2, 4 /b/g
  eq 2, "4" / b/g
  eq 2, "4"/b/g
  eq 2, "4"/ b/g
  eq 2, "4" /b/g
  eq 20, "4#{0}" / b/g
  eq 20, "4#{0}"/b/g
  eq 20, "4#{0}"/ b/g
  eq 20, "4#{0}" /b/g
  ok isNaN /a/ / b/g
  ok isNaN /a/i / b/g
  ok isNaN /a//b/g
  ok isNaN /a/i/b/g
  ok isNaN /a// b/g
  ok isNaN /a/i/ b/g
  ok isNaN /a/ /b/g
  ok isNaN /a/i /b/g
  eq 0.5, true / b/g
  eq 0.5, true/b/g
  eq 0.5, true/ b/g
  eq 0.5, true /b/g
  eq 0, false / b/g
  eq 0, false/b/g
  eq 0, false/ b/g
  eq 0, false /b/g
  eq 0, null / b/g
  eq 0, null/b/g
  eq 0, null/ b/g
  eq 0, null /b/g
  ok isNaN undefined / b/g
  ok isNaN undefined/b/g
  ok isNaN undefined/ b/g
  ok isNaN undefined /b/g
  ok isNaN {a: 4} / b/g
  ok isNaN {a: 4}/b/g
  ok isNaN {a: 4}/ b/g
  ok isNaN {a: 4} /b/g
  o = prototype: 4
  eq 2, o:: / b/g
  eq 2, o::/b/g
  eq 2, o::/ b/g
  eq 2, o:: /b/g
  i = 4
  eq 2.0, i++ / b/g
  eq 2.5, i++/b/g
  eq 3.0, i++/ b/g
  eq 3.5, i++ /b/g
  eq 4.0, i-- / b/g
  eq 3.5, i--/b/g
  eq 3.0, i--/ b/g
  eq 2.5, i-- /b/g

test "compound division vs regex", ->
  c = 4
  i = 2

  a = 10
  b = a /= c / i
  eq a, 5

  a = 10
  b = a /= c /i
  eq a, 5

  a = 10
  b = a	/=	c /i # Tabs.
  eq a, 5

  a = 10
  b = a /= c /i # Non-breaking spaces.
  eq a, 5

  a = 10
  b = a/= c /i
  eq a, 5

  a = 10
  b = a/=c/i
  eq a, 5

  a = (regex) -> regex.test '=C '
  b = a /=c /i
  eq b, true

  a = (regex) -> regex.test '= C '
  # Use parentheses to disambiguate.
  b = a(/= c /i)
  eq b, true
  b = a(/= c /)
  eq b, false
  b = a (/= c /)
  eq b, false
  # Escape to disambiguate.
  b = a /\= c /i
  eq b, true
  b = a /\= c /
  eq b, false

test "#764: regular expressions should be indexable", ->
  eq /0/['source'], ///#{0}///['source']

test "#584: slashes are allowed unescaped in character classes", ->
  ok /^a\/[/]b$/.test 'a//b'

test "does not allow to escape newlines", ->
  throws -> CoffeeScript.compile '/a\\\nb/'


# Heregexe(n|s)

test "a heregex will ignore whitespace and comments", ->
  eq /^I'm\x20+[a]\s+Heregex?\/\/\//gim + '', ///
    ^ I'm \x20+ [a] \s+
    Heregex? / // # or not
  ///gim + ''

test "an empty heregex will compile to an empty, non-capturing group", ->
  eq /(?:)/ + '', ///  /// + ''
  eq /(?:)/ + '', ////// + ''

test "heregex starting with slashes", ->
  ok /////a/\////.test ' //a// '

test '#2388: `///` in heregex interpolations', ->
  ok ///a#{///b///}c///.test ' /a/b/c/ '
  ws = ' \t'
  scan = (regex) -> regex.exec('\t  foo')[0]
  eq '/\t  /', /// #{scan /// [#{ws}]* ///} /// + ''

test "regexes are not callable", ->
  throws -> CoffeeScript.compile '/a/()'
  throws -> CoffeeScript.compile '///a#{b}///()'
  throws -> CoffeeScript.compile '/a/ 1'
  throws -> CoffeeScript.compile '///a#{b}/// 1'
  throws -> CoffeeScript.compile '''
    /a/
       k: v
  '''
  throws -> CoffeeScript.compile '''
    ///a#{b}///
       k: v
  '''

test "backreferences", ->
  ok /(a)(b)\2\1/.test 'abba'

test "#3795: Escape otherwise invalid characters", ->
  ok (/ /).test '\u2028'
  ok (/ /).test '\u2029'
  ok ///\ ///.test '\u2028'
  ok ///\ ///.test '\u2029'
  ok ///a b///.test 'ab' # The space is U+2028.
  ok ///a b///.test 'ab' # The space is U+2029.
  ok ///\0
      1///.test '\x001'

  a = 'a'
  ok ///#{a} b///.test 'ab' # The space is U+2028.
  ok ///#{a} b///.test 'ab' # The space is U+2029.
  ok ///#{a}\ ///.test 'a\u2028'
  ok ///#{a}\ ///.test 'a\u2029'
  ok ///#{a}\0
      1///.test 'a\x001'
