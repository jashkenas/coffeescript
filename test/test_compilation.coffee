{ exec } = require 'child_process'

# Ensure that carriage returns don't break compilation on Windows.
eq CoffeeScript.compile('one\r\ntwo', bare: on), 'one;\ntwo;'

# `globals: on` removes `var`s
eq CoffeeScript.compile('x = y', bare: on, globals: on), 'x = y;'

ok 'passed' is CoffeeScript.eval '"passed"', bare: on, fileName: 'test'

#750
try ok not CoffeeScript.nodes 'f(->'
catch e then eq e.message, 'unclosed CALL_START on line 1'

eq CoffeeScript.compile('for all k of o then', bare: on, globals: on),
   'for (k in o) {}'

#875: %d and %s in strings causes node.js to apply formatting
cmd = process.argv[1].replace /cake$/, 'coffee'
exec "#{cmd} -bpe  \"'%d isnt %s'\"", (error, stdout, stderr) ->
  throw error if error
  eq stdout.trim(), "'%d isnt %s';"
