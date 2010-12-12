# Regular Expressions
# -------------------
#TODO: add some rigorous regex interpolation tests

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

  obj = method: -> 2
  two = 2
  eq 2, (obj.method()/two + obj.method()/two)

  i = 1
  eq 2, (4)/2/i
  eq 1, i/i/i

test "backslash escapes", ->
  eq "\\/\\\\", /\/\\/.source

test "#764: regular expressions should be indexable", ->
  eq /0/['source'], ///#{0}///['source']

test "#584: slashes are allowed unescaped in character classes", ->
  ok /^a\/[/]b$/.test 'a//b'


#### Heregexe(n|s)

test "a heregex will ignore whitespace and comments", ->
  eq /^I'm\x20+[a]\s+Heregex?\/\/\//gim + '', ///
    ^ I'm \x20+ [a] \s+
    Heregex? / // # or not
  ///gim + ''

test "heregex interpolation", ->
  eq /\\#{}\\\"/ + '', ///
   #{
     "#{ '\\' }" # normal comment
   }
   # regex comment
   \#{}
   \\ \"
  /// + ''

test "an empty heregex will compile to an empty, non-capturing group", ->
  eq /(?:)/ + '', ///  /// + ''
