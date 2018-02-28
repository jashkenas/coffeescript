# Sub-Structure Assignment
# ----------

test "lhs sub-structure assignment", ->
  data =
    title: "Mr"
    name: "Coffee"
    address: "Sesame Street"
    zip: 10001
    city: "London"

  view = {}
  view{title, name} = data

  deepEqual view, {title: "Mr", name: "Coffee"}

  user = name: "CS"
  user{title, name:full_name} = data

  deepEqual user, {name: "CS", title: "Mr", full_name: "Coffee"}

test "lhs sub-structure assignment: exclude property", ->
  data =
    title: "Mr"
    name: "Coffee"
    address: "Sesame Street"
    zip: 10001
    city: "London"

  view = {address: "Elm Street"}
  view{title, name:full_name, -address, rest...} = data

  deepEqual view,
      address: "Elm Street"
      title: "Mr"
      full_name: "Coffee"
      rest:
        zip: 10001,
        city: "London"

test "lhs sub-structure assignment: nested properties", ->
  data =
    addr:
      street: ["Elm", 12]
      city: "London"
      state: "England"
      zip: "GH 201 X"
      floor: 30
      appartment: "XJ-1"
    phone:
      home: "999-555-111"
      work: "888-333-555"

  user = name: "CS"
  user{
    addr: {
      street: [street1, street2],
      city, state, -zip, -floor, ext...
    },
    phone: { home:phone_home }
  } = data

  deepEqual user,
      name: "CS"
      street1: "Elm"
      street2: 12
      city: "London"
      state: "England"
      ext:
        appartment: "XJ-1"
      phone_home: "999-555-111"

test "rhs sub-structure assignment", ->
  data =
    title: "Mr"
    name: "Coffee"
    address: "Sesame Street"
    zip: 10001
    city: "London"

  view = title: "X"
  view = data{title, name}

  deepEqual view, {title: "Mr", name: "Coffee"}

  view = data{title:t, name:full_name}

  deepEqual view, {t: "Mr", full_name: "Coffee"}

test "rhs sub-structure assignment: exclude property", ->
  data =
    title: "Mr"
    name: "Coffee"
    address: "Sesame Street"
    zip: 10001
    city: "London"

  view = {address: "Elm Street"}
  view = data{title, name:full_name, -address, rest...}

  deepEqual view,
      title: "Mr"
      full_name: "Coffee"
      rest:
        zip: 10001,
        city: "London"

test "rhs sub-structure assignment: nested properties", ->
  data =
    addr:
      street: ["Elm", 12]
      city: "London"
      state: "England"
      zip: "GH 201 X"
      floor: 30
      appartment: "XJ-1"
    phone:
      home: "999-555-111"
      work: "888-333-555"

  user = addr:
    street: ["Sesame Street", 99]
  user =
    data{
      addr: {
        street: [street1, street2],
        city, state, -zip, -floor, ext...
      },
      phone: { home:phone_home }
    }

  deepEqual user,
      street1: "Elm"
      street2: 12
      city: "London"
      state: "England"
      ext:
        appartment: "XJ-1"
      phone_home: "999-555-111"
