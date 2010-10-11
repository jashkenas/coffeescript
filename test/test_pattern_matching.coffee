# Simple variable swapping.
a = -1
b = -2

[a, b] = [b, a]

eq a, -2
eq b, -1

func = ->
  [a, b] = [b, a]

eq func().join(' '), '-1 -2'
eq a, -1
eq b, -2

#713
eq (onetwo = [1, 2]), [a, b] = [c, d] = onetwo
ok a is c is 1 and b is d is 2


# Array destructuring, including splats.
[x,y...,z] = [1,2,3,4,5]

ok x is 1
ok y.length is 3
ok z is 5

[x, [y, mids..., last], z..., end] = [1, [10, 20, 30, 40], 2,3,4, 5]

ok x is 1
ok y is 10
ok mids.length is 2 and mids[1] is 30
ok last is 40
ok z.length is 3 and z[2] is 4
ok end is 5


# Object destructuring.
obj = {x: 10, y: 20, z: 30}

{x: a, y: b, z: c} = obj

ok a is 10
ok b is 20
ok c is 30

person = {
  name: "Moe"
  family: {
    'elder-brother': {
      addresses: [
        "first"
        {
          street: "101 Deercreek Ln."
          city:   "Moquasset NY, 10021"
        }
      ]
    }
  }
}

{name: a, family: {'elder-brother': {addresses: [one, {city: b}]}}} = person

ok a is "Moe"
ok b is "Moquasset NY, 10021"

test = {
  person: {
    address: [
      "------"
      "Street 101"
      "Apt 101"
      "City 101"
    ]
  }
}

{person: {address: [ignore, addr...]}} = test

ok addr.join(', ') is "Street 101, Apt 101, City 101"


# Pattern matching against an expression.
[a, b] = if true then [2, 1] else [1, 2]

ok a is 2
ok b is 1


# Pattern matching with object shorthand.

person = {
  name: "Bob"
  age:  26
  dogs: ["Prince", "Bowie"]
}

{name, age, dogs: [first, second]} = person

ok name   is "Bob"
ok age    is 26
ok first  is "Prince"
ok second is "Bowie"

# Pattern matching within for..loops

persons = {
  George: { name: "Bob" },
  Bob: { name: "Alice" }
  Christopher: { name: "Stan" }
}

join1 = "#{key}: #{name}" for key, { name } of persons

eq join1.join(' / '), "George: Bob / Bob: Alice / Christopher: Stan"

persons = [
  { name: "Bob", parent: { name: "George" } },
  { name: "Alice", parent: { name: "Bob" } },
  { name: "Stan", parent: { name: "Christopher" } }
]

join2 = "#{parent}: #{name}" for { name, parent: { name: parent } } in persons

eq join1.join(' '), join2.join(' ')

persons = [['Bob', ['George']], ['Alice', ['Bob']], ['Stan', ['Christopher']]]
join3 = "#{parent}: #{name}" for [name, [parent]] in persons

eq join2.join(' '), join3.join(' ')


# Pattern matching doesn't clash with implicit block objects.
obj = a: 101
func = -> true

if func func
  {a} = obj

ok a is 101

[x] = {0: y} = {'0': z} = [Math.random()]
ok x is y is z, 'destructuring in multiple'


# Destructuring into an object.
obj =
  func: (list, object) ->
    [@one, @two] = list
    {@a, @b} = object
    {@a} = object  # must not unroll this
    null

obj.func [1, 2], a: 'a', b: 'b'

eq obj.one, 1
eq obj.two, 2
eq obj.a, 'a'
eq obj.b, 'b'
