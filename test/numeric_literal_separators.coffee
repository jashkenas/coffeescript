# Numeric Literal Separators
# --------------------------

test 'integer literals with separators', ->
  eq 123_456, 123456
  eq 12_34_56, 123456

test 'decimal literals with separators', ->
  eq 1_2.34_5, 12.345
  eq 1_0e1_0, 10e10
  eq 1_2.34_5e6_7, 12.345e67

test 'hexadecimal literals with separators', ->
  eq 0x1_2_3_4, 0x1234

test 'binary literals with separators', ->
  eq 0b10_10, 0b1010

test 'octal literals with separators', ->
  eq 0o7_7_7, 0o777

test 'infinity with separator', ->
  eq 2e3_08, Infinity

test 'range with separators', ->
  range = [10_000...10_002]
  eq range.length, 2
  eq range[0], 10000

test 'property access on a number', ->
  # Somehow, `3..toFixed()` is valid JavaScript; though just `3.toFixed()`
  # is not. CoffeeScript has long allowed code like `3.toFixed()` to compile
  # into `3..toFixed()`.
  eq 3.toFixed(), '3'
  # Where this can conflict with numeric literal separators is when the
  # property name contains an underscore.
  Number::_23 = _23 = 'x'
  eq 1._23, 'x'
  ok 1._34 is undefined
  delete Number::_23

test 'invalid decimal literal separators do not compile', ->
  # `1._23` is a valid property access (see previous test)
  throwsCompileError '1_.23'
  throwsCompileError '1e_2'
  throwsCompileError '1e2_'
  throwsCompileError '1_'
  throwsCompileError '1__2'

test 'invalid hexadecimal literal separators do not compile', ->
  throwsCompileError '0x_1234'
  throwsCompileError '0x1234_'
  throwsCompileError '0x1__34'

test 'invalid binary literal separators do not compile', ->
  throwsCompileError '0b_100'
  throwsCompileError '0b100_'
  throwsCompileError '0b1__1'

test 'invalid octal literal separators do not compile', ->
  throwsCompileError '0o_777'
  throwsCompileError '0o777_'
  throwsCompileError '0o6__6'
