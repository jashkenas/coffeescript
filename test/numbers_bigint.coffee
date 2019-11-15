# BigInt Literals
# ---------------

test "BigInt exists", ->
  'object' is typeof BigInt

test "Parser recognizes decimal BigInt literals", ->
  eq 42n, BigInt 42

test "Parser recognizes binary BigInt literals", ->
  eq 42n, 0b101010n

test "Parser recognizes octal BigInt literals", ->
  eq 42n, 0o52n

test "Parser recognizes hexadecimal BigInt literals", ->
  eq 42n, 0x2an
