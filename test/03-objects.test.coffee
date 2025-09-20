# Test object operations

test "object creation", ->
  obj = {a: 1, b: 2}
  eq obj.a, 1
  eq obj.b, 2

test "object with string keys", ->
  obj = {"hello": "world", 'foo': 'bar'}
  eq obj.hello, "world"
  eq obj.foo, "bar"

test "computed property names", ->
  key = "dynamic"
  obj = {"#{key}": 42}
  eq obj.dynamic, 42

test "object shorthand", ->
  x = 10
  y = 20
  obj = {x, y}
  eq obj.x, 10
  eq obj.y, 20

test "nested objects", ->
  obj = {a: {b: {c: 42}}}
  eq obj.a.b.c, 42

test "object destructuring", ->
  {a, b} = {a: 1, b: 2, c: 3}
  eq a, 1
  eq b, 2

test "nested destructuring", ->
  {a: {b}} = {a: {b: 42}}
  eq b, 42

test "destructuring with defaults", ->
  {x = 10, y = 20} = {x: 5}
  eq x, 5
  eq y, 20

test "object spread", ->
  a = {x: 1, y: 2}
  b = {a..., z: 3}
  eq b.x, 1
  eq b.y, 2
  eq b.z, 3

test "property access", ->
  obj = {foo: {bar: 42}}
  eq obj.foo.bar, 42
  eq obj["foo"]["bar"], 42
