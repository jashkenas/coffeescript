
test 'numeric literal separators', ->
  compiles = (code) -> doesNotThrow ->
    CoffeeScript.compile code, bare: yes
  doesNotCompile = (code) -> throws ->
    CoffeeScript.compile code, bare: yes

  compiles '1_2.34_5e6_7'
  doesNotCompile '1_.23'
  doesNotCompile '1._23'
  doesNotCompile '1e_2'
  doesNotCompile '1e2_'
  doesNotCompile '1_'
  doesNotCompile '1__2'
  compiles '0x1_2_3_4'
  doesNotCompile '0x_1234'
  doesNotCompile '0x1234_'
  doesNotCompile '0x1__34'
  compiles '0b10_10'
  doesNotCompile '0b_100'
  doesNotCompile '0b100_'
  doesNotCompile '0b1__1'
  compiles '0o7_7_7'
  doesNotCompile '0o_777'
  doesNotCompile '0o777_'
  doesNotCompile '0o6__6'

  eq 123456, 123_456
  eq 10**11, 1_0e1_0
  eq 12.345, 1_2.34_5
  eq 0x1234, 0x12_34
  eq 0b1000, 0b10_00
  eq 0o777, 0o7_7_7
