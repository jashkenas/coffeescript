# Test classes with a four-level inheritance chain.
class Base
  func: (string) ->
    "zero/#{string}"

  @static: (string) ->
    "static/#{string}"

class FirstChild extends Base
  func: (string) ->
    super('one/') + string

SecondChild = class extends FirstChild
  func: (string) ->
    super('two/') + string

thirdCtor = ->
  @array = [1, 2, 3]

class ThirdChild extends SecondChild
  constructor: -> thirdCtor.call this

  # Gratuitous comment for testing.
  func: (string) ->
    super('three/') + string

result = (new ThirdChild).func 'four'

ok result is 'zero/one/two/three/four'
ok Base.static('word') is 'static/word'

FirstChild::func = (string) ->
  super('one/').length + string

result = (new ThirdChild).func 'four'

ok result is '9two/three/four'

ok (new ThirdChild).array.join(' ') is '1 2 3'


identity = (f) -> f

class TopClass
  constructor: (arg) ->
    @prop = 'top-' + arg

class SuperClass extends TopClass
  constructor: (arg) ->
    identity super 'super-' + arg

class SubClass extends SuperClass
  constructor: ->
    identity super 'sub'

ok (new SubClass).prop is 'top-super-sub'


class OneClass
  @new: 'new'
  function: 'function'
  constructor: (name) -> @name = name

class TwoClass extends OneClass
delete TwoClass.new

Function.prototype.new = -> new this arguments...

ok (TwoClass.new('three')).name is 'three'
ok (new OneClass).function is 'function'
ok OneClass.new is 'new'

delete Function.prototype.new


# And now the same tests, but written in the manual style:
Base = ->
Base::func = (string) ->
  'zero/' + string
Base::['func-func'] = (string) ->
  "dynamic-#{string}"

FirstChild = ->
SecondChild = ->
ThirdChild = ->
  @array = [1, 2, 3]
  this

ThirdChild extends SecondChild extends FirstChild extends Base

FirstChild::func = (string) ->
  super('one/') + string

SecondChild::func = (string) ->
  super('two/') + string

ThirdChild::func = (string) ->
  super('three/') + string

result = (new ThirdChild).func 'four'

ok result is 'zero/one/two/three/four'

ok (new ThirdChild)['func-func']('thing') is 'dynamic-thing'


TopClass = (arg) ->
  @prop = 'top-' + arg
  this

SuperClass = (arg) ->
  super 'super-' + arg
  this

SubClass = ->
  super 'sub'
  this

SuperClass extends TopClass
SubClass extends SuperClass

ok (new SubClass).prop is 'top-super-sub'


# '@' referring to the current instance, and not being coerced into a call.
class ClassName
  amI: ->
    @ instanceof ClassName

obj = new ClassName
ok obj.amI()


# super() calls in constructors of classes that are defined as object properties.
class Hive
  constructor: (name) -> @name = name

class Hive.Bee extends Hive
  constructor: (name) -> super

maya = new Hive.Bee 'Maya'
ok maya.name is 'Maya'


# Class with JS-keyword properties.
class Class
  class: 'class'
  name: -> @class

instance = new Class
ok instance.class is 'class'
ok instance.name() is 'class'


# Classes with methods that are pre-bound to the instance.
# ... or statically, to the class.
class Dog

  constructor: (name) ->
    @name = name

  bark: =>
    "#{@name} woofs!"

  @static = =>
    new this('Dog')

spark = new Dog('Spark')
fido  = new Dog('Fido')
fido.bark = spark.bark

ok fido.bark() is 'Spark woofs!'

obj = func: Dog.static

ok obj.func().name is 'Dog'


# Testing a bound function in a bound function.
class Mini
  num: 10
  generate: =>
    for i in [1..3]
      =>
        @num

m = new Mini
eq (func() for func in m.generate()).join(' '), '10 10 10'


# Testing a contructor called with varargs.
class Connection
  constructor: (one, two, three) ->
    [@one, @two, @three] = [one, two, three]

  out: ->
    "#{@one}-#{@two}-#{@three}"

list = [3, 2, 1]
conn = new Connection list...
ok conn instanceof Connection
ok conn.out() is '3-2-1'


# Test calling super and passing along all arguments.
class Parent
  method: (args...) -> @args = args

class Child extends Parent
  method: -> super

c = new Child
c.method 1, 2, 3, 4
ok c.args.join(' ') is '1 2 3 4'


# Test classes wrapped in decorators.
func = (klass) ->
  klass::prop = 'value'
  klass

func class Test
  prop2: 'value2'

ok (new Test).prop  is 'value'
ok (new Test).prop2 is 'value2'


# Test anonymous classes.
obj =
  klass: class
    method: -> 'value'

instance = new obj.klass
ok instance.method() is 'value'


# Implicit objects as static properties.
class Static
  @static =
    one: 1
    two: 2

ok Static.static.one is 1
ok Static.static.two is 2


# Nothing classes.
c = class
ok c instanceof Function


# Classes with value'd constructors.
counter = 0
classMaker = ->
  counter += 1
  inner = counter
  ->
    @value = inner

class One
  constructor: classMaker()

class Two
  constructor: classMaker()

ok (new One).value is 1
ok (new Two).value is 2
ok (new One).value is 1
ok (new Two).value is 2


# Exectuable class bodies.
class A
  if true
    b: 'b'
  else
    c: 'c'

a = new A

eq a.b, 'b'
eq a.c, undefined


# Light metaprogramming.
class Base
  @attr: (name) ->
    @::[name] = (val) ->
      if arguments.length > 0
        @["_#{name}"] = val
      else
        @["_#{name}"]

class Robot extends Base
  @attr 'power'
  @attr 'speed'

robby = new Robot

ok robby.power() is undefined

robby.power 11
robby.speed Infinity

eq robby.power(), 11
eq robby.speed(), Infinity


# Namespaced classes do not reserve their function name in outside scope.
one = {}
two = {}

class one.Klass
  @label = "one"

class two.Klass
  @label = "two"

eq typeof Klass, 'undefined'
eq one.Klass.label, 'one'
eq two.Klass.label, 'two'


# Nested classes.
class Outer
  constructor: ->
    @label = 'outer'

  class @Inner
    constructor: ->
      @label = 'inner'

eq (new Outer).label, 'outer'
eq (new Outer.Inner).label, 'inner'


# Variables in constructor bodies are correctly scoped.
class A
  x = 1
  constructor: ->
    x = 10
    y = 20
  y = 2
  captured: ->
    {x, y}

a = new A
eq a.captured().x, 10
eq a.captured().y, 2


# Issue #924: Static methods in nested classes.
class A
  @B: class
    @c = -> 5

eq A.B.c(), 5


# `class extends this` ...
class A
  func: -> 'A'

B = null
makeClass = ->
  B = class extends this
    func: -> super + ' B'

makeClass.call A

eq (new B()).func(), 'A B'
