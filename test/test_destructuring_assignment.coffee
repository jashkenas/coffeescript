a: -1
b: -2

[a, b]: [b, a]

ok a is -2
ok b is -1


arr: [1, 2, 3]

[a, b, c]: arr

ok a is 1
ok b is 2
ok c is 3


obj: {x: 10, y: 20, z: 30}

{x: a, y: b, z: c}: obj

ok a is 10
ok b is 20
ok c is 30


person: {
  name: "Bob"
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

ok a is "Bob"
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