# Number Literals
# ---------------

# * Decimal Integer Literals
# * Octal Integer Literals
# * Hexadecimal Integer Literals
# * Scientific Notation Integer Literals
# * Scientific Notation Non-Integer Literals
# * Non-Integer Literals


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
eq Number::toString, 4.2['toString']
eq Number::toString, .42['toString']

eq Number::toString, 4.2.toString
eq Number::toString, .42.toString

test '#1168: leading floating point suppresses newline', ->
	eq 1, do ->
		1
		.5 + 0.5
