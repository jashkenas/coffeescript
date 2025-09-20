# Test Advanced Classes

test "class with static methods", ->
  class MyClass
    @staticMethod: -> 'static'
    instanceMethod: -> 'instance'

  eq MyClass.staticMethod(), 'static'
  obj = new MyClass()
  eq obj.instanceMethod(), 'instance'

test "class with static properties", ->
  class MyClass
    @staticProp: 42

  eq MyClass.staticProp, 42

test "class with getters and setters", ->
  class Person
    constructor: (@firstName, @lastName) ->

    fullName: ->
      "#{@firstName} #{@lastName}"

  p = new Person('John', 'Doe')
  eq p.fullName(), 'John Doe'

test "class with private methods (convention)", ->
  class MyClass
    constructor: ->
      @value = @_privateMethod()

    _privateMethod: ->
      42

    publicMethod: ->
      @_privateMethod() + 1

  obj = new MyClass()
  eq obj.value, 42
  eq obj.publicMethod(), 43

test "class inheritance chain", ->
  class A
    method: -> 'A'

  class B extends A
    method: -> super() + 'B'

  class C extends B
    method: -> super() + 'C'

  c = new C()
  eq c.method(), 'ABC'

test "class with constructor parameters", ->
  class Point
    constructor: (@x, @y) ->

  p = new Point(3, 4)
  eq p.x, 3
  eq p.y, 4

test "class with default constructor parameters", ->
  class Point
    constructor: (@x = 0, @y = 0) ->

  p1 = new Point()
  eq p1.x, 0
  eq p1.y, 0

  p2 = new Point(5)
  eq p2.x, 5
  eq p2.y, 0

test "class with computed property names", ->
  key = 'dynamicMethod'
  class MyClass
    "#{key}": -> 42

  obj = new MyClass()
  eq obj.dynamicMethod(), 42

test "class with mixins", ->
  mixin =
    mixedMethod: -> 'mixed'

  class MyClass
    for key, value of mixin
      @::[key] = value

  obj = new MyClass()
  eq obj.mixedMethod(), 'mixed'

test "class with bound methods using fat arrow", ->
  class Counter
    constructor: ->
      @count = 0

    increment: =>
      @count++

  c = new Counter()
  fn = c.increment
  fn()
  fn()
  eq c.count, 2

test "class with super in constructor", ->
  class Base
    constructor: (@base) ->

  class Derived extends Base
    constructor: (base, @derived) ->
      super(base)

  d = new Derived('b', 'd')
  eq d.base, 'b'
  eq d.derived, 'd'

test "class with super in methods", ->
  class Base
    method: (x) -> x * 2

  class Derived extends Base
    method: (x) ->
      super(x) + 1

  d = new Derived()
  eq d.method(5), 11

test "anonymous class", ->
  MyClass = class
    method: -> 42

  obj = new MyClass()
  eq obj.method(), 42

test "class expression", ->
  createClass = ->
    class
      method: -> 42

  MyClass = createClass()
  obj = new MyClass()
  eq obj.method(), 42

test "class with symbols", ->
  class MyClass
    '#private': 'secret'
    method: -> @['#private']

  obj = new MyClass()
  eq obj.method(), 'secret'

test "class extending native types", ->
  class MyArray extends Array
    first: -> @[0]

  arr = new MyArray()
  arr.push(1, 2, 3)
  eq arr.first(), 1

test "class with async methods", ->
  class AsyncClass
    asyncMethod: ->
      await Promise.resolve(42)

  obj = new AsyncClass()
  ok obj.asyncMethod() instanceof Promise

test "class with generator methods", ->
  class GenClass
    generator: ->
      yield 1
      yield 2

  obj = new GenClass()
  gen = obj.generator()
  eq gen.next().value, 1

test "instanceof checks", ->
  class Base
  class Derived extends Base

  d = new Derived()
  ok d instanceof Derived
  ok d instanceof Base

test "class with decorators pattern", ->
  withLogging = (target) ->
    target.logged = true
    target

  MyClass = withLogging class
    method: -> 42

  eq MyClass.logged, true
