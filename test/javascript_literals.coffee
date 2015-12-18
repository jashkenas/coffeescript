# Javascript Literals
# -------------------

# TODO: refactor javascript literal tests
# TODO: add indexing and method invocation tests: `[1]`[0] is 1, `function(){}`.call()

eq '\\`', `
  // Inline JS
  "\\\`"
`

toJS = (str)->
  CoffeeScript.compile str, bare: true
  .replace /^\s+|\s+$/g, ""

test "regular JS literal import statement", ->
  input = '`import { member as alias } from "module-name"`'
  output = 'import { member as alias } from "module-name";'
  eq toJS(input), output

test "module import test, syntax #1", ->
  input = "import foo from 'lib'"
  output = "import foo from 'lib';"
  eq toJS(input), output

test "module import test, syntax #2", ->
  input = "import { foo } from 'lib'"
  output = "import { foo } from 'lib';"
  eq toJS(input), output

test "module import test, syntax #3", ->
  input = "import { default as foo } from 'lib'"
  output = "import { default as foo } from 'lib';"
  eq toJS(input), output

test "module import test, syntax #4", ->
  input = "import { square, diag } from 'lib'"
  output = "import { square, diag } from 'lib';"
  eq toJS(input), output

test "module import test, syntax #5", ->
  input = "import { foo } from 'lib' # with a comment"
  output = "import { foo } from 'lib' ;"
  eq toJS(input), output

test "module export test, syntax #1", ->
  input = "export default mixin"
  output = "export default mixin;"
  eq toJS(input), output

test "module export test, syntax #2", ->
  input = "export { D as default }"
  output = "export { D as default };"
  eq toJS(input), output

test "module export test, syntax #3", ->
  input = "export const sqrt = Math.sqrt"
  output = "export const sqrt = Math.sqrt;"
  eq toJS(input), output
