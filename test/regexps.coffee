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
  eq 2, 4 / 2 / 1

  a = 4
  b = 2
  g = 1
  eq 2, a / b/g

  a = 10
  b = a /= 4 / 2
  eq a, 5

  obj = method: -> 2
  two = 2
  eq 2, (obj.method()/two + obj.method()/two)

  i = 1
  eq 2, (4)/2/i
  eq 1, i/i/i

test "#764: regular expressions should be indexable", ->
  eq /0/['source'], ///#{0}///['source']

test "#584: slashes are allowed unescaped in character classes", ->
  ok /^a\/[/]b$/.test 'a//b'


# Heregexe(n|s)

test "a heregex will ignore whitespace and comments", ->
  eq /^I'm\x20+[a]\s+Heregex?\/\/\//gim + '', ///
    ^ I'm \x20+ [a] \s+
    Heregex? / // # or not
  ///gim + ''

test "an empty heregex will compile to an empty, non-capturing group", ->
  eq /(?:)/ + '', ///  /// + ''

test "=~ operator", ->
  m = '3-4' =~ /^\d+-(\d+)$/
  ok \& is '3-4'
  ok \1 is '4'
  ok m is \~
  ok m[0] is \~[0]
  ok m[1] is \1

