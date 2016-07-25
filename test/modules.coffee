# Modules, a.k.a. ES2015 import/export
# ------------------------------------
#
# Remember, we’re not *resolving* modules, just outputting valid ES2015 syntax.


# Helper function
toJS = (str) ->
  CoffeeScript.compile str, bare: yes
  .replace /^\s+|\s+$/g, '' # Trim leading/trailing whitespace


# test "backticked import statement", ->
#   input = '`import { member as alias } from "module-name"`'
#   output = 'import { member as alias } from "module-name";'
#   eq toJS(input), output

test "import module", ->
  input = "import 'module-name'"
  output = "import 'module-name';"
  # console.log toJS input
  eq toJS(input), output

# test "module import test, syntax #1", ->
#   input = "import foo from 'lib'"
#   output = "import foo from 'lib';"
#   eq toJS(input), output

# test "module import test, syntax #2", ->
#   input = "import { foo } from 'lib'"
#   output = "import { foo } from 'lib';"
#   eq toJS(input), output

# test "module import test, syntax #3", ->
#   input = "import { default as foo } from 'lib'"
#   output = "import { default as foo } from 'lib';"
#   eq toJS(input), output

# test "module import test, syntax #4", ->
#   input = "import { square, diag } from 'lib'"
#   output = "import { square, diag } from 'lib';"
#   eq toJS(input), output

# test "module import test, syntax #5", ->
#   input = "import { foo } from 'lib' # with a comment"
#   output = "import { foo } from 'lib' ;"
#   eq toJS(input), output

# test "module export test, syntax #1", ->
#   input = "export default mixin"
#   output = "export default mixin;"
#   eq toJS(input), output

# test "module export test, syntax #2", ->
#   input = "export { D as default }"
#   output = "export { D as default };"
#   eq toJS(input), output

# test "module export test, syntax #3", ->
#   input = "export sqrt = Math.sqrt"
#   output = "export sqrt = Math.sqrt;"
#   eq toJS(input), output
