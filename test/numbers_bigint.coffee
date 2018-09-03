# BigInt Literals
# ---------------

test "BigInt exists", ->
  'object' is typeof BigInt

test "Parser recognizes BigInt literals", ->
  eq 'bigint', typeof 42n
