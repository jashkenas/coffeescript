# Test operators

test "arithmetic operators", ->
  eq 2 + 3, 5
  eq 10 - 4, 6
  eq 3 * 4, 12
  eq 15 / 3, 5
  eq 10 % 3, 1
  eq 2 ** 3, 8

test "comparison operators", ->
  ok 5 > 3
  ok 3 < 5
  ok 5 >= 5
  ok 3 <= 3
  ok 5 is 5
  ok 5 isnt 3

test "logical operators", ->
  ok true and true
  ok true or false
  ok not false
  ok true && true
  ok true || false
  ok !false

test "string concatenation", ->
  eq "hello" + " " + "world", "hello world"

test "in operator", ->
  ok 2 in [1, 2, 3]
  ok "a" in ["a", "b", "c"]
  ok not (4 in [1, 2, 3])

test "of operator", ->
  obj = {a: 1, b: 2}
  ok "a" of obj
  ok not ("c" of obj)

test "instanceof", ->
  arr = [1, 2, 3]
  ok arr instanceof Array
  ok arr instanceof Object  # Arrays are Objects in JavaScript

test "typeof", ->
  eq typeof 42, "number"
  eq typeof "hello", "string"
  eq typeof true, "boolean"
  eq typeof {}, "object"
  eq typeof (->), "function"

test "chaining operators", ->
  ok 1 < 2 < 3
  ok 3 > 2 > 1

test "compound assignment", ->
  x = 10
  x += 5
  eq x, 15

  x -= 3
  eq x, 12

  x *= 2
  eq x, 24

  x /= 4
  eq x, 6

test "existence operator", ->
  a = null
  b = 42
  eq a ? 10, 10
  eq b ? 10, 42

test "soak operator", ->
  obj = {a: {b: 42}}
  eq obj?.a?.b, 42
  eq obj?.x?.y, undefined
