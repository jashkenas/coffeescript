# JavaScript Literals
# -------------------

test "inline JavaScript is evaluated", ->
  eq '\\`', `
    // Inline JS
    "\\\\\`"
  `

test "escaped backticks are output correctly", ->
  `var a = \`2 + 2 = ${4}\``
  eq a, '2 + 2 = 4'

test "backslashes before a newline don’t break JavaScript blocks", ->
  `var a = \`To be, or not\\
  to be.\``
  eq a, '''
  To be, or not\\
    to be.'''

test "block inline JavaScript is evaluated", ->
  ```
  var a = 1;
  var b = 2;
  ```
  c = 3
  ```var d = 4;```
  eq a + b + c + d, 10

test "block inline JavaScript containing backticks", ->
  ```
  // This is a comment with `backticks`
  var a = 42;
  var b = `foo ${'bar'}`;
  var c = 3;
  var d = 'foo`bar`';
  ```
  eq a + c, 45
  eq b, 'foo bar'
  eq d, 'foo`bar`'

test "block JavaScript can end with an escaped backtick character", ->
  ```var a = \`hello\````
  ```
  var b = \`world${'!'}\````
  eq a, 'hello'
  eq b, 'world!'

test "JavaScript block only escapes backslashes followed by backticks", ->
  eq `'\\\n'`, '\\\n'

test "escaped JavaScript blocks speed round", ->
  # The following has escaped backslashes because they’re required in strings, but the intent is this:
  # `hello`                                       → hello;
  # `\`hello\``                                   → `hello`;
  # `\`Escaping backticks in JS: \\\`hello\\\`\`` → `Escaping backticks in JS: \`hello\``;
  # `Single backslash: \ `                        → Single backslash: \ ;
  # `Double backslash: \\ `                       → Double backslash: \\ ;
  # `Single backslash at EOS: \\`                 → Single backslash at EOS: \;
  # `Double backslash at EOS: \\\\`               → Double backslash at EOS: \\;
  for [input, output] in [
    ['`hello`',                                               'hello;']
    ['`\\`hello\\``',                                         '`hello`;']
    ['`\\`Escaping backticks in JS: \\\\\\`hello\\\\\\`\\``', '`Escaping backticks in JS: \\`hello\\``;']
    ['`Single backslash: \\ `',                               'Single backslash: \\ ;']
    ['`Double backslash: \\\\ `',                             'Double backslash: \\\\ ;']
    ['`Single backslash at EOS: \\\\`',                       'Single backslash at EOS: \\;']
    ['`Double backslash at EOS: \\\\\\\\`',                   'Double backslash at EOS: \\\\;']
  ]
    eqJS input, output
