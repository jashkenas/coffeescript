third = (a, b, c) -> c
obj =
  one: 'one'
  two: third 'one', 'two', 'three'
ok obj.one is 'one'
ok obj.two is 'three'


# Implicit arguments to function calls:
func = (obj) -> obj.a
func2 = -> arguments

result = func
  a: 10
ok result is 10

result = func
  "a": 20
ok result is 20

a = b = undefined

result = func
    b:1
    a
ok result is undefined

result = func
    a:
        b:2
    b:1
ok result.b is 2

result = func2
    a:1
    b
    c:1
ok result.length is 3
ok result[2].c is 1

second = (x, y) -> y
obj = then second 'the',
  1: 1
  two:
    three: ->
      four five,
        six: seven
  three: 3
ok obj[1] is 1
ok obj.three is 3
