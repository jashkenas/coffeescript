a: -1
b: -2

[a, b]: [b, a]

print a is -2
print b is -1


arr: [1, 2, 3]

[a, b, c]: arr

print a is 1
print b is 2
print c is 3


obj: {x: 10, y: 20, z: 30}

{x: a, y: b, z: c}: obj

print a is 10
print b is 20
print c is 30


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

print a is "Bob"
print b is "Moquasset NY, 10021"


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

print addr.join(', ') is "Street 101, Apt 101, City 101"