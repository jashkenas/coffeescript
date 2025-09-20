# Test Advanced Operators

test "exponentiation operator", ->
  eq 2 ** 3, 8
  eq 5 ** 2, 25
  eq 10 ** 0, 1

test "floor division operator", ->
  eq 7 // 2, 3
  eq 10 // 3, 3
  eq -7 // 2, -4

test "modulo with negative numbers", ->
  eq 7 %% 3, 1
  eq -7 %% 3, 2
  eq 7 %% -3, -2

test "chained comparisons", ->
  x = 5
  ok 1 < x < 10
  ok not (10 < x < 20)

test "instanceof with multiple types", ->
  class A
  class B extends A

  b = new B()
  ok b instanceof B
  ok b instanceof A

test "in operator with arrays", ->
  arr = [1, 2, 3]
  ok 2 in arr
  ok 4 not in arr

test "in operator with objects", ->
  obj = {a: 1, b: 2}
  ok 'a' of obj
  ok 'c' not of obj

test "existence operator chaining", ->
  obj =
    a:
      b:
        c: 42

  eq obj?.a?.b?.c, 42
  eq obj?.x?.y?.z, undefined

test "logical assignment operators", ->
  x = null
  x ||= 42
  eq x, 42

  y = true
  y &&= false
  eq y, false

test "bitwise operators", ->
  eq 5 & 3, 1
  eq 5 | 3, 7
  eq 5 ^ 3, 6
  eq ~5, -6
  eq 5 << 1, 10
  eq 5 >> 1, 2

test "typeof operator", ->
  eq typeof 42, 'number'
  eq typeof 'hello', 'string'
  eq typeof true, 'boolean'
  eq typeof {}, 'object'
  eq typeof [], 'object'
  eq typeof (->), 'function'

test "delete operator", ->
  obj = {a: 1, b: 2}
  delete obj.a
  ok 'a' not of obj
  ok 'b' of obj

test "undefined value", ->
  x = undefined
  eq x, undefined

test "sequential evaluation", ->
  x = 3  # CoffeeScript doesn't have comma operator
  eq x, 3

test "is and isnt operators", ->
  ok 5 is 5
  ok 5 isnt 6
  ok null is null
  ok undefined is undefined

test "range operators", ->
  arr1 = [1..5]
  arrayEq arr1, [1, 2, 3, 4, 5]

  arr2 = [1...5]
  arrayEq arr2, [1, 2, 3, 4]

test "splat in array literals", ->
  a = [1, 2]
  b = [3, 4]
  c = [a..., b...]
  arrayEq c, [1, 2, 3, 4]

test "prototype operator", ->
  class MyClass
  MyClass::method = -> 42

  obj = new MyClass()
  eq obj.method(), 42

test "do operator with functions", ->
  result = do -> 42
  eq result, 42

  x = 5
  result2 = do (y = x) -> y * 2
  eq result2, 10

test "conditional existence", ->
  fn = (x) ->
    x ? 'default'

  eq fn(42), 42
  eq fn(null), 'default'
  eq fn(undefined), 'default'
