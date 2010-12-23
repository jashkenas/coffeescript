# Ensure that carriage returns don't break compilation on Windows.
eq CoffeeScript.compile('one\r\ntwo', bare: on), 'one;\ntwo;'

# `globals: on` removes `var`s
eq CoffeeScript.compile('x = y', bare: on, globals: on), 'x = y;'

ok 'passed' is CoffeeScript.eval '"passed"', bare: on, fileName: 'test'

#750
try ok not CoffeeScript.nodes 'f(->'
catch e then eq e.message, 'unclosed CALL_START on line 1'

eq CoffeeScript.compile('for k of o then', bare: on, globals: on),
   'for (k in o) {}'

# Compilations that should fail.
cantCompile = (code) ->
  throws -> CoffeeScript.compile code

cantCompile 'a = (break)'

cantCompile 'a = (return 5 for item in list)'

cantCompile 'a = (return 5 while condition)'

cantCompile 'a = for x in y\n  return 5'