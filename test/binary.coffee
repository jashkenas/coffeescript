# Number Literals in Binary notation
# ---------------

# Binary notation is understood as would be decimal notation.

test "Parser recognises binary numbers", ->
  eq 4, 0b100.valueOf()
  eq '11', 0b100.toString 3
  eq '100', 0b100['toString'] 2
