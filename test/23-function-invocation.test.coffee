# Test Function Invocation

test "basic function calls", ->
  fn = (x) -> x * 2
  eq fn(5), 10
  eq (fn 5), 10  # without parens - needs parens for correct parsing

test "implicit calls", ->
  fn = (x) -> x + 1
  result = fn 5
  eq result, 6

test "chained calls", ->
  obj =
    fn1: -> obj
    fn2: -> obj
    value: 42
  result = obj.fn1().fn2().value
  eq result, 42

test "nested calls", ->
  add = (a, b) -> a + b
  mul = (a, b) -> a * b
  result = add mul(2, 3), 4
  eq result, 10

test "calls with splats", ->
  fn = (a, b, c) -> a + b + c
  args = [1, 2, 3]
  eq fn(args[0], args[1], args[2]), 6

test "calls with trailing commas", ->
  fn = (a, b) -> a + b
  result = fn(
    1,
    2,
  )
  eq result, 3

test "calls with complex arguments", ->
  fn = (obj) -> obj.a + obj.b
  result = fn
    a: 1
    b: 2
  eq result, 3

test "method calls on literals", ->
  eq 'hello'.toUpperCase(), 'HELLO'
  eq (42).toString(), '42'

test "calls with default parameters", ->
  fn = (a = 1, b = 2) -> a + b
  eq fn(), 3
  eq fn(5), 7
  eq fn(5, 3), 8

test "IIFE (immediately invoked function expressions)", ->
  result = do ->
    x = 10
    x * 2
  eq result, 20

test "do with arguments", ->
  result = do (x = 5) ->
    x * 3
  eq result, 15

test "function calls in conditions", ->
  isTrue = -> true
  result = if isTrue() then 'yes' else 'no'
  eq result, 'yes'

test "function calls as object values", ->
  fn = -> 42
  obj =
    value: fn()
  eq obj.value, 42

test "super calls", ->
  class Base
    method: (x) -> x * 2

  class Derived extends Base
    method: (x) -> super(x) + 1

  d = new Derived()
  eq d.method(5), 11

test "constructor calls with new", ->
  class Thing
    constructor: (@value) ->

  t = new Thing(42)
  eq t.value, 42

test "calls with existence operator", ->
  obj =
    fn: -> 42
  eq obj.fn?(), 42
  eq obj.missing?(), undefined

test "call with spread in object", ->
  fn = (opts) -> opts.a + opts.b + opts.c
  defaults = {a: 1, b: 2}
  result = fn {a: defaults.a, b: defaults.b, c: 3}
  eq result, 6

test "multiline implicit calls", ->
  fn = (a, b, c) -> a + b + c
  result = fn 1,
    2,
    3
  eq result, 6

test "calls with interpolated strings", ->
  fn = (str) -> str.length
  x = 'world'
  result = fn "hello #{x}"
  eq result, 11

test "apply and call", ->
  fn = (a, b) -> a + b
  eq fn.call(null, 2, 3), 5
  eq fn.apply(null, [2, 3]), 5
