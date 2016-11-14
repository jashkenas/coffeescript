# Javascript Literals
# -------------------

# TODO: refactor javascript literal tests
# TODO: add indexing and method invocation tests: `[1]`[0] is 1, `function(){}`.call()

test "inline JavaScript is evaluated", ->
  eq '\\`', `
    // Inline JS
    "\\\`"
  `

test "escaped backticks are output correctly", ->
  `var a = 'foo\`bar';`
  eq a, 'foo`bar'

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
  eq d, 'foo`bar`'
