# Compilation
# -----------

# TODO: refactor compilation tests

# helper to assert that a string should fail compilation
cantCompile = (code) ->
  throws -> CoffeeScript.compile code


# Ensure that carriage returns don't break compilation on Windows.
doesNotThrow -> CoffeeScript.compile 'one\r\ntwo', bare: on

# `globals: on` removes `var`s
eq -1, CoffeeScript.compile('x = y', bare: on, globals: on).indexOf 'var'

ok 'passed' is CoffeeScript.eval '"passed"', bare: on, fileName: 'test'

# multiple generated references
(->
  a = {b: []}
  a.b[true] = -> this == a.b
  c = 0
  d = []
  ok a.b[0<++c<2] d...
)()

# Splat on a line by itself is invalid.
cantCompile "x 'a'\n...\n"

#750
cantCompile 'f(->'

cantCompile 'a = (break)'

cantCompile 'a = (return 5 for item in list)'

cantCompile 'a = (return 5 while condition)'

cantCompile 'a = for x in y\n  return 5'

# Issue #986: Unicode identifiers.
λ = 5
eq λ, 5

test "don't accidentally stringify keywords", ->
  ok (-> this == 'this')() is false
