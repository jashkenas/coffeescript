# Simple variable swapping.
a: -1
b: -2

[a, b]: [b, a]

ok a is -2
ok b is -1

func: ->
  [a, b]: [b, a]

ok func().join(' ') is '-1 -2'

noop: ->

noop [a,b]: [c,d]: [1,2]

ok a is 1 and b is 2


# Array destructuring, including splats.
arr: [1, 2, 3]

[a, b, c]: arr

ok a is 1
ok b is 2
ok c is 3

[x,y...,z]: [1,2,3,4,5]

ok x is 1
ok y.length is 3
ok z is 5

[x, [y, mids..., last], z..., end]: [1, [10, 20, 30, 40], 2,3,4, 5]

ok x is 1
ok y is 10
ok mids.length is 2 and mids[1] is 30
ok last is 40
ok z.length is 3 and z[2] is 4
ok end is 5


# Object destructuring.
obj: {x: 10, y: 20, z: 30}

{x: a, y: b, z: c}: obj

ok a is 10
ok b is 20
ok c is 30

person: {
  name: "Moe"
  family: {
    brother: {
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

{name: a, family: {brother: {addresses: [one, {city: b}]}}}: person

ok a is "Moe"
ok b is "Moquasset NY, 10021"

test: {
  person: {
    address: [
      "------"
      "Street 101"
      "Apt 101"
      "City 101"
    ]
  }
}

{person: {address: [ignore, addr...]}}: test

ok addr.join(', ') is "Street 101, Apt 101, City 101"


# Destructuring against an expression.
[a, b]: if true then [2, 1] else [1, 2]

ok a is 2
ok b is 1
