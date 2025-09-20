# Test Advanced Objects

test "object with methods", ->
  obj =
    value: 42
    getValue: -> @value
    setValue: (@value) ->

  eq obj.getValue(), 42
  obj.setValue(100)
  eq obj.getValue(), 100

test "object with computed properties", ->
  key = 'dynamic'
  obj =
    "#{key}Key": 'value'
    ["computed_#{key}"]: 42

  eq obj.dynamicKey, 'value'
  eq obj.computed_dynamic, 42

test "nested objects", ->
  obj =
    level1:
      level2:
        level3:
          value: 42

  eq obj.level1.level2.level3.value, 42

test "object spread", ->
  obj1 = {a: 1, b: 2}
  obj2 = {b: 3, c: 4}
  combined = {obj1..., obj2...}

  eq combined.a, 1
  eq combined.b, 3
  eq combined.c, 4

test "object rest", ->
  obj = {a: 1, b: 2, c: 3, d: 4}
  {a, b, rest...} = obj

  eq a, 1
  eq b, 2
  eq rest.c, 3
  eq rest.d, 4

test "YAML-style objects", ->
  person =
    name: 'John'
    age: 30
    address:
      street: '123 Main'
      city: 'Boston'
    hobbies: [
      'reading'
      'coding'
    ]

  eq person.name, 'John'
  eq person.address.city, 'Boston'
  ok person.hobbies[0] == 'reading'
  ok person.hobbies[1] == 'coding'

test "object with getters pattern", ->
  obj =
    _value: 42
    get: -> @_value
    set: (val) -> @_value = val

  eq obj.get(), 42
  obj.set(100)
  eq obj.get(), 100

test "object prototype manipulation", ->
  obj = {}
  Object.setPrototypeOf obj,
    inherited: -> 'inherited'

  eq obj.inherited(), 'inherited'

test "object with symbols as keys", ->
  obj =
    '@special': 'at'
    '#private': 'hash'
    '$jquery': 'dollar'

  eq obj['@special'], 'at'
  eq obj['#private'], 'hash'
  eq obj['$jquery'], 'dollar'

test "object property descriptors", ->
  obj = {}
  Object.defineProperty obj, 'prop',
    value: 42
    writable: false

  eq obj.prop, 42
  obj.prop = 100
  eq obj.prop, 42  # didn't change

test "object with mixed property types", ->
  obj =
    string: 'text'
    number: 42
    boolean: true
    array: [1, 2, 3]
    nested: {a: 1}
    fn: -> 'function'
    regex: /pattern/

  eq obj.string, 'text'
  eq obj.number, 42
  eq obj.boolean, true
  ok obj.array[0] == 1
  ok obj.array[2] == 3
  eq obj.fn(), 'function'

test "object merging patterns", ->
  defaults = {a: 1, b: 2, c: 3}
  options = {b: 20, d: 40}
  merged = {defaults..., options...}

  eq merged.a, 1
  eq merged.b, 20
  eq merged.c, 3
  eq merged.d, 40

test "object with implicit returns", ->
  obj =
    method1: -> 42
    method2: ->
      x = 10
      x * 2
    method3: ->
      if true
        'yes'
      else
        'no'

  eq obj.method1(), 42
  eq obj.method2(), 20
  eq obj.method3(), 'yes'

test "object property existence", ->
  obj = {a: null, b: undefined, c: 0, d: false, e: 'value'}

  ok 'a' of obj
  ok 'b' of obj
  ok 'c' of obj
  ok 'd' of obj
  ok 'e' of obj
  ok 'f' not of obj

test "object with dynamic method calls", ->
  obj =
    method1: -> 1
    method2: -> 2
    method3: -> 3

  methodName = 'method2'
  eq obj[methodName](), 2

test "object cloning", ->
  original = {a: 1, b: {c: 2}}
  shallow = {original...}

  shallow.a = 10
  shallow.b.c = 20

  eq original.a, 1
  eq original.b.c, 20  # shallow copy

test "object with async methods", ->
  obj =
    asyncMethod: ->
      await Promise.resolve(42)

  ok obj.asyncMethod() instanceof Promise

test "object entries and values", ->
  obj = {a: 1, b: 2, c: 3}

  entries = []
  for k, v of obj
    entries.push [k, v]
  ok entries.length == 3

  values = []
  for k, v of obj
    values.push v
  ok values[0] == 1 or values[1] == 1 or values[2] == 1
  ok values[0] == 2 or values[1] == 2 or values[2] == 2
  ok values[0] == 3 or values[1] == 3 or values[2] == 3

test "object with circular reference", ->
  obj = {value: 42}
  obj.self = obj

  eq obj.self.self.value, 42
