# Ensure that carriage returns don't break compilation on Windows.
eq CoffeeScript.compile('one\r\ntwo', wrap: off), 'one;\ntwo;'

# `globals: on` removes `var`s
eq CoffeeScript.compile('x = y', wrap: off, globals: on), 'x = y;'

ok 'passed' is CoffeeScript.eval '"passed"', wrap: off, fileName: 'test'

#750
try ok not CoffeeScript.nodes 'f(->'
catch e then eq e.message, 'unclosed CALL_START on line 1'
