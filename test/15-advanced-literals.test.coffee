# Test advanced literal types

test "numeric separators", ->
  million = 1_000_000
  eq million, 1000000

  binary = 0b1010_1010
  eq binary, 170

  hex = 0xFF_FF
  eq hex, 65535

test "bigint literals", ->
  # BigInt literals with n suffix
  big = 123n
  ok typeof big is 'bigint'
  eq big.toString(), "123"

  huge = 9007199254740993n  # Larger than MAX_SAFE_INTEGER
  ok typeof huge is 'bigint'

# JavaScript backticks not yet supported in CS3
# test "javascript backtick literals", ->
#   result = `1 + 1`
#   eq result, 2

# test "javascript backtick with interpolation", ->
#   x = 5
#   result = `${x} * 2`
#   eq result, "5 * 2"

test "mixed numeric bases", ->
  decimal = 255
  hex = 0xff
  octal = 0o377
  binary = 0b11111111

  eq decimal, hex
  eq decimal, octal
  eq decimal, binary

test "scientific notation", ->
  small = 1e-6
  eq small, 0.000001

  large = 3.14e10
  eq large, 31400000000

test "special number values", ->
  eq Infinity, Infinity
  ok isNaN(NaN)
  eq -Infinity, -Infinity

test "numeric separator edge cases", ->
  float = 3.141_592_653
  eq float.toFixed(6), "3.141593"

  exp = 1.23e4_5  # Separators in exponent
  eq exp, 1.23e45
