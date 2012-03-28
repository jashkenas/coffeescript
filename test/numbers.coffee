# Number Literals
# ---------------

# * Decimal Integer Literals
# * Octal Integer Literals
# * Hexadecimal Integer Literals
# * Scientific Notation Integer Literals
# * Scientific Notation Non-Integer Literals
# * Non-Integer Literals
# * Binary Integer Literals


# Binary Integer Literals
# Binary notation is understood as would be decimal notation.

test "Parser recognises binary numbers", ->
  eq 4, 0b100

# Decimal Integer Literals

test "call methods directly on numbers", ->
  eq 4, 4.valueOf()
  eq '11', 4.toString 3

eq -1, 3 -4

#764: Numbers should be indexable
eq Number::toString, 42['toString']

eq Number::toString, 42.toString


# Non-Integer Literals

# Decimal number literals.
value = .25 + .75
ok value is 1
value = 0.0 + -.25 - -.75 + 0.0
ok value is 0.5

#764: Numbers should be indexable
eq Number::toString,   4['toString']
eq Number::toString, 4.2['toString']
eq Number::toString, .42['toString']
eq Number::toString, (4)['toString']

eq Number::toString,   4.toString
eq Number::toString, 4.2.toString
eq Number::toString, .42.toString
eq Number::toString, (4).toString

test '#1168: leading floating point suppresses newline', ->
  eq 1, do ->
    1
    .5 + 0.5

test "Python-style octal literal notation '0o777'", ->
  eq 511, 0o777
  eq 1, 0o1
  eq 1, 0o00001
  eq parseInt('0777', 8), 0o777
  eq '777', 0o777.toString 8
  eq 4, 0o4.valueOf()
  eq Number::toString, 0o777['toString']
  eq Number::toString, 0o777.toString

test "#2060: Disallow uppercase radix prefixes and exponential notation", ->
  for char in ['b', 'o', 'x', 'e']
    program = "0#{char}0"
    doesNotThrow -> CoffeeScript.compile program, bare: yes
    throws -> CoffeeScript.compile program.toUpperCase(), bare: yes

test "#2224: hex literals with 0b or B or E", ->
  eq 176, 0x0b0
  eq 177, 0x0B1
  eq 225, 0xE1
