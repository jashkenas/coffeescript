
compiles = (code) -> doesNotThrow ->
  CoffeeScript.compile code, bare: yes

doesNotCompile = (code) -> throws ->
  CoffeeScript.compile code, bare: yes

test 'valid decimal literal separators compile', ->
  compiles '1_2.34_5e6_7'

test 'invalid decimal literal separators do not compile', ->
  doesNotCompile '1_.23'
  # The next one is a valid property access:
  # doesNotCompile '1._23'
  doesNotCompile '1e_2'
  doesNotCompile '1e2_'
  doesNotCompile '1_'
  doesNotCompile '1__2'

test 'valid hexadecimal literal separators compile', ->
  compiles '0x1_2_3_4'

test 'invalid hexadecimal literal separators do not compile', ->
  doesNotCompile '0x_1234'
  doesNotCompile '0x1234_'
  doesNotCompile '0x1__34'

test 'valid binary literal separators compile', ->
  compiles '0b10_10'

test 'invalid binary literal separators do not compile', ->
  doesNotCompile '0b_100'
  doesNotCompile '0b100_'
  doesNotCompile '0b1__1'

test 'valid octal literal separators compile', ->
  compiles '0o7_7_7'

test 'invalid octal literal separators do not compile', ->
  doesNotCompile '0o_777'
  doesNotCompile '0o777_'
  doesNotCompile '0o6__6'

test 'numeric literals equal numeric literals with separators', ->
  eq 123456, 123_456
  eq 10e10, 1_0e1_0
  eq 12.345, 1_2.34_5
  eq 0x1234, 0x12_34
  eq 0b1000, 0b10_00
  eq 0o777, 0o7_7_7
