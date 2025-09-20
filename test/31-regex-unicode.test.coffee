# Test Advanced Regex Features

test "regex with all flags", ->
  # Test global, ignoreCase, multiline, sticky, unicode flags
  regex = /test/gimuy
  ok regex.global
  ok regex.ignoreCase
  ok regex.multiline
  ok regex.sticky
  ok regex.unicode

test "regex dotAll flag", ->
  # The 's' flag makes . match newlines
  regex = /test.+end/s
  ok regex.test("test\nsome\ntext\nend")
  
  withoutS = /test.+end/
  ok not withoutS.test("test\nsome\ntext\nend")

test "unicode in regex patterns", ->
  # Basic unicode escapes
  regex = /\u0041/  # Letter A
  ok regex.test("A")
  
  # Unicode flag for better unicode support
  unicodeRegex = /test/u
  ok unicodeRegex.unicode

test "unicode property escapes", ->
  # Match any letter using Unicode property
  letterRegex = /\p{Letter}/u
  ok letterRegex.test("a")
  ok letterRegex.test("α")  # Greek alpha
  ok letterRegex.test("中")  # Chinese character
  ok not letterRegex.test("1")
  
  # Match any digit
  digitRegex = /\p{Decimal_Number}/u
  ok digitRegex.test("5")
  ok not digitRegex.test("a")

test "named capture groups", ->
  # Named groups syntax
  regex = /(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})/
  match = "2024-03-15".match(regex)
  
  ok match?
  eq match.groups?.year, "2024"
  eq match.groups?.month, "03"
  eq match.groups?.day, "15"

test "regex with backreferences", ->
  # Backreference to capture group
  regex = /(test)\1/  # Matches 'testtest'
  ok regex.test("testtest")
  ok not regex.test("testother")
  
  # Simple backreference with numbers
  regex2 = /(\d+)-\1/  # Matches same number repeated
  ok regex2.test("123-123")
  ok not regex2.test("123-456")

test "regex lookahead and lookbehind", ->
  # Positive lookahead
  lookahead = /test(?=ing)/
  ok lookahead.test("testing")
  ok not lookahead.test("tested")
  
  # Negative lookahead
  negLookahead = /test(?!ing)/
  ok negLookahead.test("tested")
  ok not negLookahead.test("testing")
  
  # Positive lookbehind
  lookbehind = /(?<=hello)world/
  ok lookbehind.test("helloworld")
  ok not lookbehind.test("goodbyeworld")
  
  # Negative lookbehind
  negLookbehind = /(?<!hello)world/
  ok negLookbehind.test("goodbyeworld")
  ok not negLookbehind.test("helloworld")

test "regex with non-capturing groups", ->
  # Non-capturing group (?:...)
  regex = /(?:test|exam)-(\d+)/
  match = "test-123".match(regex)
  
  ok match?
  eq match[1], "123"  # Only the number is captured
  ok not match[2]?  # No second capture group

test "heregex with unicode", ->
  # Multiline regex with unicode support
  regex = ///
    ^\p{Letter}+    # Start with letters
    \s+             # Whitespace
    \p{Number}+     # Followed by numbers
    $               # End of string
  ///u
  
  ok regex.test("hello 123")
  ok regex.test("世界 456")  # Chinese characters
  ok not regex.test("123 hello")  # Wrong order

test "regex exec with global flag", ->
  regex = /\d+/g
  text = "abc 123 def 456 ghi 789"
  
  match1 = regex.exec(text)
  eq match1?[0], "123"
  
  match2 = regex.exec(text)
  eq match2?[0], "456"
  
  match3 = regex.exec(text)
  eq match3?[0], "789"
  
  match4 = regex.exec(text)
  ok not match4?

test "regex replace with function", ->
  # Replace with a function
  text = "hello world"
  result = text.replace /(\w+)/g, (match, word) ->
    word.toUpperCase()
  
  eq result, "HELLO WORLD"

test "regex split with limit", ->
  text = "a,b,c,d,e"
  parts = text.split(/,/, 3)
  
  eq parts.length, 3
  eq parts[0], "a"
  eq parts[1], "b"
  eq parts[2], "c"
