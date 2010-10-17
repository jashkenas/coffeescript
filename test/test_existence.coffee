ok(if mySpecialVariable? then false else true)

mySpecialVariable = false

ok(if mySpecialVariable? then true else false)


# Existential assignment.
a = 5
a = null
a ?= 10
b ?= 10

ok a is 10 and b is 10


# The existential operator.
z = null
x = z ? "EX"
ok z is null and x is "EX"

i = 9
func = -> i += 1
result = func() ? 101
ok result is 10

# Only evaluate once.
counter = 0
getNextNode = ->
  throw "up" if counter
  counter++

ok(if getNextNode()? then true else false)


# Existence chains, soaking up undefined properties:
obj =
  prop: "hello"

eq obj?.prop, "hello"
eq obj?['prop'], "hello"
eq obj.prop?.length, 5
eq obj?.prop?['length'], 5
eq obj?.prop?.non?.existent?.property, undefined


# Soaks and caches method calls as well.
arr = ["--", "----"]

eq arr.pop()?.length, 4
eq arr.pop()?.length, 2
eq arr.pop()?.length, undefined
eq arr.pop()?.length?.non?.existent()?.property, undefined


# Soaks method calls safely.
value = null
eq value?.toString().toLowerCase(), undefined

value = 10
eq value?.toString().toLowerCase(), '10'

eq 0.nothing?.property() or 101, 101

counter = 0
func = ->
  counter += 1
  'prop'
obj =
  prop: -> this
  value: 25

ok obj[func()]()[func()]()[func()]()?.value is 25
ok counter is 3


ident = (obj) -> obj
eq ident(non?.existent().method()), undefined, 'soaks inner values'


# Soaks constructor invocations.
a = 0
class Foo
  constructor: -> a += 1
  bar: "bat"

ok (new Foo())?.bar is 'bat'
ok a is 1


ok not value?.property?, 'safely checks existence on soaks'


eq nothing?.value, undefined, 'safely calls values off of non-existent variables'
eq !nothing?.value and 1, 1,  'corresponding operators work as expected'


# Assign to the result of an exsitential operation with a minus.
x = null ? - 1
ok x is - 1


# Things that compile to ternaries should force parentheses, like operators do.
duration = if options?.animated then 150 else 0
ok duration is 0


# Function soaks.
plus1 = (x) -> x + 1
count = 0
obj = {
  counter: -> count += 1; this
  returnThis: -> this
}

eq plus1?(41), 42
eq (plus1? 41), 42
eq plus2?(41), undefined
eq (plus2? 41), undefined
eq obj.returnThis?(), obj
eq obj.returnSelf?(), undefined
eq obj.returnThis?().flag = on, on
eq obj.returnSelf?().flag = on, undefined
eq obj.counter().counter().returnThis?(), obj
eq count, 2

maybe_close = (f, arg) -> if typeof f is 'function' then () -> f(arg) else -1

eq maybe_close(plus1, 41)?(), 42
eq (maybe_close plus1, 41)?(), 42
eq (maybe_close 'string', 41)?(), undefined

eq 2?(3), undefined
eq new Number?(42) | 0, 42
eq new Bumper?(42) | 0, 0

#726
eq calendar?[Date()], undefined

#733
a = b: {c: null}
eq a.b?.c?(), undefined
a.b?.c or= (it) -> it
eq a.b?.c?(1), 1
eq a.b?.c?([2, 3]...), 2
