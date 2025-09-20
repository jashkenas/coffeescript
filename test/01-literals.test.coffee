# Test literal values

test "number literals", ->
  eq 42, 42
  eq 3.14, 3.14
  eq 0xFF, 255
  eq 0b1010, 10
  eq 0o777, 511

test "string literals", ->
  eq "hello", "hello"
  eq 'world', 'world'
  eq """multi
  line""", "multi\nline"

test "boolean literals", ->
  eq true, true
  eq false, false
  eq yes, true
  eq no, false
  eq on, true
  eq off, false

test "null and undefined", ->
  eq null, null
  eq undefined, undefined

test "regex literals", ->
  regex = /test/gi
  ok regex instanceof RegExp
  eq regex.source, "test"
  eq regex.flags, "gi"
